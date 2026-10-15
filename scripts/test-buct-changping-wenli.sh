#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd -- "$(dirname -- "$0")" && pwd)"
REPO="$(cd -- "$HERE/.." && pwd)"
ROOT="$(realpath "${1:-$REPO/godot_native}")"
MODE="${2:-headless}"
OUT="${BUCT_WENLI_QA_DIR:-$REPO/.buct-wenli-qa}"
mkdir -p "$OUT"/{tmp,config,cache,data,state,run,gpu}
export TMPDIR="$OUT/tmp" TEMP="$OUT/tmp" TMP="$OUT/tmp"
export XDG_CONFIG_HOME="$OUT/config" XDG_CACHE_HOME="$OUT/cache"
export XDG_DATA_HOME="$OUT/data" XDG_STATE_HOME="$OUT/state" XDG_RUNTIME_DIR="$OUT/run"
export BUCT_WENLI_PROOF_DIR="$OUT/gpu"
node "$HERE/check-buct-changping-wenli.mjs" "$ROOT"
case "$MODE" in
 import) godot --headless --audio-driver Dummy --path "$ROOT" --editor --import --quit;;
 headless) godot --headless --audio-driver Dummy --path "$ROOT" --script res://tests/test_buct_changping_wenli.gd;;
 proof) godot --audio-driver Dummy --path "$ROOT" --script res://tests/capture_buct_changping_wenli.gd;;
 *) echo 'Mode must be import, headless, or proof' >&2;exit 2;;
esac
