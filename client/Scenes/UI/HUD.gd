class_name HUD
extends CanvasLayer
## ゲーム中HUD — EventBusシグナルで更新、プレイヤー直接参照なし

@onready var health_bar: ProgressBar = $HealthBar
@onready var mana_bar: ProgressBar = $ManaBar
@onready var wave_label: Label = $WaveInfo/WaveLabel
@onready var phase_label: Label = $PhaseInfo/PhaseLabel
@onready var resource_label: Label = $ResourcePanel/MaterialLabel
@onready var gold_label: Label = $ResourcePanel/GoldLabel
@onready var skill_container: HBoxContainer = $SkillBar
@onready var enemy_count_label: Label = $WaveInfo/EnemyCountLabel
@onready var fps_label: Label = $DebugPanel/FPSLabel
@onready var phase_timer_bar: ProgressBar = $PhaseInfo/PhaseTimerBar

var _local_player_id: int = 1
var _phase_manager: PhaseManager

func _ready() -> void:
	_connect_event_bus()

func _process(_delta: float) -> void:
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	if _phase_manager:
		phase_timer_bar.value = _phase_manager.get_phase_timer_ratio()

func set_local_player_id(id: int) -> void:
	_local_player_id = id

func set_phase_manager(pm: PhaseManager) -> void:
	_phase_manager = pm

func _connect_event_bus() -> void:
	EventBus.player_took_damage.connect(_on_player_took_damage)
	EventBus.player_healed.connect(_on_player_healed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.resources_changed.connect(_on_resources_changed)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.player_level_up.connect(_on_player_level_up)

func update_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

func update_mana(current: float, maximum: float) -> void:
	mana_bar.max_value = maximum
	mana_bar.value = current

func update_skill_cooldown(slot: int, ratio: float) -> void:
	# Ratio 0=ready, 1=full cooldown
	var slots := skill_container.get_children()
	if slot < slots.size():
		var slot_node := slots[slot]
		if slot_node.has_method("set_cooldown_ratio"):
			slot_node.set_cooldown_ratio(ratio)

func _on_player_took_damage(player_id: int, amount: float, _source: Node) -> void:
	if player_id != _local_player_id:
		return
	health_bar.modulate = Color(1.5, 0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(health_bar, "modulate", Color.WHITE, 0.5)

func _on_player_healed(player_id: int, _amount: float) -> void:
	if player_id != _local_player_id:
		return
	health_bar.modulate = Color(0.3, 1.5, 0.3)
	var tween := create_tween()
	tween.tween_property(health_bar, "modulate", Color.WHITE, 0.5)

func _on_wave_started(wave_number: int, total_enemies: int) -> void:
	wave_label.text = "Wave %d" % wave_number
	enemy_count_label.text = "Enemies: %d" % total_enemies

func _on_wave_completed(wave_number: int, _success: bool) -> void:
	wave_label.text = "Wave %d — CLEAR!" % wave_number

func _on_resources_changed(build_material: int, gold: int) -> void:
	resource_label.text = "[Mat] %d" % build_material
	gold_label.text = "[G] %d" % gold

func _on_phase_changed(new_phase: int) -> void:
	var phase_names := ["Lobby", "Exploration", "Build", "Wave Defense", "Counter Attack", "Results"]
	phase_label.text = phase_names[new_phase] if new_phase < phase_names.size() else "Unknown"

func _on_enemy_died(_enemy: Node, _pos: Vector3, _xp: int) -> void:
	# Flash enemy count indicator on kill
	enemy_count_label.modulate = Color(1.5, 1.0, 0.3)
	var tween := create_tween()
	tween.tween_property(enemy_count_label, "modulate", Color.WHITE, 0.3)

func _on_player_level_up(player_id: int, new_level: int) -> void:
	if player_id != _local_player_id:
		return
	var previous_text: String = wave_label.text
	wave_label.text = "LEVEL UP! Lv.%d" % new_level
	wave_label.modulate = Color(1.0, 0.9, 0.2)
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(func() -> void:
		wave_label.text = previous_text
		wave_label.modulate = Color.WHITE
	)
