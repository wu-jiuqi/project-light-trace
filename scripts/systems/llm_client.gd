extends Node
## LLM 流式客户端 — DeepSeek
## 使用 HTTPClient 实现 SSE 流式输出，逐 token 信号
## 异步状态机实现，不阻塞主线程

const API_HOST = "api.deepseek.com"
const API_PATH = "/v1/chat/completions"
const API_KEY = "sk-3e9efb9d1cd3434cb12705c72d11012e"  # ← 修改这里
const MODEL = "deepseek-v4-flash"
const MAX_TOKENS = 512
const TEMPERATURE = 0.8
const USE_SSL = true
const PORT = 443

# 连接状态
enum State {
	IDLE,         # 空闲
	CONNECTING,   # 正在连接
	REQUESTING,   # 已连接，正在发送请求
	STREAMING,    # 流式接收中
	DONE          # 完成或失败
}

signal stream_token(token: String)
signal stream_completed(full_text: String)
signal stream_failed(error: String)

var _client: HTTPClient
var _state: int = State.IDLE
var _connected: bool = false
var _accumulated_text: String = ""
var _line_buffer: String = ""
var _current_callback: Callable

# 待发送的请求数据（用于异步发送）
var _pending_request: Dictionary = {}
var _connection_attempt_time: float = 0.0
const CONNECTION_TIMEOUT: float = 15.0  # 连接超时（秒）


func _ready() -> void:
	_client = HTTPClient.new()
	print("[LLMClient] 流式客户端就绪 (model=%s)" % MODEL)


func _process(_delta: float) -> void:
	if _state == State.IDLE or _state == State.DONE:
		return
	
	# 连接超时检测
	if _state == State.CONNECTING:
		if Time.get_ticks_msec() / 1000.0 - _connection_attempt_time > CONNECTION_TIMEOUT:
			_state = State.DONE
			_client.close()
			var msg = "连接超时 (%.0fs)" % CONNECTION_TIMEOUT
			stream_failed.emit(msg)
			if _current_callback.is_valid(): _current_callback.call(msg)
			print("[LLMClient] %s" % msg)
			return
	
	_poll_stream()


func chat_stream(system_prompt: String, user_message: String, callback: Callable = Callable()) -> void:
	if _state != State.IDLE and _state != State.DONE:
		printerr("[LLMClient] 已有流式请求在进行中")
		return
	
	if API_KEY == "" or API_KEY.begins_with("sk-your-"):
		var err = "API Key未配置"
		stream_failed.emit(err)
		if callback.is_valid(): callback.call(err)
		return
	
	_current_callback = callback
	_accumulated_text = ""
	_line_buffer = ""
	
	# 构建请求体
	var messages = [
		{"role": "system", "content": system_prompt},
		{"role": "user", "content": user_message}
	]
	
	var body = {
		"model": MODEL,
		"messages": messages,
		"max_tokens": MAX_TOKENS,
		"temperature": TEMPERATURE,
		"stream": true
	}
	
	_pending_request = {
		"body": JSON.stringify(body),
		"headers": [
			"Content-Type: application/json",
			"Authorization: Bearer %s" % API_KEY,
			"Accept: text/event-stream"
		]
	}
	
	print("[LLMClient] 发起连接 → %s:%d (prompt=%d chars, input=\"%s\")" % 
		[API_HOST, PORT, system_prompt.length(), user_message.left(50)])
	
	# 异步连接 —— 不在主线程阻塞等待
	var err = _client.connect_to_host(API_HOST, PORT, TLSOptions.client())
	if err != OK:
		_state = State.DONE
		var msg = "连接发起失败: %d" % err
		stream_failed.emit(msg)
		if _current_callback.is_valid(): _current_callback.call(msg)
		print("[LLMClient] %s" % msg)
		return
	
	_state = State.CONNECTING
	_connection_attempt_time = Time.get_ticks_msec() / 1000.0


func _poll_stream() -> void:
	_client.poll()
	var status = _client.get_status()
	
	match _state:
		State.CONNECTING:
			match status:
				HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING:
					return  # 继续等待
				HTTPClient.STATUS_CONNECTED:
					# 连接成功 → 发送请求
					var req = _pending_request
					var req_err = _client.request(
						HTTPClient.METHOD_POST, API_PATH,
						req["headers"], req["body"]
					)
					if req_err != OK:
						_state = State.DONE
						_client.close()
						var msg = "请求发送失败: %d" % req_err
						stream_failed.emit(msg)
						if _current_callback.is_valid(): _current_callback.call(msg)
						print("[LLMClient] %s" % msg)
						return
					_state = State.REQUESTING
					print("[LLMClient] 已连接，请求已发送，等待响应...")
					return
				_:
					# 连接失败
					_state = State.DONE
					_client.close()
					var msg = "连接失败: status=%d" % status
					stream_failed.emit(msg)
					if _current_callback.is_valid(): _current_callback.call(msg)
					print("[LLMClient] %s" % msg)
		
		State.REQUESTING:
			match status:
				HTTPClient.STATUS_REQUESTING:
					return  # 继续等待
				HTTPClient.STATUS_BODY:
					if _client.has_response():
						# 检查 HTTP 状态码
						var resp_code = _client.get_response_code()
						if resp_code != 200:
							# 读取错误响应体
							var err_body = ""
							while _client.get_status() == HTTPClient.STATUS_BODY:
								_client.poll()
								var chunk = _client.read_response_body_chunk()
								if chunk.size() == 0:
									break
								err_body += chunk.get_string_from_utf8()
							_state = State.DONE
							_client.close()
							var msg = "HTTP %d: %s" % [resp_code, err_body.left(200)]
							stream_failed.emit(msg)
							if _current_callback.is_valid(): _current_callback.call(msg)
							print("[LLMClient] %s" % msg)
							return
						print("[LLMClient] HTTP 200, 开始接收流式响应...")
						_state = State.STREAMING
						_read_response_chunk()
					return
				HTTPClient.STATUS_CONNECTED:
					return  # 等待服务器处理
				_:
					_state = State.DONE
					_client.close()
					var msg = "请求异常: status=%d (HTTPClient.STATUS_*)" % status
					stream_failed.emit(msg)
					if _current_callback.is_valid(): _current_callback.call(msg)
					print("[LLMClient] %s" % msg)
		
		State.STREAMING:
			match status:
				HTTPClient.STATUS_BODY:
					_read_response_chunk()
					return
				HTTPClient.STATUS_DISCONNECTED:
					_finish_stream()
					return
				_:
					# 意外状态
					if status != HTTPClient.STATUS_RESOLVING and status != HTTPClient.STATUS_CONNECTING and status != HTTPClient.STATUS_REQUESTING:
						var msg = "流式中断: status=%d (已接收%d chars)" % [status, _accumulated_text.length()]
						printerr("[LLMClient] %s" % msg)
						if _accumulated_text.length() > 0:
							# 部分数据已收到，视为完成
							_finish_stream()
						else:
							_state = State.DONE
							_client.close()
							stream_failed.emit(msg)
							if _current_callback.is_valid(): _current_callback.call(msg)


func _read_response_chunk() -> void:
	var chunk = _client.read_response_body_chunk()
	if chunk.size() == 0:
		return
	
	var text = chunk.get_string_from_utf8()
	_line_buffer += text
	
	# 解析 SSE 行
	while true:
		var newline_idx = _line_buffer.find("\n")
		if newline_idx == -1:
			break
		
		var line = _line_buffer.substr(0, newline_idx).strip_edges()
		_line_buffer = _line_buffer.substr(newline_idx + 1)
		
		if line == "":
			continue
		
		if line.begins_with("data: "):
			var data = line.substr(6)
			if data == "[DONE]":
				_finish_stream()
				return
			
			var json = JSON.new()
			var err = json.parse(data)
			if err == OK:
				var result = json.get_data()
				var choices = result.get("choices", [])
				if choices.size() > 0:
					var delta = choices[0].get("delta", {})
					if delta == null:
						continue
					var content_raw = delta.get("content", "")
					# 防御：content 可能是 null（无文本的 delta，如 role/finish_reason）
					if content_raw is String and content_raw != "":
						_accumulated_text += content_raw
						stream_token.emit(content_raw)


func _finish_stream() -> void:
	_state = State.DONE
	_client.close()
	print("[LLMClient] 流式完成 (%d chars)" % _accumulated_text.length())
	stream_completed.emit(_accumulated_text)
	if _current_callback.is_valid():
		_current_callback.call(_accumulated_text)


func is_api_key_configured() -> bool:
	return API_KEY != "" and not API_KEY.begins_with("sk-your-")


func is_busy() -> bool:
	return _state != State.IDLE and _state != State.DONE
