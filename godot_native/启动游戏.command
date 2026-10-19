#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
  exec /Applications/Godot.app/Contents/MacOS/Godot --path "$project_dir"
fi
if command -v godot >/dev/null 2>&1; then
  exec godot --path "$project_dir"
fi
printf '%s\n' '请安装 Godot 4.6.3 或兼容的更新版本，然后打开本目录 project.godot。'
exit 1
