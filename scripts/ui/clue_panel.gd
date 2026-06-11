class_name CluePanel
extends BasePanel

@onready var clue_list: VBoxContainer = $"Stage/MainContainer/ClueListScroll/ClueList"
@onready var detail_overlay: Control = $"DetailOverlay"
@onready var undiscovered_hint: Label = $"Stage/MainContainer/UndiscoveredHint"
@onready var clue_title_label: Label = $"DetailOverlay/DetailContent/ClueTitleLabel"
@onready var clue_description: RichTextLabel = $"DetailOverlay/DetailContent/ClueDescription"
@onready var related_list: HBoxContainer = $"DetailOverlay/DetailContent/RelatedSection/RelatedContainer/RelatedList"
@onready var close_button: Button = $"Stage/MainContainer/TitleBar/CloseButton"
@onready var close_detail_btn: Button = $"DetailOverlay/DetailContent/CloseDetailBtn"

var clues: Array[ClueData] = []


func _on_ready() -> void:
	close_button.pressed.connect(close)
	close_detail_btn.pressed.connect(hide_clue_detail)


func refresh_clues() -> void:
	for child in clue_list.get_children():
		child.queue_free()

	var discovered: Array = clues.filter(func(c: ClueData): return c.is_discovered)
	if discovered.is_empty():
		undiscovered_hint.visible = true
		return

	undiscovered_hint.visible = false
	var ClueCardScene: PackedScene = preload("res://scenes/ui/components/ClueCard.tscn")
	for data: ClueData in clues:
		var card: ClueCard = ClueCardScene.instantiate() as ClueCard
		card.set_clue(data)
		card.pressed.connect(show_clue_detail)
		clue_list.add_child(card)


func show_clue_detail(clue_id: int) -> void:
	for data: ClueData in clues:
		if data.id == clue_id:
			clue_title_label.text = data.name
			clue_description.text = data.description
			# Populate related clues
			for child in related_list.get_children():
				child.queue_free()
			for rid: int in data.related_clue_ids:
				var rdata := _find_clue(rid)
				if rdata:
					var lbl := Label.new()
					lbl.text = rdata.name
					lbl.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
					related_list.add_child(lbl)
			break
	detail_overlay.visible = true


func hide_clue_detail() -> void:
	detail_overlay.visible = false


func _find_clue(id: int) -> ClueData:
	for c: ClueData in clues:
		if c.id == id:
			return c
	return null
