"""Check default dependency selection with local fixtures and no network access."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class FetchSdkTests(unittest.TestCase):
    def invoke(self, *arguments):
        temporary = tempfile.TemporaryDirectory(prefix='.sdk-test-', dir=ROOT)
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        (root / 'scripts').mkdir()
        shutil.copyfile(ROOT / 'scripts/fetch-sdk.sh', root / 'scripts/fetch-sdk.sh')
        fixtures = root / 'fixtures'
        fixture_files = {
            'unitree_sdk2': {'lib/x86_64/libunitree_sdk2.a': 'x86 fixture',
                             'lib/aarch64/libunitree_sdk2.a': 'arm fixture'},
            'unitree_ros2': {'cyclonedds_ws/src/unitree/unitree_api/package.xml': '<package/>'},
            'unitree_ros': {'robots/a2_description/urdf/a2.urdf': '<robot/>',
                            'robots/a2_description/meshes/base_link.STL': 'mesh fixture',
                            'LICENSE': 'license fixture'},
            'unitree_sdk2_python': {'setup.py': '# optional Python SDK'},
        }
        for name, files in fixture_files.items():
            for relative, content in files.items():
                path = fixtures / name / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content)
        # Keep production lock ordering/selection while replacing only the remote.
        rows = []
        for line in (ROOT / 'sdk.lock.tsv').read_text().splitlines():
            if not line or line.startswith('#'):
                continue
            name, revision, _ = line.split()
            rows.append(f'{name} {revision} fixture://{name}')
        (root / 'sdk.lock.tsv').write_text('\n'.join(rows) + '\n')
        checksum_rows = []
        for relative, content in fixture_files['unitree_sdk2'].items():
            checksum_rows.append(f'{hashlib.sha256(content.encode()).hexdigest()}  unitree_sdk2/{relative}')
        (root / 'sdk-binaries.sha256').write_text('\n'.join(checksum_rows) + '\n')
        mock_bin = root / 'mock-bin'
        mock_bin.mkdir()
        git = mock_bin / 'git'
        git.write_text('''#!/usr/bin/env python3
import os, pathlib, shutil, sys
path = pathlib.Path(sys.argv[2])
args = sys.argv[3:]
metadata = path / '.git'
if args[0] == 'init':
    metadata.mkdir()
elif args[:2] == ['remote', 'add']:
    (metadata / 'fixture-name').write_text(args[3].split('://')[1])
elif args[0] == 'fetch':
    (metadata / 'revision').write_text(args[-1])
elif args[0] == 'checkout':
    source = pathlib.Path(os.environ['SDK_FIXTURES']) / (metadata / 'fixture-name').read_text()
    shutil.copytree(source, path, dirs_exist_ok=True)
elif args[0] == 'rev-parse':
    print((metadata / 'revision').read_text())
elif args[0] != 'status':
    raise SystemExit('unexpected mock Git command: ' + repr(args))
''')
        git.chmod(0o755)
        dest = root / 'downloaded-sdk'
        env = dict(os.environ, PATH=str(mock_bin) + ':' + os.environ['PATH'], SDK_FIXTURES=str(fixtures))
        result = subprocess.run(['bash', str(root / 'scripts/fetch-sdk.sh'), '--dest', str(dest), *arguments],
                                env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return dest

    def test_default_fetch_includes_navigation_models_but_not_python(self):
        dest = self.invoke()
        self.assertEqual({p.name for p in dest.iterdir()}, {'unitree_sdk2', 'unitree_ros2', 'unitree_ros'})
        self.assertTrue((dest / 'unitree_ros/robots/a2_description/urdf/a2.urdf').is_file())
        self.assertTrue((dest / 'unitree_ros/robots/a2_description/meshes/base_link.STL').is_file())
        self.assertTrue((dest / 'unitree_ros/LICENSE').is_file())
        self.assertFalse((dest / 'unitree_sdk2_python').exists())

    def test_all_adds_optional_python_sdk(self):
        dest = self.invoke('--all')
        self.assertTrue((dest / 'unitree_ros/robots/a2_description/urdf/a2.urdf').is_file())
        self.assertTrue((dest / 'unitree_sdk2_python/setup.py').is_file())


if __name__ == '__main__':
    unittest.main()
