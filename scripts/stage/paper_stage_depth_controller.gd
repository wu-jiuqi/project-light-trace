extends Node
class_name PaperStageDepthController
## Scans a flat papercraft stage made of DepthRow_XX nodes and keeps row z-order stable.

@export var stage_rows_path: NodePath = ^"../StageRows"
@export var player_path: NodePath = ^"../../Player"
@export var first_row_base_z: int = 300
@export var row_z_step: int = 100
@export var actor_z_offset: int = 50
@export var occluder_z_offset: int = 80
@export var ground_z_offset: int = -20

var _rows: Array[Node2D] = []
var _row_base_z: Dictionary = {}
var _current_row_number: int = 1
var _player: CanvasItem = null


func _ready() -> void:
	## Initialize row ordering after the scene tree is ready.
	_player = get_node_or_null(player_path) as CanvasItem
	if _player == null:
		push_warning("[PaperStageDepthController] Player not found at %s" % player_path)
	_scan_depth_rows()
	_apply_row_z_indices()
	_connect_row_areas()
	_update_player_z()


func _process(_delta: float) -> void:
	## Keep actor draw order synced even if another system moves the player between rows.
	_update_player_z()


func _scan_depth_rows() -> void:
	## Find every direct child named DepthRow_XX and sort by the parsed row number.
	_rows.clear()
	_row_base_z.clear()
	var stage_rows := get_node_or_null(stage_rows_path)
	if stage_rows == null:
		push_warning("[PaperStageDepthController] StageRows not found at %s" % stage_rows_path)
		return
	for child in stage_rows.get_children():
		if child is Node2D and String(child.name).begins_with("DepthRow_"):
			_rows.append(child)
	_rows.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return _extract_row_number(a.name) < _extract_row_number(b.name)
	)
	for row in _rows:
		var row_number := _extract_row_number(row.name)
		_row_base_z[row_number] = first_row_base_z - ((row_number - 1) * row_z_step)


func _apply_row_z_indices() -> void:
	## Assign each row, visual bucket, ground strip, and occluder a predictable base z-index.
	for row in _rows:
		var row_number := _extract_row_number(row.name)
		var base_z := int(_row_base_z.get(row_number, 0))
		row.z_as_relative = false
		row.z_index = base_z
		var row_visuals := row.get_node_or_null("RowVisuals") as CanvasItem
		if row_visuals:
			row_visuals.z_as_relative = false
			row_visuals.z_index = base_z
		var ground := row.get_node_or_null("RowVisuals/GroundStrips") as CanvasItem
		if ground:
			ground.z_as_relative = false
			ground.z_index = base_z + ground_z_offset
		var occluders := row.get_node_or_null("Occluders") as CanvasItem
		if occluders:
			occluders.z_as_relative = false
			occluders.z_index = base_z + occluder_z_offset


func _connect_row_areas() -> void:
	## Connect WalkZone and Connector areas so the current row can be inferred without changing player movement.
	for row in _rows:
		var row_number := _extract_row_number(row.name)
		var walk_zone := row.get_node_or_null("WalkZone") as Area2D
		if walk_zone:
			walk_zone.body_entered.connect(_on_walk_zone_body_entered.bind(row_number))
		var connectors := row.get_node_or_null("RowConnectors")
		if connectors:
			for child in connectors.get_children():
				if child is Area2D:
					child.body_entered.connect(_on_connector_body_entered.bind(child, row_number))


func _on_walk_zone_body_entered(body: Node, row_number: int) -> void:
	## Update the actor row when the player enters a row walk zone.
	if _player != null and body == _player:
		_current_row_number = row_number
		_update_player_z()


func _on_connector_body_entered(body: Node, connector: Area2D, fallback_row_number: int) -> void:
	## Prefer Connector_To_Row_XX naming for target rows, then fall back to the owning row.
	if _player == null or body != _player:
		return
	var target_row := _extract_connector_target(connector.name)
	_current_row_number = target_row if target_row > 0 else fallback_row_number
	_update_player_z()


func _update_player_z() -> void:
	## Place the player between row visuals and same-row occluders.
	if _player == null:
		return
	var base_z := int(_row_base_z.get(_current_row_number, first_row_base_z))
	_player.z_as_relative = false
	_player.z_index = base_z + actor_z_offset


func _extract_row_number(row_name: StringName) -> int:
	## Parse the numeric suffix from DepthRow_XX; invalid names sort behind the first row.
	var text := String(row_name).trim_prefix("DepthRow_")
	return max(1, text.to_int())


func _extract_connector_target(connector_name: StringName) -> int:
	## Parse Connector_To_Row_XX so connector count and row count can grow freely.
	var text := String(connector_name)
	var prefix := "Connector_To_Row_"
	if not text.begins_with(prefix):
		return -1
	return max(1, text.trim_prefix(prefix).to_int())
