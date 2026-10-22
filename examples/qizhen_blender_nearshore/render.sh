#!/bin/bash
set -euo pipefail
base=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$base/runtime"/{home,config,data,cache} "$base/outputs"
display=${DISPLAY_NUM:-27}; auth="$base/runtime/xauth-$display"
xauth -f "$auth" add 127.0.0.1:$display MIT-MAGIC-COOKIE-1 "$(python3 -c 'import secrets;print(secrets.token_hex(16))')"
/usr/lib/xorg/Xorg :"$display" -config "$base/xorg.conf" -logfile "$base/outputs/xorg-$display.log" -auth "$auth" -nolisten local -nolisten unix -listen tcp -noreset > "$base/outputs/xorg-$display.out" 2>&1 &
pid=$!;trap 'kill "$pid" 2>/dev/null || true' EXIT
sleep 1
export DISPLAY=127.0.0.1:$display XAUTHORITY="$auth" HOME="$base/runtime/home" XDG_CONFIG_HOME="$base/runtime/config" XDG_DATA_HOME="$base/runtime/data" XDG_CACHE_HOME="$base/runtime/cache"
godot --path "$base/preview" --audio-driver Dummy --resolution 1280x720 --disable-vsync "$@"
