#!/usr/bin/env bash
set -euo pipefail
ROOT="$(pwd)"
PROJECT="${1:-$ROOT/godot_native}"
MODE="${2:-headless}"
RUNTIME="$(mktemp -d "$ROOT/.buct-liuhu-qa.XXXXXX")"
mkdir -p "$RUNTIME"/{tmp,data,config,cache,state,run,evidence}
export TMPDIR="$RUNTIME/tmp" TMP="$RUNTIME/tmp" TEMP="$RUNTIME/tmp"
export XDG_DATA_HOME="$RUNTIME/data" XDG_CONFIG_HOME="$RUNTIME/config" XDG_CACHE_HOME="$RUNTIME/cache" XDG_STATE_HOME="$RUNTIME/state" XDG_RUNTIME_DIR="$RUNTIME/run"
export BUCT_LIUHU_OUTPUT="$RUNTIME/evidence"
node scripts/check-buct-changping-liuhu.mjs
case "$MODE" in
  headless) timeout 35s godot --headless --audio-driver Dummy --path "$PROJECT" --script res://tests/test_buct_changping_liuhu.gd ;;
  parse) timeout 15s godot --headless --audio-driver Dummy --path "$PROJECT" --check-only --script res://tests/capture_buct_changping_liuhu.gd ;;
  proof) timeout 75s godot --audio-driver Dummy --path "$PROJECT" --script res://tests/capture_buct_changping_liuhu.gd ;;
  *) echo "Use headless, parse or proof" >&2;exit 2 ;;
esac
printf 'Evidence retained at %s\n' "$BUCT_LIUHU_OUTPUT"
