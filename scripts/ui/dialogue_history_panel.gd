class_name DialogueHistoryPanel
extends BasePanel

@onready var history_scroll: ScrollContainer = $"Stage/DialoguePanel/HistoryScroll"
@onready var history_content: VBoxContainer = $"Stage/DialoguePanel/HistoryScroll/HistoryContent"
@onready var back_button: Button = $"Stage/DialoguePanel/TitleBar/BackButton"

var messages: Array[Dictionary] = []


func _on_ready() -> void:
	back_button.pressed.connect(close)


func add_message(speaker: String, text: String) -> void:
	messages.append({"speaker": speaker, "text": text})
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var speaker_label := Label.new()
	speaker_label.text = speaker
	speaker_label.custom_minimum_size = Vector2(120, 0)
	speaker_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_LABEL)
	speaker_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_LABEL)

	var msg_label := RichTextLabel.new()
	msg_label.bbcode_enabled = true
	msg_label.text = text
	msg_label.fit_content = true
	msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_label.add_theme_color_override("default_color", UIConstants.COLOR_TEXT_PRIMARY)
	msg_label.add_theme_font_size_override("normal_font_size", UIConstants.FONT_SIZE_BODY)

	row.add_child(speaker_label)
	row.add_child(msg_label)
	history_content.add_child(row)


func clear() -> void:
	messages.clear()
	for child in history_content.get_children():
		child.queue_free()


func scroll_to_bottom() -> void:
	await get_tree().process_frame
	history_scroll.scroll_vertical = int(history_scroll.get_v_scroll_bar().max_value)
