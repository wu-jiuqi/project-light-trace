extends SceneTree

const NPC_SCRIPT_PATH := "res://scripts/fragment/npc_controller.gd"
const NPC_IDS := ["oldteacher", "youngsoldier", "flowergirl", "merchant", "littlegirl", "conductor"]
const NPC_SCENES := {
	"oldteacher": "res://scenes/characters/id0002/npc_oldteacher.tscn",
	"youngsoldier": "res://scenes/characters/id0002/npc_youngsoldier.tscn",
	"flowergirl": "res://scenes/characters/id0002/npc_flowergirl.tscn",
	"merchant": "res://scenes/characters/id0002/npc_merchant.tscn",
	"littlegirl": "res://scenes/characters/id0002/npc_littlegirl.tscn",
	"conductor": "res://scenes/characters/id0002/npc_conductor.tscn",
}

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager = root.get_node("FragmentManager")
	var fragment = manager.get_fragment_by_id("0002")
	_check(fragment != null and fragment.implemented, "0002 is implemented")

	await _check_scene("res://scenes/fragments/fragment_0002.tscn", "WorldRoot/Interaction", "res://scenes/rooms/id0002/ticket_check.tscn")
	await _check_scene("res://scenes/rooms/id0002/ticket_check.tscn", "WorldRoot/StationExit", "res://scenes/fragments/fragment_0002.tscn")
	_check_npcs()
	await _check_ticket_check_flow_scene()
	_check_rag()

	if _failures == 0:
		print("[SUMMARY] fragment 0002 smoke test passed")
	quit(_failures)


func _check_scene(scene_path: String, exit_path: String, target_scene: String) -> void:
	var scene_manager = root.get_node("SceneManager")
	scene_manager.pending_spawn_point = ""
	var scene: Node = load(scene_path).instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	_check(scene.has_method("has_player_for_test") and scene.has_player_for_test(), "%s creates a player" % scene_path)
	if scene.has_method("get_player_scale_for_test"):
		_check(scene.get_player_scale_for_test().is_equal_approx(Vector2.ONE), "%s keeps player physics scale unchanged" % scene_path)
	if scene.has_method("get_player_visual_scale_for_test"):
		_check(scene.get_player_visual_scale_for_test().is_equal_approx(Vector2(2.2, 2.2)), "%s scales player visuals to 2.2" % scene_path)
	var spawn := scene.get_node_or_null("WorldRoot/SpawnPoints/Default") as Marker2D
	_check(spawn != null, "%s has Default spawn" % scene_path)
	if spawn != null and scene.has_method("get_player_position_for_test"):
		_check(scene.get_player_position_for_test().distance_to(spawn.global_position) < 0.1, "%s spawns player at Default" % scene_path)
	_check(scene.has_node("UIRoot/DialogueBox"), "%s has DialogueBox under UIRoot" % scene_path)

	var exit_node: Node = scene.get_node_or_null(exit_path)
	_check(exit_node != null and exit_node.is_in_group("interactable"), "%s has an interactable exit" % scene_path)
	if exit_node != null:
		_check(str(exit_node.get("target_scene")) == target_scene, "%s exit targets expected scene" % scene_path)
		_check(str(exit_node.get("target_spawn_point")) == "Default", "%s exit targets Default spawn" % scene_path)
		var scene_fader = root.get_node("SceneFader")
		var emitted := {}
		scene_manager.scene_changing.connect(func(next_scene: String, spawn_point: String) -> void:
			emitted["target_scene"] = next_scene
			emitted["spawn_point"] = spawn_point
		, CONNECT_ONE_SHOT)
		scene_fader.set("_changing", true)
		exit_node.interact()
		_check(scene_manager.pending_spawn_point == "Default", "%s exit interaction sets pending spawn" % scene_path)
		_check(emitted.get("target_scene", "") == target_scene, "%s exit interaction requests expected scene" % scene_path)
		_check(emitted.get("spawn_point", "") == "Default", "%s exit interaction requests Default spawn" % scene_path)
		scene_fader.set("_changing", false)
		scene_manager.pending_spawn_point = ""

	scene.queue_free()
	await process_frame


func _check_npcs() -> void:
	for npc_id in NPC_IDS:
		var npc: Node = load(NPC_SCENES[npc_id]).instantiate()
		_check(npc.get_script() != null and npc.get_script().resource_path == NPC_SCRIPT_PATH, "%s uses npc_controller" % npc_id)
		_check("npc_kb_id" in npc and str(npc.npc_kb_id) == npc_id, "%s has expected kb id" % npc_id)
		if npc_id == "conductor":
			_check("use_rag" in npc and bool(npc.use_rag), "%s keeps RAG enabled" % npc_id)
		else:
			_check("use_rag" in npc and not bool(npc.use_rag), "%s uses monologue instead of RAG" % npc_id)
		npc.queue_free()


func _check_ticket_check_flow_scene() -> void:
	var scene: Node = load("res://scenes/rooms/id0002/ticket_check.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	_check(scene.has_method("uses_alert_system") and not scene.uses_alert_system(), "0002 disables alert system")
	_check(scene.has_method("handle_npc_interaction"), "0002 provides NPC interaction router")
	_check(scene.has_method("handle_npc_player_message"), "0002 provides conductor message interceptor")
	_check(scene.has_node("UIRoot/Monologue"), "ticket check scene has Monologue UI")
	_check(scene.has_node("UIRoot/SeatTable"), "ticket check scene has SeatTable UI")
	_check(scene.has_node("UIRoot/SourceMarkTicketOverlay"), "ticket check scene has source mark ticket overlay")

	var oldteacher := scene.get_node_or_null("WorldRoot/NpcOldteacher")
	_check(oldteacher != null and scene.handle_npc_interaction(oldteacher), "oldteacher interaction is handled by fragment route")
	var monologue := scene.get_node_or_null("UIRoot/Monologue")
	_check(monologue != null and monologue.visible, "oldteacher opens monologue UI")
	if monologue != null and monologue.has_method("close_monologue"):
		monologue.close_monologue()
	await process_frame

	scene.queue_free()
	await process_frame

	var conductor_scene: Node = load("res://scenes/fragments/fragment_0002.tscn").instantiate()
	root.add_child(conductor_scene)
	current_scene = conductor_scene
	await process_frame
	await process_frame
	var conductor := conductor_scene.get_node_or_null("WorldRoot/NpcConductor")
	_check(conductor != null, "fragment 0002 scene has conductor")
	_check(conductor != null and conductor_scene.handle_npc_interaction(conductor), "conductor interaction is handled by fragment route")
	conductor_scene.queue_free()
	await process_frame


func _check_rag() -> void:
	var rag = root.get_node("NPCRagRetriever")
	var state := {
		"fragment_id": "0002",
		"scene_name": "Fragment0002",
		"memory_stage": "initial",
		"alert_level": 0,
		"trust_level": 0,
		"awakened_count": 0,
	}
	for npc_id in ["conductor"]:
		var prompt: String = rag.assemble_prompt(npc_id, "车票在哪里？", state)
		_check(prompt.length() > 0, "%s RAG prompt is non-empty" % npc_id)
		_check(not prompt.contains("## 角色身份\n你是一个NPC。"), "%s RAG prompt uses 0002 identity" % npc_id)
		_check(prompt.contains("## 背景知识"), "%s RAG prompt includes background knowledge" % npc_id)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
