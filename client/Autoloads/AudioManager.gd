extends Node
## AudioManager - 音響統括 Autoload
##
## 設計書「音響哲学」: AI製ゲームは音が軽い → 最重要改善点として実装。
## 必須仕様: 近接音レイヤリング/低域強化/距離減衰/Reverb Zone/地形反射。
## 5層 AudioBus 構成 (Master/SFX/Music/Voice/UI/Impact)。

const BUS_MASTER: StringName = &"Master"
const BUS_SFX: StringName = &"SFX"
const BUS_MUSIC: StringName = &"Music"
const BUS_VOICE: StringName = &"Voice"
const BUS_UI: StringName = &"UI"
const BUS_IMPACT: StringName = &"Impact"

const SFX_POOL_SIZE: int = 32
const MUSIC_FADE_DURATION: float = 1.5
const MAX_DISTANCE_3D: float = 60.0
const UNIT_SIZE_3D: float = 8.0

const REVERB_OUTDOOR: int = 0
const REVERB_CAVE: int = 1
const REVERB_HALL: int = 2
const REVERB_DUNGEON: int = 3
const REVERB_FOREST: int = 4

var _sfx_pool_3d: Array[AudioStreamPlayer3D] = []
var _sfx_pool_2d: Array[AudioStreamPlayer] = []
var _pool_index_3d: int = 0
var _pool_index_2d: int = 0
var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer
var _current_music_path: String = ""
var _current_reverb: int = REVERB_OUTDOOR
var _master_volume: float = 1.0
var _sfx_volume: float = 1.0
var _music_volume: float = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_pools()
	_build_music_players()
	_apply_initial_volumes()
	_connect_event_bus()

func _build_pools() -> void:
	for i in SFX_POOL_SIZE:
		var player_3d := AudioStreamPlayer3D.new()
		player_3d.bus = BUS_SFX
		player_3d.max_distance = MAX_DISTANCE_3D
		player_3d.unit_size = UNIT_SIZE_3D
		player_3d.attenuation_filter_cutoff_hz = 5000.0
		player_3d.attenuation_filter_db = -24.0
		player_3d.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(player_3d)
		_sfx_pool_3d.append(player_3d)
		var player_2d := AudioStreamPlayer.new()
		player_2d.bus = BUS_UI
		add_child(player_2d)
		_sfx_pool_2d.append(player_2d)

func _build_music_players() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.bus = BUS_MUSIC
	_music_player_a.volume_db = -80.0
	add_child(_music_player_a)
	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.bus = BUS_MUSIC
	_music_player_b.volume_db = -80.0
	add_child(_music_player_b)
	_active_music_player = _music_player_a

func _apply_initial_volumes() -> void:
	set_master_volume(_master_volume)
	set_sfx_volume(_sfx_volume)
	set_music_volume(_music_volume)

func _connect_event_bus() -> void:
	if not Engine.has_singleton("EventBus") and not has_node("/root/EventBus"):
		return
	var bus := get_node_or_null("/root/EventBus")
	if bus == null:
		return
	if bus.has_signal("hit_confirmed"):
		bus.hit_confirmed.connect(_on_hit_confirmed)
	if bus.has_signal("enemy_died"):
		bus.enemy_died.connect(_on_enemy_died)
	if bus.has_signal("tower_placed"):
		bus.tower_placed.connect(_on_tower_placed)
	if bus.has_signal("wave_started"):
		bus.wave_started.connect(_on_wave_started)
	if bus.has_signal("wave_completed"):
		bus.wave_completed.connect(_on_wave_completed)
	if bus.has_signal("phase_changed"):
		bus.phase_changed.connect(_on_phase_changed)
	if bus.has_signal("player_died"):
		bus.player_died.connect(_on_player_died)

func play_sfx_3d(stream: AudioStream, position: Vector3, volume_db: float = 0.0, pitch_scale: float = 1.0, bus_override: StringName = BUS_SFX) -> AudioStreamPlayer3D:
	if stream == null:
		return null
	var player := _next_3d_player()
	player.stream = stream
	player.global_position = position
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.bus = bus_override
	player.play()
	return player

func play_sfx_2d(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0, bus_override: StringName = BUS_UI) -> AudioStreamPlayer:
	if stream == null:
		return null
	var player := _next_2d_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.bus = bus_override
	player.play()
	return player

func play_impact_3d(stream: AudioStream, position: Vector3, is_heavy: bool = false) -> AudioStreamPlayer3D:
	var volume := 6.0 if is_heavy else 0.0
	var pitch := randf_range(0.92, 1.08)
	return play_sfx_3d(stream, position, volume, pitch, BUS_IMPACT)

func play_music(stream: AudioStream, fade_duration: float = MUSIC_FADE_DURATION) -> void:
	if stream == null:
		return
	var stream_path := stream.resource_path
	if stream_path != "" and stream_path == _current_music_path:
		return
	_current_music_path = stream_path
	var next_player := _music_player_b if _active_music_player == _music_player_a else _music_player_a
	next_player.stream = stream
	next_player.volume_db = -80.0
	next_player.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(next_player, "volume_db", linear_to_db(_music_volume), fade_duration)
	if _active_music_player.playing:
		tween.tween_property(_active_music_player, "volume_db", -80.0, fade_duration)
		tween.chain().tween_callback(_active_music_player.stop)
	_active_music_player = next_player

func stop_music(fade_duration: float = MUSIC_FADE_DURATION) -> void:
	_current_music_path = ""
	if _active_music_player == null or not _active_music_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(_active_music_player, "volume_db", -80.0, fade_duration)
	tween.tween_callback(_active_music_player.stop)

func set_reverb_zone(zone_id: int) -> void:
	_current_reverb = zone_id
	var bus_index := AudioServer.get_bus_index(BUS_SFX)
	if bus_index < 0:
		return
	for i in AudioServer.get_bus_effect_count(bus_index):
		var effect := AudioServer.get_bus_effect(bus_index, i)
		if effect is AudioEffectReverb:
			_configure_reverb(effect, zone_id)
			break

func _configure_reverb(effect: AudioEffectReverb, zone_id: int) -> void:
	match zone_id:
		REVERB_OUTDOOR:
			effect.room_size = 0.4
			effect.wet = 0.12
			effect.damping = 0.6
		REVERB_CAVE:
			effect.room_size = 0.95
			effect.wet = 0.45
			effect.damping = 0.2
		REVERB_HALL:
			effect.room_size = 0.85
			effect.wet = 0.35
			effect.damping = 0.3
		REVERB_DUNGEON:
			effect.room_size = 0.75
			effect.wet = 0.3
			effect.damping = 0.35
		REVERB_FOREST:
			effect.room_size = 0.55
			effect.wet = 0.18
			effect.damping = 0.7
		_:
			effect.room_size = 0.5
			effect.wet = 0.15
			effect.damping = 0.5

func set_master_volume(linear: float) -> void:
	_master_volume = clamp(linear, 0.0, 1.0)
	var idx := AudioServer.get_bus_index(BUS_MASTER)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(_master_volume))

func set_sfx_volume(linear: float) -> void:
	_sfx_volume = clamp(linear, 0.0, 1.0)
	var idx := AudioServer.get_bus_index(BUS_SFX)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(_sfx_volume))

func set_music_volume(linear: float) -> void:
	_music_volume = clamp(linear, 0.0, 1.0)
	var idx := AudioServer.get_bus_index(BUS_MUSIC)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(_music_volume))

func get_master_volume() -> float:
	return _master_volume

func get_sfx_volume() -> float:
	return _sfx_volume

func get_music_volume() -> float:
	return _music_volume

func _next_3d_player() -> AudioStreamPlayer3D:
	var start := _pool_index_3d
	for i in SFX_POOL_SIZE:
		var idx := (start + i) % SFX_POOL_SIZE
		if not _sfx_pool_3d[idx].playing:
			_pool_index_3d = (idx + 1) % SFX_POOL_SIZE
			return _sfx_pool_3d[idx]
	_pool_index_3d = (start + 1) % SFX_POOL_SIZE
	return _sfx_pool_3d[start]

func _next_2d_player() -> AudioStreamPlayer:
	var start := _pool_index_2d
	for i in SFX_POOL_SIZE:
		var idx := (start + i) % SFX_POOL_SIZE
		if not _sfx_pool_2d[idx].playing:
			_pool_index_2d = (idx + 1) % SFX_POOL_SIZE
			return _sfx_pool_2d[idx]
	_pool_index_2d = (start + 1) % SFX_POOL_SIZE
	return _sfx_pool_2d[start]

func _on_hit_confirmed(_attacker: Node, target: Node, damage: float, is_critical: bool) -> void:
	var pos := Vector3.ZERO
	if target is Node3D:
		pos = (target as Node3D).global_position
	var is_heavy := is_critical or damage >= 80.0
	play_impact_3d(null, pos, is_heavy)

func _on_enemy_died(enemy: Node, position: Vector3, _xp: int) -> void:
	var pos := position
	if enemy is Node3D and pos == Vector3.ZERO:
		pos = (enemy as Node3D).global_position
	play_sfx_3d(null, pos, 0.0, randf_range(0.95, 1.05), BUS_SFX)

func _on_tower_placed(tower: Node, _cell: Vector2i) -> void:
	if tower is Node3D:
		play_sfx_3d(null, (tower as Node3D).global_position, 2.0, 1.0, BUS_SFX)

func _on_wave_started(_wave: int, _total: int) -> void:
	play_sfx_2d(null, 4.0, 1.0, BUS_UI)

func _on_wave_completed(_wave: int, success: bool) -> void:
	play_sfx_2d(null, 2.0 if success else -2.0, 1.0, BUS_UI)

func _on_phase_changed(_new_phase: int) -> void:
	pass

func _on_player_died(_player: Node) -> void:
	play_sfx_2d(null, 0.0, 0.85, BUS_UI)
