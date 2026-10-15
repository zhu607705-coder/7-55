#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for relative in rpg/cinematics/chapter4-prologue/chapter35_to_chapter4_h3_transition rpg/cinematics/qizhen-rain-rescue/qizhen_rain_rescue_hailuo23_v01; do
  ffmpeg -nostdin -y -v error -i "$ROOT/assets/$relative.mp4" -c:v libtheora -q:v 8 -c:a libvorbis -q:a 5 "$ROOT/assets/$relative.ogv"
done
