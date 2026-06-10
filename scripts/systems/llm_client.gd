extends Node
## LLM 客户端 — 双模：编辑器直连 / Web 代理
##
## 编辑器/桌面运行（非 Web 平台）：
##   从环境变量 DEEPSEEK_API_KEY 读取密钥，直接 HTTPS 请求 api.deepseek.com。
##   环境变量设置方式（PowerShell）：
##     $env:DEEPSEEK_API_KEY="sk-xxxxxxxx"
##     然后在同一终端中启动 Godot 编辑器。
##
## Web 导出：
##   浏览器 CORS 限制无法直连外部 API，必须通过同源 Node 代理转发。
##   代理从 process.env.DEEPSEEK_API_KEY 读取密钥，返回简化 JSON。

const DEEPSEEK_API_HOST = "api.deepseek.com"
const DEEPSEEK_API_PATH = "/v1/chat/completions"
const DEEPSEEK_MODEL = "deepseek-chat"

const PROXY_API_PATH = "/api/chat/completions"
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
var _api_path: String = PROXY_API_PATH
var _use_direct_api: bool = false
var _api_key: String = ""
var _request_headers: PackedStringArray = []
var _pending_body: String = ""
var _response_body: String = ""
var _response_code: int = 0
var _response_started: bool = false
var _current_callback: Callable
var _connection_attempt_time: float = 0.0


func _ready() -> void:
	_client = HTTPClient.new()
	_configure_connection()
	var mode_label = "直连 DeepSeek API" if _use_direct_api else "同源代理"
	print("[LLMClient] %s 就绪 (%s://%s:%d%s)" % [
		mode_label,
		"https" if _proxy_ssl else "http",
		_proxy_host,
		_proxy_port,
		_api_path
	])


func _configure_connection() -> void:
	# --- 环境变量覆盖代理配置（始终有效） ---
	var env_host = OS.get_environment("SHUOGUANG_LLM_PROXY_HOST")
	var env_port = OS.get_environment("SHUOGUANG_LLM_PROXY_PORT")
	var env_ssl = OS.get_environment("SHUOGUANG_LLM_PROXY_SSL")
	if not env_host.is_empty():
		_proxy_host = env_host
	if env_port.is_valid_int():
		_proxy_port = env_port.to_int()
	if env_ssl.to_lower() in ["1", "true", "yes"]:
		_proxy_ssl = true

	# --- Web 平台：始终走同源代理 ---
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
		_api_path = PROXY_API_PATH
		_use_direct_api = false
		return

	# --- 非 Web 平台：检测 DEEPSEEK_API_KEY → 直连 ---
	var key = OS.get_environment("DEEPSEEK_API_KEY")
	if not key.is_empty():
		_api_key = key
		_proxy_host = DEEPSEEK_API_HOST
		_proxy_port = 443
		_proxy_ssl = true
		_api_path = DEEPSEEK_API_PATH
		_use_direct_api = true
		return

	# --- 无密钥：回退代理模式 ---
	_api_path = PROXY_API_PATH
	_use_direct_api = false


func _process(_delta: float) -> void:
	if _state in [State.IDLE, State.DONE]:
		return
	if Time.get_ticks_msec() / 1000.0 - _connection_attempt_time > CONNECTION_TIMEOUT:
		_fail("请求超时 (%.0fs)" % CONNECTION_TIMEOUT)
		return
	_poll_request()


func chat_stream(system_prompt: String, user_message: String, callback: Callable = Callable()) -> void:
	if _state not in [State.IDLE, State.DONE]:
		printerr("[LLMClient] 已有请求在进行中")
		return

	_current_callback = callback
	var messages = [
		{"role": "system", "content": system_prompt},
		{"role": "user", "content": user_message}
	]

	if _use_direct_api:
		# 直连 DeepSeek API：构建完整请求体
		_pending_body = JSON.stringify({
			"model": DEEPSEEK_MODEL,
			"messages": messages,
			"max_tokens": 512,
			"temperature": 0.8,
			"stream": false
		})
		_request_headers = [
			"Content-Type: application/json",
			"Accept: application/json",
			"Authorization: Bearer " + _api_key
		]
	else:
		# 代理模式：代理会补充 model 等字段
		_pending_body = JSON.stringify({"messages": messages})
		_request_headers = [
			"Content-Type: application/json",
			"Accept: application/json"
		]

	_response_body = ""
	_response_code = 0
	_response_started = false

	var tls_options = TLSOptions.client() if _proxy_ssl else null
	var err = _client.connect_to_host(_proxy_host, _proxy_port, tls_options)
	if err != OK:
		_fail("连接发起失败: %d" % err)
		return

	_state = State.CONNECTING
	_connection_attempt_time = Time.get_ticks_msec() / 1000.0
	var target_label = "DeepSeek API" if _use_direct_api else "同源代理"
	print("[LLMClient] 请求 %s → %s:%d (prompt=%d chars)" % [
		target_label, _proxy_host, _proxy_port, system_prompt.length()
	])


func _poll_request() -> void:
	_client.poll()
	var status = _client.get_status()

	match _state:
		State.CONNECTING:
			if status in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
				return
			if status != HTTPClient.STATUS_CONNECTED:
				_fail("连接失败: status=%d" % status)
				return
			var err = _client.request(
				HTTPClient.METHOD_POST,
				_api_path,
				_request_headers,
				_pending_body
			)
			if err != OK:
				_fail("请求发送失败: %d" % err)
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
				_fail("连接提前断开")
				return
			_fail("请求异常: status=%d" % status)


func _finish_response() -> void:
	_state = State.DONE
	_client.close()
	if _response_code != 200:
		_fail("HTTP %d: %s" % [_response_code, _response_body.left(200)])
		return

	var json = JSON.new()
	if json.parse(_response_body) != OK:
		_fail("响应不是合法 JSON")
		return
	var payload = json.get_data()
	if payload is not Dictionary:
		_fail("响应格式错误")
		return

	var content: String = ""
	if _use_direct_api:
		# DeepSeek API 格式：{choices: [{message: {content: "..."}}]}
		var choices = payload.get("choices", [])
		if choices is Array and choices.size() > 0:
			var message = choices[0].get("message", {})
			content = message.get("content", "")
	else:
		# 代理格式：{content: "..."}
		content = payload.get("content", "")

	if content.is_empty():
		_fail(payload.get("error", "未返回文本内容"))
		return

	# 保持既有 UI 信号兼容
	stream_token.emit(content)
	stream_completed.emit(content)
	if _current_callback.is_valid():
		_current_callback.call(content)
	var source_label = "DeepSeek" if _use_direct_api else "代理"
	print("[LLMClient] %s 响应完成 (%d chars)" % [source_label, content.length()])


func _fail(message: String) -> void:
	_state = State.DONE
	if _client:
		_client.close()
	stream_failed.emit(message)
	if _current_callback.is_valid():
		_current_callback.call(message)
	printerr("[LLMClient] %s" % message)


func is_api_key_configured() -> bool:
	## 直连模式：检查环境变量是否有密钥
	## 代理模式：检查代理地址是否已配置
	if _use_direct_api:
		return not _api_key.is_empty()
	return not _proxy_host.is_empty() and _proxy_port > 0


func is_busy() -> bool:
	return _state not in [State.IDLE, State.DONE]
