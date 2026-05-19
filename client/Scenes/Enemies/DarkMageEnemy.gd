class_name DarkMageEnemy
extends EnemyBase
## Dark Mage Enemy — 遠距離魔法攻撃・ミニオン召喚を行う敵

const BOLT_SCENE := "res://Scenes/Projectiles/MageBolt.tscn"
const PREFERRED_DISTANCE: float = 8.0

var _summon_cooldown: float = 15.0
var _summon_timer: float = 5.0

func _ready() -> void:
	super._ready()
	add_to_group(&"enemies_mage")

func _create_ai() -> EnemyAIBase:
	return EnemyAIBase.new()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_summon_timer = maxf(0.0, _summon_timer - delta)
	if _summon_timer <= 0.0 and enemy_data and enemy_data.can_summon_minions:
		_summon_timer = _summon_cooldown
		_do_summon()

func _on_attack_target(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return
	_fire_magic_bolt(target)

func _fire_magic_bolt(target: Node) -> void:
	var scene: PackedScene = load(BOLT_SCENE)
	if scene == null:
		return
	var bolt: Node3D = scene.instantiate()
	get_tree().current_scene.add_child(bolt)
	bolt.global_position = global_position + Vector3.UP * 1.5

	var damage := enemy_data.attack_damage if enemy_data else 20.0
	var dir := (target.global_position - bolt.global_position).normalized()
	if bolt.has_method("initialize"):
		bolt.initialize(dir, damage, self)

func _do_summon() -> void:
	var goblin_scene: PackedScene = load("res://Scenes/Enemies/GoblinScout.tscn")
	if goblin_scene == null:
		return
	for i in 2:
		var angle := (float(i) / 2.0) * TAU
		var offset := Vector3(cos(angle) * 2.0, 0.0, sin(angle) * 2.0)
		var minion: Node3D = goblin_scene.instantiate()
		get_tree().current_scene.add_child(minion)
		minion.global_position = global_position + offset
		EventBus.enemy_spawned.emit(minion)
