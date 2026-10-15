#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO="$(cd -- "$HERE/.." && pwd)"
ROOT="$(realpath "${1:-$REPO/godot_native}")"
MODE="${2:-headless}"
OUT="${BUCT_HD_QA_DIR:-$REPO/.buct-wenli-hd-qa}"
mkdir -p "$OUT"/{tmp,config,cache,data,state,run,gpu}
export TMPDIR="$OUT/tmp" TEMP="$OUT/tmp" TMP="$OUT/tmp"
export XDG_CONFIG_HOME="$OUT/config" XDG_CACHE_HOME="$OUT/cache"
export XDG_DATA_HOME="$OUT/data" XDG_STATE_HOME="$OUT/state" XDG_RUNTIME_DIR="$OUT/run" BUCT_HD_QA_DIR="$OUT"
node "$HERE/check-buct-changping-hd-region.mjs" "$ROOT"
case "$MODE" in
 import) godot --headless --audio-driver Dummy --path "$ROOT" --editor --import --quit;;
 headless) godot --headless --audio-driver Dummy --path "$ROOT" --script res://tests/test_buct_changping_hd_region.gd;;
 proof) godot --audio-driver Dummy --path "$ROOT" --script res://tests/capture_buct_changping_hd_region.gd;;
 *) echo 'Mode must be import, headless, or proof' >&2;exit 2;;
esac
