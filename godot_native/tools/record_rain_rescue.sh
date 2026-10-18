#!/usr/bin/env bash
# Record the actual Main/session clock on an existing X11 display (Xvfb works).
# Never infer a window rectangle from the X11 screen size: a larger screen
# centers the client and silently crops its bottom if capture starts at 0,0.
set -euo pipefail
project=$(cd "$(dirname "$0")/.." && pwd)
out=${1:?Usage: record_rain_rescue.sh OUTPUT_DIRECTORY (requires DISPLAY)}
: "${DISPLAY:?Start an X11 server or use xvfb-run before recording}"
for command in godot ffmpeg ffprobe xwininfo python3 timeout sha256sum; do command -v "$command" >/dev/null; done
mkdir -p "$out"
out=$(cd "$out" && pwd)
sha256sum "$project/tests/test_rain_rescue.gd" "$project/tools/record_rain_rescue.sh" "$project/scripts/media/c3_rain_rescue.gd" "$project/scripts/media/c3_rain_rescue_model.gd" "$project/scripts/media/c3_rain_rescue_session.gd" "$project/scripts/media/c3_rain_rescue_native/renderer.gd" >"$out/recording-source-sha256.txt"
sync_dir=$(mktemp -d)
game_pid= recorder_pid=
cleanup() {
  [[ -z "$recorder_pid" ]] || kill "$recorder_pid" 2>/dev/null || true
  [[ -z "$game_pid" ]] || kill "$game_pid" 2>/dev/null || true
  rm -rf "$sync_dir"
}
trap cleanup EXIT
# A temporary HOME also avoids inheriting real saves/settings into the test.
export HOME="$sync_dir/home" XDG_DATA_HOME="$sync_dir/data" XDG_CONFIG_HOME="$sync_dir/config" XDG_CACHE_HOME="$sync_dir/cache" XDG_STATE_HOME="$sync_dir/state"
mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
export GODOT_TEST_USER_DATA_DIR="$XDG_DATA_HOME/SevenFiftyFiveNative" GODOT_SILENCE_ROOT_WARNING=1
export RAIN_RESCUE_CAPTURE_DIR="$out" RAIN_RESCUE_RECORDING_SYNC_DIR="$sync_dir"
timeout 60 godot --path "$project" --audio-driver Dummy --resolution 1280x720 --position 0,0 --borderless --script res://tests/test_rain_rescue.gd -- --graphical-real-focus >"$out/graphical-final.log" 2>&1 &
game_pid=$!
for ((i=0; i<300; i++)); do
  [[ ! -s "$sync_dir/window-ready.json" ]] || break
  if ! kill -0 "$game_pid" 2>/dev/null; then cat "$out/graphical-final.log"; wait "$game_pid"; exit 1; fi
  sleep .05
done
[[ -s "$sync_dir/window-ready.json" ]] || { cat "$out/graphical-final.log"; echo 'Window handshake timed out' >&2; exit 1; }
window_id=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["windowId"])' "$sync_dir/window-ready.json")
xwininfo -id "$window_id" >"$out/recording-xwininfo.txt"
python3 - "$sync_dir/window-ready.json" "$out/recording-xwininfo.txt" "$out/recording-window.json" <<'PY'
import json,re,sys
reported=json.load(open(sys.argv[1]))
x11=open(sys.argv[2]).read()
def field(label):
    match=re.search(r'^\s*'+re.escape(label)+r':\s*(-?\d+)\s*$',x11,re.M)
    if not match: raise SystemExit('Missing X11 field: '+label)
    return int(match.group(1))
actual=[field('Absolute upper-left X'),field('Absolute upper-left Y'),field('Width'),field('Height')]
assert actual==[0,0,1280,720], ('Unexpected actual X11 client rectangle',actual)
assert reported['windowPosition']==actual[:2] and reported['windowSize']==actual[2:], (reported,actual)
assert reported['rootTextureSize']==actual[2:], ('Root render differs from capture size',reported)
reported['verifiedX11Rect']=actual
reported['captureRect']=actual
json.dump(reported,open(sys.argv[3],'w'),indent=2)
print('Verified X11 client and root render: '+str(actual))
PY
cp "$out/recording-window.json" "$sync_dir/verified-window.json"
# Read the verified rectangle rather than silently relying on command-line intent.
read -r width height x y < <(python3 -c 'import json,sys;x,y,w,h=json.load(open(sys.argv[1]))["captureRect"];print(w,h,x,y)' "$out/recording-window.json")
ffmpeg -hide_banner -loglevel warning -y -f x11grab -framerate 30 -video_size "${width}x${height}" -i "$DISPLAY+$x,$y" -t 24 -c:v libx264 -preset ultrafast -crf 20 -pix_fmt yuv420p -movflags +faststart -progress "$sync_dir/ffmpeg-progress" "$out/rain_continuation_real_time.mp4" >"$out/recording-final.log" 2>&1 &
recorder_pid=$!
for ((i=0; i<200; i++)); do
  if [[ -s "$sync_dir/ffmpeg-progress" ]] && grep -Eq '^frame=[1-9][0-9]*$' "$sync_dir/ffmpeg-progress"; then break; fi
  if ! kill -0 "$recorder_pid" 2>/dev/null; then cat "$out/recording-final.log"; wait "$recorder_pid"; exit 1; fi
  sleep .05
done
grep -Eq '^frame=[1-9][0-9]*$' "$sync_dir/ffmpeg-progress" || { echo 'Recorder produced no initial frame' >&2; exit 1; }
touch "$sync_dir/capture-started"
wait "$recorder_pid"; recorder_pid=
touch "$sync_dir/capture-finished"
wait "$game_pid"; game_pid=
ffprobe -v error -show_entries format=duration:stream=codec_name,width,height,r_frame_rate -of json "$out/rain_continuation_real_time.mp4" >"$out/recording-final.json"
for second in 0 5 10 18; do
  ffmpeg -hide_banner -loglevel error -y -ss "$second" -i "$out/rain_continuation_real_time.mp4" -frames:v 1 "$out/video-${second}s.png"
done
ffmpeg -hide_banner -loglevel error -y -sseof -0.1 -i "$out/rain_continuation_real_time.mp4" -frames:v 1 "$out/video-final.png"
cat "$out/graphical-final.log"
