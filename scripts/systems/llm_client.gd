extends Node
## Streaming LLM client.
##
## Built-in mode uses the same-origin proxy at /api/chat/completions.
## Custom mode uses an OpenAI-compatible chat/completions endpoint.

const PROXY_API_PATH = "/api/chat/completions"
const DEFAULT_PROXY_HOST = "127.0.0.1"
const DEFAULT_PROXY_PORT = 3000
const CONNECT_TIMEOUT = 15.0
const STREAM_IDLE_TIMEOUT = 30.0
const REQUEST_TOTAL_TIMEOUT = 120.0

enum State {
	IDLE,
	CONNECTING,
	REQUESTING,
	RECEIVING,
	EMITTING,
	DONE
}

signal stream_token(token: String)
signal stream_completed(full_text: String)
signal stream_failed(error: String)

var _client: HTTPClient
var _state: int = State.IDLE
var _host: String = DEFAULT_PROXY_HOST
var _port: int = DEFAULT_PROXY_PORT
var _ssl: bool = false
var _api_path: String = PROXY_API_PATH
var _use_custom_api: bool = false
var _api_key: String = ""
var _model: String = ""
var _settings_error: String = ""
var _request_headers: PackedStringArray = []
var _pending_body: String = ""
var _response_body: String = ""
var _response_code: int = 0
var _response_started: bool = false
var _current_callback: Callable
var _connection_attempt_time: float = 0.0
var _request_started_time: float = 0.0
var _last_activity_time: float = 0.0
var _stream_mode: bool = false
var _stream_buffer: String = ""
var _stream_full_text: String = ""
var _stream_completed_once: bool = false


func _ready() -> void:
	_client = HTTPClient.new()
	reload_settings()


func reload_settings() -> void:
	SettingsManager.load()
	_settings_error = SettingsManager.validate_llm_settings()
	_use_custom_api = SettingsManager.is_custom_llm_ready()
	if _use_custom_api:
		_configure_custom_api(SettingsManager.llm_base_url)
		_api_key = SettingsManager.llm_api_key.strip_edges()
		_model = SettingsManager.llm_model.strip_edges()
	else:
		_configure_builtin_proxy()
		_api_key = ""
		_model = ""

	var mode_label := "custom OpenAI-compatible API" if _use_custom_api else "same-origin proxy"
	if SettingsManager.llm_mode == SettingsManager.LLM_MODE_CUSTOM and not _settings_error.is_empty():
		mode_label = "custom API disabled: %s" % _settings_error
	print("[LLMClient] ready: %s (%s://%s:%d%s)" % [
		mode_label,
		"https" if _ssl else "http",
		_host,
		_port,
		_api_path
	])


func _configure_builtin_proxy() -> void:
	_host = DEFAULT_PROXY_HOST
	_port = DEFAULT_PROXY_PORT
	_ssl = false
	_api_path = PROXY_API_PATH

	var env_host := OS.get_environment("SHUOGUANG_LLM_PROXY_HOST")
	var env_port := OS.get_environment("SHUOGUANG_LLM_PROXY_PORT")
	var env_ssl := OS.get_environment("SHUOGUANG_LLM_PROXY_SSL")
	if not env_host.is_empty():
		_host = env_host
	if env_port.is_valid_int():
		_port = env_port.to_int()
	if env_ssl.to_lower() in ["1", "true", "yes"]:
		_ssl = true

	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var bridge = Engine.get_singleton("JavaScriptBridge")
		var location_json = bridge.eval(
			"JSON.stringify({hostname: window.location.hostname, port: window.location.port, protocol: window.location.protocol})"
		)
		var json = JSON.new()
		if location_json is String and json.parse(location_json) == OK:
			var location = json.get_data()
			if location is Dictionary:
				_host = location.get("hostname", _host)
				_ssl = location.get("protocol", "http:") == "https:"
				var port_text = location.get("port", "")
				if port_text is String and port_text.is_valid_int():
					_port = port_text.to_int()
				else:
					_port = 443 if _ssl else 80


func _configure_custom_api(base_url: String) -> void:
	var url := SettingsManager.normalize_llm_base_url(base_url)
	_ssl = true
	if url.begins_with("https://"):
		url = url.substr(8)
		_ssl = true
	elif url.begins_with("http://"):
		url = url.substr(7)
		_ssl = false

	var slash_index := url.find("/")
	var host_port := url
	var path_prefix := ""
	if slash_index >= 0:
		host_port = url.substr(0, slash_index)
		path_prefix = url.substr(slash_index).trim_suffix("/")

	_host = host_port
	_port = 443 if _ssl else 80
	var colon_index := host_port.rfind(":")
	if colon_index > 0:
		var port_text := host_port.substr(colon_index + 1)
		if port_text.is_valid_int():
			_port = port_text.to_int()
			_host = host_port.substr(0, colon_index)

	if path_prefix.ends_with("/chat/completions"):
		_api_path = path_prefix
	else:
		_api_path = path_prefix + "/chat/completions"


func _process(_delta: float) -> void:
	if _state in [State.IDLE, State.EMITTING, State.DONE]:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if _state == State.CONNECTING and now - _connection_attempt_time > CONNECT_TIMEOUT:
		_fail("connection timeout (%.0fs)" % CONNECT_TIMEOUT)
		return
	if _request_started_time > 0.0 and now - _request_started_time > REQUEST_TOTAL_TIMEOUT:
		_fail("request total timeout (%.0fs)" % REQUEST_TOTAL_TIMEOUT)
		return
	if _state in [State.REQUESTING, State.RECEIVING] and now - _last_activity_time > STREAM_IDLE_TIMEOUT:
		_fail("stream idle timeout (%.0fs)" % STREAM_IDLE_TIMEOUT)
		return
	_poll_request()


func chat_stream(system_prompt: String, user_message: String, history_messages: Variant = [], callback: Callable = Callable(), npc_id: String = "") -> void:
	if _state not in [State.IDLE, State.DONE]:
		printerr("[LLMClient] request already in progress")
		return

	if history_messages is Callable:
		callback = history_messages
		history_messages = []

	_current_callback = callback
	reload_settings()
	if SettingsManager.llm_mode == SettingsManager.LLM_MODE_CUSTOM and not _use_custom_api:
		_fail("invalid custom API settings: %s" % _settings_error)
		return

	var messages = _build_messages(system_prompt, user_message, history_messages)

	if _use_custom_api:
		_pending_body = JSON.stringify({
			"model": _model,
			"messages": messages,
			"max_tokens": 512,
			"temperature": 0.8,
			"stream": true
		})
		_request_headers = [
			"Content-Type: application/json",
			"Accept: text/event-stream",
			"Authorization: Bearer " + _api_key
		]
	else:
		_pending_body = JSON.stringify({"npc_id": npc_id, "messages": messages, "stream": true})
		_request_headers = [
			"Content-Type: application/json",
			"Accept: text/event-stream"
		]
	_stream_mode = true

	_response_body = ""
	_response_code = 0
	_response_started = false
	_stream_buffer = ""
	_stream_full_text = ""
	_stream_completed_once = false

	var tls_options = TLSOptions.client() if _ssl else null
	var err = _client.connect_to_host(_host, _port, tls_options)
	if err != OK:
		_fail("connection start failed: %d" % err)
		return

	var now := Time.get_ticks_msec() / 1000.0
	_state = State.CONNECTING
	_connection_attempt_time = now
	_request_started_time = now
	_last_activity_time = now
	print("[LLMClient] request %s:%d%s (prompt=%d chars)" % [_host, _port, _api_path, system_prompt.length()])


func _build_messages(system_prompt: String, user_message: String, history_messages: Variant) -> Array:
	var messages: Array = [{"role": "system", "content": system_prompt}]
	if history_messages is Array:
		for entry in history_messages:
			if entry is not Dictionary:
				continue
			var role := str(entry.get("role", ""))
			if role not in ["user", "assistant"]:
				continue
			var content := _string_or_empty(entry.get("content", "")).strip_edges()
			if content == "":
				continue
			messages.append({"role": role, "content": content})
	messages.append({"role": "user", "content": user_message})
	return messages


func _poll_request() -> void:
	_client.poll()
	var status = _client.get_status()

	match _state:
		State.CONNECTING:
			if status in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
				return
			if status != HTTPClient.STATUS_CONNECTED:
				_fail("connection failed: status=%d" % status)
				return
			var err = _client.request(HTTPClient.METHOD_POST, _api_path, _request_headers, _pending_body)
			if err != OK:
				_fail("request send failed: %d" % err)
				return
			_state = State.REQUESTING
			_last_activity_time = Time.get_ticks_msec() / 1000.0

		State.REQUESTING, State.RECEIVING:
			if status == HTTPClient.STATUS_REQUESTING:
				return
			if status == HTTPClient.STATUS_BODY:
				if not _response_started:
					_response_started = true
					_response_code = _client.get_response_code()
					_last_activity_time = Time.get_ticks_msec() / 1000.0
				_state = State.RECEIVING
				var chunk = _client.read_response_body_chunk()
				if not chunk.is_empty():
					_last_activity_time = Time.get_ticks_msec() / 1000.0
					var chunk_text := chunk.get_string_from_utf8()
					_response_body += chunk_text
					if _stream_mode and _response_code == 200:
						_consume_stream_chunk(chunk_text)
				return
			if _response_started and status in [HTTPClient.STATUS_CONNECTED, HTTPClient.STATUS_DISCONNECTED]:
				if _stream_mode:
					_finish_stream_response()
					return
				_finish_response()
				return
			if status == HTTPClient.STATUS_DISCONNECTED:
				_fail("connection closed early")
				return
			_fail("request error: status=%d" % status)


func _finish_response() -> void:
	_client.close()
	if _response_code != 200:
		_fail("HTTP %d: %s" % [_response_code, _response_body.left(200)])
		return

	var json = JSON.new()
	if json.parse(_response_body) != OK:
		_fail("response is not valid JSON")
		return
	var payload = json.get_data()
	if payload is not Dictionary:
		_fail("invalid response shape")
		return

	var content := ""
	if _use_custom_api:
		var choices = payload.get("choices", [])
		if choices is Array and choices.size() > 0:
			var message = choices[0].get("message", {})
			if message is Dictionary:
				content = _string_or_empty(message.get("content", ""))
	else:
		content = _string_or_empty(payload.get("content", ""))

	if content.is_empty():
		_fail(str(payload.get("error", "empty response")))
		return

	_emit_text_as_stream(content)


func _consume_stream_chunk(chunk_text: String) -> void:
	_stream_buffer += chunk_text.replace("\r\n", "\n")
	while true:
		var event_end := _stream_buffer.find("\n\n")
		if event_end < 0:
			break
		var event_text := _stream_buffer.substr(0, event_end)
		_stream_buffer = _stream_buffer.substr(event_end + 2)
		_process_stream_event(event_text)


func _process_stream_event(event_text: String) -> void:
	for raw_line in event_text.split("\n"):
		var line := String(raw_line).strip_edges()
		if not line.begins_with("data:"):
			continue
		var data := line.substr(5).strip_edges()
		if data == "[DONE]":
			_complete_stream_response()
			return
		if data.is_empty():
			continue
		var delta := _extract_stream_delta(data)
		if delta.is_empty():
			continue
		_stream_full_text += delta
		stream_token.emit(delta)


func _extract_stream_delta(data: String) -> String:
	var json := JSON.new()
	if json.parse(data) != OK:
		return ""
	var payload = json.get_data()
	if payload is not Dictionary:
		return ""
	var choices = payload.get("choices", [])
	if choices is Array and choices.size() > 0:
		var choice = choices[0]
		if choice is Dictionary:
			var delta = choice.get("delta", {})
			if delta is Dictionary:
				return _string_or_empty(delta.get("content", ""))
			var message = choice.get("message", {})
			if message is Dictionary:
				return _string_or_empty(message.get("content", ""))
	return _string_or_empty(payload.get("content", ""))


func _string_or_empty(value: Variant) -> String:
	if value == null:
		return ""
	return str(value)


func _finish_stream_response() -> void:
	if _stream_completed_once:
		return
	if _stream_buffer.strip_edges() != "":
		_process_stream_event(_stream_buffer)
		_stream_buffer = ""
	if _stream_full_text.is_empty():
		_stream_mode = false
		_finish_response()
		return
	_complete_stream_response()


func _complete_stream_response() -> void:
	if _stream_completed_once:
		return
	_stream_completed_once = true
	_state = State.DONE
	if _client:
		_client.close()
	stream_completed.emit(_stream_full_text)
	if _current_callback.is_valid():
		_current_callback.call(_stream_full_text)
	print("[LLMClient] stream completed (%d chars)" % _stream_full_text.length())


func _emit_text_as_stream(content: String) -> void:
	_state = State.EMITTING
	_stream_full_text = content
	var index := 0
	var chunk_size := 3
	while index < content.length():
		var length: int = mini(chunk_size, content.length() - index)
		stream_token.emit(content.substr(index, length))
		index += length
		await get_tree().create_timer(0.015).timeout
	_state = State.DONE
	stream_completed.emit(content)
	if _current_callback.is_valid():
		_current_callback.call(content)
	print("[LLMClient] response completed (%d chars)" % content.length())


func _fail(message: String) -> void:
	_state = State.DONE
	if _client:
		_client.close()
	stream_failed.emit(message)
	if _current_callback.is_valid():
		_current_callback.call(message)
	printerr("[LLMClient] %s" % message)


func is_api_key_configured() -> bool:
	if _use_custom_api:
		return not _api_key.is_empty()
	return not _host.is_empty() and _port > 0


func is_busy() -> bool:
	return _state not in [State.IDLE, State.DONE]
