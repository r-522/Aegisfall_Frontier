class_name ArcaneTower
extends TowerBase
## アルカナエネルギーの弾を発射し、爆発AoEとWEAKENEDデバフを付与する魔法タワー

const ARCANE_BLAST_SCENE := "res://Scenes/Projectiles/ArcaneBlast.tscn"

const AOE_RADIUS: float = 2.0
const WEAKEN_CHANCE: float = 0.5
const WEAKEN_DURATION: float = 4.0
const WEAKEN_VALUE: float = 0.3  # 攻撃力-30%

func _ready() -> void:
	add_to_group(&"towers_attack")
	super._ready()

func _on_placed() -> void:
	if animation_player and animation_player.has_animation("idle_arcane"):
		animation_player.play("idle_arcane")

func _spawn_projectile(target: Node, damage: float) -> void:
	if not ResourceLoader.exists(ARCANE_BLAST_SCENE):
		push_warning("ArcaneTower: ArcaneBlast.tscn が見つかりません: " + ARCANE_BLAST_SCENE)
		_apply_aoe_at(target.global_position, damage)
		return

	var blast_res: PackedScene = load(ARCANE_BLAST_SCENE)
	if blast_res == null:
		return

	var blast: Node3D = blast_res.instantiate()
	get_tree().current_scene.add_child(blast)
	blast.global_position = global_position + Vector3.UP * 1.5

	var speed: float = tower_data.projectile_speed if tower_data else 20.0
	if blast.has_method("initialize"):
		blast.initialize(target, damage, speed, AOE_RADIUS)

	# ヒット時のコールバックでWEAKENEDを付与
	if blast.has_signal("hit"):
		blast.hit.connect(_on_blast_hit.bind(damage))

	if animation_player and animation_player.has_animation("cast"):
		animation_player.play("cast")

func _on_blast_hit(hit_position: Vector3, _damage: float) -> void:
	_apply_aoe_at(hit_position, _damage)

func _apply_aoe_at(center: Vector3, damage: float) -> void:
	var enemies := get_tree().get_nodes_in_group(&"enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(center) > AOE_RADIUS:
			continue

		var hc: HealthComponent = enemy.find_child("HealthComponent") as HealthComponent
		if hc and not hc.is_dead:
			hc.take_damage(damage, self)
			EventBus.enemy_took_damage.emit(enemy, damage)

		# 50%の確率でWEAKENEDを付与
		if randf() < WEAKEN_CHANCE:
			var sec: StatusEffectComponent = enemy.find_child("StatusEffectComponent") as StatusEffectComponent
			if sec:
				sec.apply_effect(
					StatusEffectComponent.EFFECT_WEAKENED,
					WEAKEN_DURATION,
					WEAKEN_VALUE
				)
