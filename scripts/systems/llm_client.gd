extends Node
## LLM 客户端
## Web 导出不直接连接模型供应商：浏览器只请求同源 Node 代理。
## 代理从服务端环境变量读取密钥，并返回兼容 Web 平台的普通 JSON 响应。

const API_PATH = "/api/chat/completions"
const DEFAULT_PROXY_HOST = "127.0.0.1"
const DEFAULT_PROXY_PORT = 3000
const CONNECTION_TIMEOUT = 20.0

enum State {
	IDLE,
	CONNECTING,
	REQUESTING,
	RECEIVING,
	DONE
}

signal stream_token(token: String)
signal stream_completed(full_text: String)
signal stream_failed(error: String)

var _client: HTTPClient
var _state: int = State.IDLE
var _proxy_host: String = DEFAULT_PROXY_HOST
var _proxy_port: int = DEFAULT_PROXY_PORT
var _proxy_ssl: bool = false
var _pending_body: String = ""
var _response_body: String = ""
var _response_code: int = 0
var _response_started: bool = false
var _current_callback: Callable
var _connection_attempt_time: float = 0.0


func _ready() -> void:
	_client = HTTPClient.new()
	_configure_proxy()
	print("[LLMClient] 同源代理客户端就绪 (%s://%s:%d%s)" % [
		"https" if _proxy_ssl else "http",
		_proxy_host,
		_proxy_port,
		API_PATH
	])


func _configure_proxy() -> void:
	var env_host = OS.get_environment("SHUOGUANG_LLM_PROXY_HOST")
	var env_port = OS.get_environment("SHUOGUANG_LLM_PROXY_PORT")
	var env_ssl = OS.get_environment("SHUOGUANG_LLM_PROXY_SSL")
	if not env_host.is_empty():
		_proxy_host = env_host
	if env_port.is_valid_int():
		_proxy_port = env_port.to_int()
	if env_ssl.to_lower() in ["1", "true", "yes"]:
		_proxy_ssl = true

	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var bridge = Engine.get_singleton("JavaScriptBridge")
		var location_json = bridge.eval(
			"JSON.stringify({hostname: window.location.hostname, port: window.location.port, protocol: window.location.protocol})"
		)
		var json = JSON.new()
		if location_json is String and json.parse(location_json) == OK:
			var location = json.get_data()
			if location is Dictionary:
				_proxy_host = location.get("hostname", _proxy_host)
				_proxy_ssl = location.get("protocol", "http:") == "https:"
				var port_text = location.get("port", "")
				if port_text is String and port_text.is_valid_int():
					_proxy_port = port_text.to_int()
				else:
					_proxy_port = 443 if _proxy_ssl else 80


func _process(_delta: float) -> void:
	if _state in [State.IDLE, State.DONE]:
		return
	if Time.get_ticks_msec() / 1000.0 - _connection_attempt_time > CONNECTION_TIMEOUT:
		_fail("代理请求超时 (%.0fs)" % CONNECTION_TIMEOUT)
		return
	_poll_request()


func chat_stream(system_prompt: String, user_message: String, callback: Callable = Callable()) -> void:
	if _state not in [State.IDLE, State.DONE]:
		printerr("[LLMClient] 已有请求在进行中")
		return

	_current_callback = callback
	_pending_body = JSON.stringify({
		"messages": [
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": user_message}
		]
	})
	_response_body = ""
	_response_code = 0
	_response_started = false

	var tls_options = TLSOptions.client() if _proxy_ssl else null
	var err = _client.connect_to_host(_proxy_host, _proxy_port, tls_options)
	if err != OK:
		_fail("代理连接发起失败: %d" % err)
		return

	_state = State.CONNECTING
	_connection_attempt_time = Time.get_ticks_msec() / 1000.0
	print("[LLMClient] 请求同源代理 → %s:%d (prompt=%d chars)" % [
		_proxy_host, _proxy_port, system_prompt.length()
	])


func _poll_request() -> void:
	_client.poll()
	var status = _client.get_status()

	match _state:
		State.CONNECTING:
			if status in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
				return
			if status != HTTPClient.STATUS_CONNECTED:
				_fail("代理连接失败: status=%d" % status)
				return
			var err = _client.request(
				HTTPClient.METHOD_POST,
				API_PATH,
				["Content-Type: application/json", "Accept: application/json"],
				_pending_body
			)
			if err != OK:
				_fail("代理请求发送失败: %d" % err)
				return
			_state = State.REQUESTING

		State.REQUESTING, State.RECEIVING:
			if status == HTTPClient.STATUS_REQUESTING:
				return
			if status == HTTPClient.STATUS_BODY:
				if not _response_started:
					_response_started = true
					_response_code = _client.get_response_code()
				_state = State.RECEIVING
				var chunk = _client.read_response_body_chunk()
				if not chunk.is_empty():
					_response_body += chunk.get_string_from_utf8()
				return
			if _response_started and status in [HTTPClient.STATUS_CONNECTED, HTTPClient.STATUS_DISCONNECTED]:
				_finish_response()
				return
			if status == HTTPClient.STATUS_DISCONNECTED:
				_fail("代理连接提前断开")
				return
			_fail("代理请求异常: status=%d" % status)


func _finish_response() -> void:
	_state = State.DONE
	_client.close()
	if _response_code != 200:
		_fail("代理 HTTP %d: %s" % [_response_code, _response_body.left(200)])
		return

	var json = JSON.new()
	if json.parse(_response_body) != OK:
		_fail("代理响应不是合法 JSON")
		return
	var payload = json.get_data()
	if payload is not Dictionary:
		_fail("代理响应格式错误")
		return
	var content = payload.get("content", "")
	if content is not String or content.is_empty():
		_fail(payload.get("error", "代理未返回文本"))
		return

	# 保持既有 UI 信号兼容。Web 平台收到完整响应后一次性追加文本。
	stream_token.emit(content)
	stream_completed.emit(content)
	if _current_callback.is_valid():
		_current_callback.call(content)
	print("[LLMClient] 代理响应完成 (%d chars)" % content.length())


func _fail(message: String) -> void:
	_state = State.DONE
	if _client:
		_client.close()
	stream_failed.emit(message)
	if _current_callback.is_valid():
		_current_callback.call(message)
	printerr("[LLMClient] %s" % message)


func is_api_key_configured() -> bool:
	## 密钥只存在于代理服务端。客户端只能判断代理地址是否已配置。
	return not _proxy_host.is_empty() and _proxy_port > 0


func is_busy() -> bool:
	return _state not in [State.IDLE, State.DONE]
