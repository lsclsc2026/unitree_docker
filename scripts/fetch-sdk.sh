#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
dest="${UNITREE_SDK_ROOT:-$root/../sdk}"
include_optional=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest) dest="${2:?需要目标目录}"; shift 2 ;;
    --all) include_optional=1; shift ;;
    --help) echo '用法: scripts/fetch-sdk.sh [--dest /absolute/workspace/sdk] [--all]'; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done
command -v git >/dev/null
mkdir -p "$dest"
dest="$(cd -- "$dest" && pwd)"
while read -r name revision url; do
  [[ -n "$name" && "$name" != \#* ]] || continue
  if [[ $include_optional == 0 && $name == unitree_sdk2_python ]]; then continue; fi
  path="$dest/$name"
  if [[ -e "$path" ]]; then
    [[ -d "$path/.git" ]] || { echo "拒绝覆盖非 Git 目录: $path" >&2; exit 1; }
    [[ $(git -C "$path" rev-parse HEAD) == "$revision" ]] || { echo "版本不匹配: $path" >&2; exit 1; }
    [[ -z $(git -C "$path" status --porcelain --untracked-files=normal) ]] || { echo "目录有修改: $path" >&2; exit 1; }
  else
    temporary="$(mktemp -d "$dest/.${name}.XXXXXX")"
    trap 'rm -rf -- "$temporary"' EXIT
    git -C "$temporary" init --quiet
    git -C "$temporary" remote add origin "$url"
    git -C "$temporary" fetch --depth 1 origin "$revision"
    git -C "$temporary" checkout --quiet --detach FETCH_HEAD
    [[ $(git -C "$temporary" rev-parse HEAD) == "$revision" ]]
    mv -- "$temporary" "$path"
    trap - EXIT
  fi
  printf '%s %s\n' "$name" "$revision"
done < "$root/sdk.lock.tsv"
(cd -- "$dest" && sha256sum --check "$root/sdk-binaries.sha256")
echo 'SDK 已准备；未编译、安装 Python 包或启动机器人。'
