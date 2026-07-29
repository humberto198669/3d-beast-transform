extends Node

signal auth_changed(logged_in: bool)
signal cloud_sync_finished(success: bool, message: String)

const PROJECT_URL := "https://iawxlqnrleztkhiwyeli.supabase.co"
const PUBLISHABLE_KEY := "sb_publishable_C3JA5_9VGnYpu0JD_yxz5g_Ut2lddE-"
const PASSWORD_RESET_URL := "https://humberto198669.github.io/3d-beast-transform/account/reset-password.html"
const SESSION_PATH := "user://supabase_session.cfg"

var access_token: String = ""
var refresh_token: String = ""
var user_id: String = ""

func _ready() -> void:
	_load_session()

func is_logged_in() -> bool:
	return not access_token.is_empty() and not user_id.is_empty()

func sign_up(email: String, password: String) -> Dictionary:
	var payload: Dictionary = {"email": email.strip_edges(), "password": password}
	var result: Dictionary = await _request_json(
		HTTPClient.METHOD_POST,
		PROJECT_URL + "/auth/v1/signup",
		_public_headers(),
		payload
	)
	_apply_auth_response(result)
	return result

func sign_in(email: String, password: String) -> Dictionary:
	var payload: Dictionary = {"email": email.strip_edges(), "password": password}
	var result: Dictionary = await _request_json(
		HTTPClient.METHOD_POST,
		PROJECT_URL + "/auth/v1/token?grant_type=password",
		_public_headers(),
		payload
	)
	_apply_auth_response(result)
	return result

func sign_out() -> void:
	if is_logged_in():
		await _request_json(
			HTTPClient.METHOD_POST,
			PROJECT_URL + "/auth/v1/logout",
			_authenticated_headers(),
			{}
		)
	_clear_session()
	auth_changed.emit(false)

func send_password_reset(email: String) -> Dictionary:
	var payload: Dictionary = {"email": email.strip_edges()}
	return await _request_json(
		HTTPClient.METHOD_POST,
		PROJECT_URL + "/auth/v1/recover?redirect_to=" + PASSWORD_RESET_URL.uri_encode(),
		_public_headers(),
		payload
	)

func update_password(new_password: String) -> Dictionary:
	if not is_logged_in():
		return {"ok": false, "message": "No hay una sesión iniciada."}
	return await _request_json(
		HTTPClient.METHOD_PUT,
		PROJECT_URL + "/auth/v1/user",
		_authenticated_headers(),
		{"password": new_password}
	)

func refresh_session() -> bool:
	if refresh_token.is_empty():
		return false
	var result: Dictionary = await _request_json(
		HTTPClient.METHOD_POST,
		PROJECT_URL + "/auth/v1/token?grant_type=refresh_token",
		_public_headers(),
		{"refresh_token": refresh_token}
	)
	_apply_auth_response(result)
	return bool(result.get("ok", false)) and is_logged_in()

func synchronize_progress() -> Dictionary:
	if not is_logged_in():
		return {"ok": false, "message": "No hay una sesión iniciada."}
	var remote_result: Dictionary = await download_cloud_progress()
	if int(remote_result.get("status", 0)) == 401 and await refresh_session():
		remote_result = await download_cloud_progress()
	if not bool(remote_result.get("ok", false)):
		return remote_result
	var rows_variant: Variant = remote_result.get("data", [])
	if rows_variant is Array:
		var rows: Array = rows_variant as Array
		if not rows.is_empty() and rows[0] is Dictionary:
			Progression.merge_cloud_progress(rows[0] as Dictionary)
	return await upload_local_progress()

func upload_local_progress() -> Dictionary:
	if not is_logged_in():
		return {"ok": false, "message": "No hay una sesión iniciada."}
	var local_data: Dictionary = Progression.export_progress_data()
	var payload: Dictionary = {
		"user_id": user_id,
		"save_version": int(local_data.get("save_version", 1)),
		"total_coins": int(local_data.get("total_coins", 0)),
		"total_distance": int(local_data.get("total_distance", 0)),
		"best_distance": int(local_data.get("best_distance", 0)),
		"selected_character_id": str(local_data.get("selected_character_id", "ethan")),
		"owned_character_ids": local_data.get("owned_character_ids", ["ethan"]),
		"sound_enabled": bool(local_data.get("sound_enabled", true)),
		"updated_at": Time.get_datetime_string_from_system(true),
	}
	var headers: PackedStringArray = _authenticated_headers()
	headers.append("Prefer: resolution=merge-duplicates,return=representation")
	var result: Dictionary = await _request_json(
		HTTPClient.METHOD_POST,
		PROJECT_URL + "/rest/v1/player_progress?on_conflict=user_id",
		headers,
		payload
	)
	cloud_sync_finished.emit(bool(result.get("ok", false)), str(result.get("message", "")))
	return result

func download_cloud_progress() -> Dictionary:
	if not is_logged_in():
		return {"ok": false, "message": "No hay una sesión iniciada."}
	return await _request_json(
		HTTPClient.METHOD_GET,
		PROJECT_URL + "/rest/v1/player_progress?user_id=eq." + user_id + "&select=*",
		_authenticated_headers()
	)

func _request_json(
	method: HTTPClient.Method,
	url: String,
	headers: PackedStringArray,
	payload: Dictionary = {}
) -> Dictionary:
	var request_node: HTTPRequest = HTTPRequest.new()
	add_child(request_node)
	var body: String = "" if method == HTTPClient.METHOD_GET else JSON.stringify(payload)
	var request_error: Error = request_node.request(url, headers, method, body)
	if request_error != OK:
		request_node.queue_free()
		return {"ok": false, "status": 0, "message": error_string(request_error)}
	var response: Array = await request_node.request_completed
	request_node.queue_free()
	var response_code: int = int(response[1])
	var response_body: PackedByteArray = response[3] as PackedByteArray
	var response_text: String = response_body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(response_text)
	var data: Variant = parsed if parsed != null else response_text
	var success: bool = response_code >= 200 and response_code < 300
	var message: String = "Solicitud completada." if success else _extract_error_message(data)
	return {"ok": success, "status": response_code, "data": data, "message": message}

func _public_headers() -> PackedStringArray:
	return PackedStringArray([
		"apikey: " + PUBLISHABLE_KEY,
		"Content-Type: application/json",
	])

func _authenticated_headers() -> PackedStringArray:
	var headers: PackedStringArray = _public_headers()
	headers.append("Authorization: Bearer " + access_token)
	return headers

func _apply_auth_response(result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		return
	var data_variant: Variant = result.get("data", {})
	if not data_variant is Dictionary:
		return
	var data: Dictionary = data_variant as Dictionary
	access_token = str(data.get("access_token", ""))
	refresh_token = str(data.get("refresh_token", ""))
	var user_variant: Variant = data.get("user", {})
	if user_variant is Dictionary:
		var user_data: Dictionary = user_variant as Dictionary
		user_id = str(user_data.get("id", ""))
	if is_logged_in():
		_save_session()
		auth_changed.emit(true)

func _extract_error_message(data: Variant) -> String:
	if data is Dictionary:
		var error_data: Dictionary = data as Dictionary
		return str(error_data.get("msg", error_data.get("message", error_data.get("error_description", "Error de conexión."))))
	return str(data)

func _save_session() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("session", "access_token", access_token)
	config.set_value("session", "refresh_token", refresh_token)
	config.set_value("session", "user_id", user_id)
	config.save(SESSION_PATH)

func _load_session() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SESSION_PATH) != OK:
		return
	access_token = str(config.get_value("session", "access_token", ""))
	refresh_token = str(config.get_value("session", "refresh_token", ""))
	user_id = str(config.get_value("session", "user_id", ""))

func _clear_session() -> void:
	access_token = ""
	refresh_token = ""
	user_id = ""
	var absolute_path: String = ProjectSettings.globalize_path(SESSION_PATH)
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(absolute_path)
