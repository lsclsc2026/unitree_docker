#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
image="${UNITREE_IMAGE:-unitree-dev:humble-review}"
base="${UNITREE_BASE_IMAGE:-ros:humble-ros-base-jammy}"
cmd=(docker build --build-arg "BASE_IMAGE=$base" --build-arg "USER_UID=$(id -u)" --build-arg "USER_GID=$(id -g)" --tag "$image" "$root")
case "${1:---help}" in
  --dry-run) printf '%q ' "${cmd[@]}"; printf '\n' ;;
  --execute) [[ $# == 1 ]] || exit 2; command -v docker >/dev/null; "${cmd[@]}" ;;
  *) printf '用法: ./build.sh --dry-run | --execute\n变量: UNITREE_IMAGE, UNITREE_BASE_IMAGE (可设镜像 digest)\n'; [[ $# == 0 || ${1:-} == --help ]] ;;
esac
