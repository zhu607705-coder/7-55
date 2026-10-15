#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd -- "$(dirname -- "$0")/.." && pwd)"
ROOT="$REPO/godot_native"
MODE="${1:-headless}"
OUT="${BUCT_NORTH_QA_DIR:-$REPO/.buct-north-hd-qa}"
mkdir -p "$OUT"/{tmp,config,cache,data,state,run,gpu}
export BUCT_NORTH_QA_DIR="$OUT" TMPDIR="$OUT/tmp" TMP="$OUT/tmp" TEMP="$OUT/tmp"
export XDG_CONFIG_HOME="$OUT/config" XDG_CACHE_HOME="$OUT/cache" XDG_DATA_HOME="$OUT/data" XDG_STATE_HOME="$OUT/state" XDG_RUNTIME_DIR="$OUT/run"
case "$MODE" in
 import) godot --headless --audio-driver Dummy --path "$ROOT" --editor --import --quit;;
 headless) godot --headless --audio-driver Dummy --path "$ROOT" --script res://tests/test_buct_changping_north_region.gd;;
 walk) BUCT_NORTH_DEFAULT=1 godot --headless --audio-driver Dummy --path "$ROOT" --script res://tests/test_buct_changping_north_preparation.gd;;
 preview) godot --audio-driver Dummy --fixed-fps 20 --resolution 1280x720 --path "$ROOT" --script res://tests/preview_buct_changping_north_region.gd;;
 manual) godot --audio-driver Dummy --resolution 1280x720 --path "$ROOT" --script res://tests/manual_buct_changping_entry.gd -- --fresh;;
 proof) godot --audio-driver Dummy --resolution 1280x720 --path "$ROOT" --script res://tests/capture_buct_changping_north_region.gd;;
 *) echo 'Mode must be import, headless, walk, proof, preview, or manual' >&2; exit 2;;
esac
