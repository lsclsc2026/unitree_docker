"""Exercise command construction/guards without contacting Docker or hardware."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class LauncherTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.workspace = self.base / 'workspace with spaces'
        self.workspace.mkdir()
        self.calls = self.base / 'calls.jsonl'
        mock = self.base / 'docker'
        mock.write_text('''#!/usr/bin/env python3
import json, os, sys
with open(os.environ['DOCKER_CALLS'], 'a') as f:
    f.write(json.dumps(sys.argv[1:]) + '\\n')
if sys.argv[1:3] == ['container', 'inspect']:
    sys.exit(int(os.environ.get('MOCK_EXISTS', '1')))
if sys.argv[1] == 'inspect':
    print(os.environ.get('MOCK_LABEL', 'managed-v1'))
''')
        mock.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.base) + ':' + os.environ['PATH'],
                        DOCKER_CALLS=str(self.calls), UNITREE_PROJECT_ROOT=str(self.workspace),
                        UNITREE_DATA_ROOT=str(self.base / 'data'), UNITREE_CONTAINER='review-test',
                        UNITREE_IMAGE='review-test:latest')
        self.env.pop('UNITREE_NETWORK_INTERFACE', None)
        self.env.pop('CYCLONEDDS_URI', None)

    def run_launcher(self, *args):
        return subprocess.run([str(ROOT / 'unitree'), *args], env=self.env,
                              capture_output=True, text=True)

    def commands(self):
        return [json.loads(x) for x in self.calls.read_text().splitlines()]

    def test_default_help_has_no_side_effects(self):
        self.assertEqual(self.run_launcher().returncode, 0)
        self.assertFalse(self.calls.exists())
        self.assertFalse((self.base / 'data').exists())

    def test_all_previews_avoid_docker(self):
        for action in ('run', 'shell', 'start', 'stop', 'remove', 'logs', 'status'):
            self.assertEqual(self.run_launcher(action, '--dry-run').returncode, 0)
        self.assertFalse(self.calls.exists())
        self.assertFalse((self.base / 'data').exists())

    def test_default_run_is_isolated_and_handles_spaces(self):
        result = self.run_launcher('run')
        self.assertEqual(result.returncode, 0, result.stderr)
        command = self.commands()[-1]
        self.assertEqual(command[command.index('--network') + 1], 'none')
        self.assertIn('ROS_LOCALHOST_ONLY=1', command)
        self.assertIn(f'type=bind,src={self.workspace},dst=/home/unitree/unitree_robot_development', command)
        self.assertNotIn('--privileged', command)
        self.assertNotIn('--ipc', command)
        self.assertEqual(command[-2:], ['sleep', 'infinity'])

    def test_host_requires_interface(self):
        self.assertNotEqual(self.run_launcher('run', '--network', 'host').returncode, 0)
        self.assertFalse(self.calls.exists())

    def test_explicit_host_sets_network_and_dds(self):
        result = self.run_launcher('run', '--network', 'host', '--interface', 'enp3s0')
        self.assertEqual(result.returncode, 0, result.stderr)
        command = self.commands()[-1]
        self.assertEqual(command[command.index('--network') + 1], 'host')
        self.assertIn('ROS_LOCALHOST_ONLY=0', command)
        self.assertIn('UNITREE_NETWORK_INTERFACE=enp3s0', command)

    def test_existing_container_not_reconfigured(self):
        self.env['MOCK_EXISTS'] = '0'
        self.assertNotEqual(self.run_launcher('run').returncode, 0)
        self.assertEqual(len(self.commands()), 1)
        self.assertFalse((self.base / 'data').exists())

    def test_foreign_container_cannot_be_stopped(self):
        self.env['MOCK_LABEL'] = '<no value>'
        self.assertNotEqual(self.run_launcher('stop').returncode, 0)
        self.assertEqual(len(self.commands()), 1)

    def test_remove_does_not_force(self):
        self.assertEqual(self.run_launcher('remove').returncode, 0)
        self.assertEqual(self.commands()[-1], ['rm', 'review-test'])

    def test_invalid_interface_rejected(self):
        self.assertNotEqual(self.run_launcher('run', '--interface', 'eth0"/>').returncode, 0)
        self.assertFalse(self.calls.exists())

    def test_build_preview_does_not_contact_docker(self):
        result = subprocess.run([str(ROOT / 'build.sh'), '--dry-run'], env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('review-test:latest', result.stdout)
        self.assertFalse(self.calls.exists())


if __name__ == '__main__':
    unittest.main()
