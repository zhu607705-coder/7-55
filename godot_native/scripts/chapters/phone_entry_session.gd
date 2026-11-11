extends RefCounted
const TiyiAccess=preload("res://scripts/chapters/tiyi_access.gd")
## Transient mount/presentation clock, owned by ChapterOne. Never serialized.
## Source: P06_Tiyi, P14_Wechat, P15_Zjuding useState/useEffect mount contracts.
const TIYI_PACKAGE_MB := 87.0
const TIYI_CACHED_MB := 45.0
const TIYI_DOWNLOAD_MS := 30000.0
const TIYI_RATE_INTERVAL_MS := 2000.0
const TIYI_AVERAGE_MBPS := (TIYI_PACKAGE_MB - TIYI_CACHED_MB) / (TIYI_DOWNLOAD_MS / 1000.0)
var owner: Dictionary={}
var family: String=""
var elapsed_ms:=0.0
var entry_allowed:=false
var tiyi_update_blocked:=false
var phase: String=""
var crash_recorded:=false
var friend_open:=false
var friend_elapsed_ms:=0.0
var friend_phase:=0
var friend_running:=false
var friend_skipped:=false
var laugh_at_ms:=13942.0
var arrival_sent:=false
var blocked_hint_sent:=false
var tiyi_download_elapsed_ms := 0.0
var tiyi_downloaded_mb := 0.0
var tiyi_download_rates: Array[float] = []
var tiyi_download_sample_usec := -1
var tiyi_download_sample_online := false

static func app_family(page: String) -> String:
	if page in ["system_chat","zjuding","directory","c3_campus_map","c35_network"] or page.begins_with("library_"): return "zjuding"
	return page

func route(state: Dictionary) -> void:
	var page: String=str(state.get("native",{}).get("page",""))
	if page=="control_center" and is_same(owner,state): return
	var next:=app_family(page)
	if is_same(owner,state) and next==family: return
	if not is_same(owner, state):
		tiyi_download_rates.clear()
		tiyi_download_elapsed_ms = 0.0
		tiyi_downloaded_mb = 0.0
	owner=state; family=next; elapsed_ms=0; phase=""; crash_recorded=false; blocked_hint_sent=false
	close_friend()
	tiyi_update_blocked=family=="tiyi" and TiyiAccess.needs_update(state)
	entry_allowed=TiyiAccess.allowed(state) if family=="tiyi" else (state.get("networkMode")=="campus_wifi")
	if family in ["tiyi","zjuding"]: phase="loading"

func start_friend() -> void:
	friend_open=true
	if friend_running: return
	friend_elapsed_ms=0; friend_phase=0; friend_skipped=false; arrival_sent=false; laugh_at_ms=13942
	friend_running=true

func close_friend() -> void:
	friend_open=false; friend_running=false; friend_elapsed_ms=0; friend_phase=0; friend_skipped=false; arrival_sent=false

func skip_friend() -> bool:
	if not friend_running or friend_phase!=2 or friend_elapsed_ms<4000: return false
	friend_skipped=true; laugh_at_ms=friend_elapsed_ms
	return true

func start_tiyi_download() -> void:
	if not tiyi_download_rates.is_empty(): return
	tiyi_download_elapsed_ms = 0.0
	tiyi_downloaded_mb = TIYI_CACHED_MB
	tiyi_download_sample_usec = Time.get_ticks_usec()
	tiyi_download_sample_online = true
	# Pair the random rates around the mean so the 42 MB still takes 30 online seconds.
	var intervals := roundi(TIYI_DOWNLOAD_MS / TIYI_RATE_INTERVAL_MS)
	for _pair: int in range(floori(intervals * .5)):
		var speed := randi_range(8, 20) / 10.0
		tiyi_download_rates.append(speed)
		tiyi_download_rates.append(2.0 * TIYI_AVERAGE_MBPS - speed)
	tiyi_download_rates.append(TIYI_AVERAGE_MBPS)
	tiyi_download_rates.shuffle()

func tiyi_download_speed() -> float:
	if tiyi_download_rates.is_empty() or owner.get("networkMode") == "offline": return 0.0
	var index := mini(floori(tiyi_download_elapsed_ms / TIYI_RATE_INTERVAL_MS), tiyi_download_rates.size() - 1)
	return tiyi_download_rates[index]

func take_completed_tiyi_download() -> bool:
	if tiyi_download_rates.is_empty() or tiyi_download_elapsed_ms < TIYI_DOWNLOAD_MS: return false
	tiyi_download_rates.clear()
	return true

func reset_tiyi_download_clock() -> void:
	tiyi_download_sample_usec = -1

func _advance_tiyi_download(delta_ms: float, sample_usec: int) -> bool:
	if tiyi_download_rates.is_empty(): return false
	var online: bool = owner.get("networkMode") != "offline"
	if sample_usec >= 0:
		# Process delta is clamped when rendering stalls. The download uses
		# the time between active samples, with no credit across a pause.
		delta_ms = 0.0
		if tiyi_download_sample_usec >= 0 and tiyi_download_sample_online:
			delta_ms = (sample_usec - tiyi_download_sample_usec) / 1000.0
		tiyi_download_sample_usec = sample_usec
		tiyi_download_sample_online = online
	if online:
		var until := minf(TIYI_DOWNLOAD_MS, tiyi_download_elapsed_ms + maxf(0.0, delta_ms))
		while tiyi_download_elapsed_ms < until:
			var interval_end := (floori(tiyi_download_elapsed_ms / TIYI_RATE_INTERVAL_MS) + 1) * TIYI_RATE_INTERVAL_MS
			var stop_at := minf(until, interval_end)
			tiyi_downloaded_mb += tiyi_download_speed() * (stop_at - tiyi_download_elapsed_ms) / 1000.0
			tiyi_download_elapsed_ms = stop_at
	if tiyi_download_elapsed_ms < TIYI_DOWNLOAD_MS: return false
	tiyi_downloaded_mb = TIYI_PACKAGE_MB
	return true

func advance(delta_ms: float, sample_usec: int = -1) -> Array:
	var events: Array=[]
	if _advance_tiyi_download(delta_ms, sample_usec):
		events.append({"action": "c2_tiyi_download_finished"})
	elapsed_ms+=maxf(0,delta_ms)
	if family=="tiyi":
		if phase=="loading" and entry_allowed and elapsed_ms>=1400:
			phase="ready"; events.append({"action":"phone_refresh"})
		elif phase=="loading" and not entry_allowed and elapsed_ms>=3000:
			phase="crashing"; events.append({"action":"c1_tiyi_crash"})
		if phase=="crashing" and elapsed_ms>=3620:
			phase="exiting"; events.append({"action":"c1_tiyi_exit"})
	elif family=="zjuding" and phase=="loading":
		if entry_allowed and elapsed_ms>=1500:
			phase="ready"; events.append({"action":"phone_refresh"})
		elif not entry_allowed and elapsed_ms>=3000 and not blocked_hint_sent:
			blocked_hint_sent=true; events.append({"action":"phone_refresh"}); events.append({"feedback":"请连接校园网后重新进入浙大钉。"})
	if family=="wechat" and friend_running:
		friend_elapsed_ms+=maxf(0,delta_ms)
		if friend_elapsed_ms>=900 and not arrival_sent:
			arrival_sent=true; friend_phase=1; events.append({"cue":"native_wechat_message_arrived"})
		if friend_elapsed_ms>=2000 and friend_phase<2:
			friend_phase=2; events.append({"cue":"xiaoying_attack"})
		if friend_elapsed_ms>=laugh_at_ms and friend_phase==2:
			friend_phase=3; events.append({"cue":"xy_laugh"})
		if friend_phase==3 and friend_elapsed_ms>=laugh_at_ms+5380:
			friend_phase=4; friend_running=false
			events.append({"action":"c1_scatter_complete","value":{"phase":4,"elapsedMs":int(round(friend_elapsed_ms)),"skipped":friend_skipped}})
	return events
