extends RefCounted
## Optional in-game billing investigation, separate from the story wallet/network.
const DEFAULT={"bill_seen":false,"receipt_seen":false,"resolved":false}

static func account(s: Dictionary) -> Dictionary:
	return s.native.get("campus_network_account",DEFAULT)

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size()!=3:return false
	for key in DEFAULT:
		if not value.get(key) is bool:return false
	return not value.resolved or (value.bill_seen and value.receipt_seen)

static func dispatch(s: Dictionary,id: String,value: Variant) -> Dictionary:
	if id not in ["phone_network_document","phone_network_review"]:return {}
	if s.native.get("page","")!="zjuding":return {"handled":true,"message":""}
	var state=account(s).duplicate()
	var copy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/native/campus-services-copy.json")).network_billing
	var message=""
	if id=="phone_network_document":
		if value=="bill":state.bill_seen=true
		elif value=="receipt":state.receipt_seen=true
		else:return {"handled":true,"message":""}
	elif state.resolved:message=copy.notice_already_processed
	elif not state.bill_seen or not state.receipt_seen:message=copy.notice_unviewed
	elif value!="duplicate_billing":message=copy.notice_wrong_reason
	else:state.resolved=true;message=copy.notice_success
	s.native.campus_network_account=state
	return {"handled":true,"message":message}
