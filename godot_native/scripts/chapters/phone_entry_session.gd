extends RefCounted
## Transient mount/presentation clock, owned by ChapterOne. Never serialized.
## Source: P06_Tiyi, P14_Wechat, P15_Zjuding useState/useEffect mount contracts.
var owner: Dictionary={}
var family: String=""
var elapsed_ms:=0.0
var entry_allowed:=false
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

static func app_family(page: String) -> String:
	if page in ["system_chat","zjuding","directory","c3_campus_map","c35_network"] or page.begins_with("library_"): return "zjuding"
	return page

func route(state: Dictionary) -> void:
	var page: String=str(state.get("native",{}).get("page",""))
	if page=="control_center" and is_same(owner,state): return
	var next:=app_family(page)
	if is_same(owner,state) and next==family: return
	owner=state; family=next; elapsed_ms=0; phase=""; crash_recorded=false; blocked_hint_sent=false
	close_friend()
	entry_allowed=(state.get("networkMode")=="cellular") if family=="tiyi" else (state.get("networkMode")=="campus_wifi")
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

func advance(delta_ms: float) -> Array:
	var events: Array=[]
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
