#!/usr/bin/env bash
set -euo pipefail
# Run from the repository root. Imports must already exist (normal project setup).
ROOT="$(pwd)"
PROJECT="${1:-$ROOT/godot_native}"
MODE="${2:-headless}"
RUNTIME="$(mktemp -d "$ROOT/.buct-east-road-qa.XXXXXX")"
mkdir -p "$RUNTIME"/{tmp,data,config,cache,state,run,evidence}
export TMPDIR="$RUNTIME/tmp" TMP="$RUNTIME/tmp" TEMP="$RUNTIME/tmp"
export XDG_DATA_HOME="$RUNTIME/data" XDG_CONFIG_HOME="$RUNTIME/config" XDG_CACHE_HOME="$RUNTIME/cache" XDG_STATE_HOME="$RUNTIME/state" XDG_RUNTIME_DIR="$RUNTIME/run"
export BUCT_EAST_ROAD_OUTPUT="$RUNTIME/evidence"
node scripts/check-buct-changping-east-road.mjs
case "$MODE" in
  headless) timeout 100s godot --headless --audio-driver Dummy --path "$PROJECT" --script res://tests/test_buct_changping_east_road.gd ;;
  proof) timeout 120s godot --audio-driver Dummy --path "$PROJECT" --script res://tests/capture_buct_changping_east_road.gd ;;
  leaf) timeout 15s godot --audio-driver Dummy --path "$PROJECT" --script res://tests/probe_buct_changping_east_road_leaf_walk.gd ;;
  parse) timeout 15s godot --headless --audio-driver Dummy --path "$PROJECT" --check-only --script res://tests/capture_buct_changping_east_road.gd ;;
  *) echo "Use headless, proof, leaf, or parse" >&2; exit 2 ;;
esac
printf 'Evidence retained at %s\n' "$BUCT_EAST_ROAD_OUTPUT"
