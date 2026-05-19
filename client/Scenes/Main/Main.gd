class_name Main
extends Node
## ゲームのルートシーン — フェーズ管理・プレイヤー生成・システム初期化

@onready var phase_manager: PhaseManager = $Systems/PhaseManager
@onready var wave_system: WaveSystem = $Systems/WaveSystem
@onready var spawn_system: SpawnSystem = $Systems/SpawnSystem
@onready var build_system: BuildSystem = $Systems/BuildSystem
@onready var resource_system: ResourceSystem = $Systems/ResourceSystem
@onready var loot_system: LootSystem = $Systems/LootSystem
@onready var save_system: SaveSystem = $Systems/SaveSystem
@onready var field_event_manager: FieldEventManager = $Systems/FieldEventManager
@onready var hud: CanvasLayer = $HUD
@onready var players_container: Node3D = $PlayersContainer
@onready var world: Node3D = $World

const FIGHTER_SCENE := preload("res://Scenes/Characters/Fighter.tscn")
const MAGE_SCENE := preload("res://Scenes/Characters/Mage.tscn")
const RANGER_SCENE := preload("res://Scenes/Characters/Ranger.tscn")
const CLERIC_SCENE := preload("res://Scenes/Characters/Cleric.tscn")

var _local_player: PlayerBase = null
var _all_players: Dictionary = {}

func _ready() -> void:
	_connect_network_events()
	_connect_event_bus()

	if not multiplayer.has_multiplayer_peer():
		_start_single_player()
	else:
		_setup_multiplayer_session()

func _connect_network_events() -> void:
	var net := get_node_or_null("../NetworkManager")
	if net:
		net.player_joined.connect(_on_remote_player_joined)
		net.player_left.connect(_on_remote_player_left)

func _connect_event_bus() -> void:
	EventBus.session_started.connect(_on_session_started)
	EventBus.session_ended.connect(_on_session_ended)
	EventBus.phase_changed.connect(_on_phase_changed)

func _start_single_player() -> void:
	var player := _spawn_player(1, &"fighter")
	_local_player = player
	if hud and hud.has_method("set_local_player_id"):
		hud.set_local_player_id(1)
	if hud and hud.has_method("set_phase_manager"):
		hud.set_phase_manager(phase_manager)
	EventBus.session_started.emit()

func _setup_multiplayer_session() -> void:
	var my_id := multiplayer.get_unique_id()
	var player := _spawn_player(my_id, &"fighter")
	_local_player = player
	if hud and hud.has_method("set_local_player_id"):
		hud.set_local_player_id(my_id)
	EventBus.session_started.emit()

func _spawn_player(peer_id: int, class_id: StringName) -> PlayerBase:
	var scene: PackedScene = _get_class_scene(class_id)
	var player: PlayerBase = scene.instantiate()
	player.player_id = peer_id
	player.name = "Player_%d" % peer_id
	players_container.add_child(player)

	var spawn_pos := _get_spawn_position()
	player.global_position = spawn_pos

	_all_players[peer_id] = player
	_connect_player_to_hud(player)

	return player

func _get_class_scene(class_id: StringName) -> PackedScene:
	match class_id:
		&"fighter": return FIGHTER_SCENE
		&"mage": return MAGE_SCENE
		&"ranger": return RANGER_SCENE
		&"cleric": return CLERIC_SCENE
		_: return FIGHTER_SCENE

func _get_spawn_position() -> Vector3:
	var spawn_points := get_tree().get_nodes_in_group(&"spawn_point_player")
	if spawn_points.is_empty():
		return Vector3(0.0, 1.0, 0.0)
	return spawn_points[randi() % spawn_points.size()].global_position

func _connect_player_to_hud(player: PlayerBase) -> void:
	if hud == null:
		return
	if not player.is_local_player:
		return
	player.health_component.health_changed.connect(hud.update_health)
	player.mana_component.mana_changed.connect(hud.update_mana)

func _on_remote_player_joined(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var player := _spawn_player(peer_id, &"fighter")
	player.is_local_player = false

func _on_remote_player_left(peer_id: int) -> void:
	if _all_players.has(peer_id):
		var player: Node = _all_players[peer_id]
		_all_players.erase(peer_id)
		if is_instance_valid(player):
			player.queue_free()

func _on_session_started() -> void:
	phase_manager.transition_to(PhaseManager.Phase.EXPLORATION)

func _on_session_ended(victory: bool, score: int) -> void:
	print("Session ended — Victory: %s, Score: %d" % [victory, score])

func _on_phase_changed(new_phase: int) -> void:
	match new_phase as PhaseManager.Phase:
		PhaseManager.Phase.BUILD:
			if build_system:
				build_system.enable_build_mode()
		PhaseManager.Phase.WAVE_DEFENSE:
			if build_system:
				build_system.disable_build_mode()

func _process(_delta: float) -> void:
	if InputMapper.is_pause_just_pressed():
		_toggle_pause()

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	InputMapper.release_mouse() if get_tree().paused else InputMapper.capture_mouse()
