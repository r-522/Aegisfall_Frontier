class_name HealthComponent
extends Node
## 全エンティティ共通のHP管理コンポーネント
## 死亡・被ダメージ・回復をシグナルで上位ノードに通知

signal died()
signal health_changed(new_health: float, max_health: float)
signal damage_taken(amount: float, source: Node)
signal healed(amount: float)
signal health_restored_full()

@export var max_health: float = 100.0
@export var defense: float = 0.0
@export var invincibility_duration: float = 0.0

var current_health: float
var is_dead: bool = false

var _invincibility_timer: float = 0.0

func _ready() -> void:
	current_health = max_health

func _process(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer = maxf(0.0, _invincibility_timer - delta)

func take_damage(raw_amount: float, source: Node = null) -> float:
	if is_dead:
		return 0.0
	if _invincibility_timer > 0.0:
		return 0.0

	var actual := maxf(0.0, raw_amount - defense)
	current_health = clampf(current_health - actual, 0.0, max_health)

	health_changed.emit(current_health, max_health)
	damage_taken.emit(actual, source)

	if current_health <= 0.0:
		_on_died()

	return actual

func take_true_damage(amount: float, source: Node = null) -> float:
	if is_dead:
		return 0.0
	var actual := maxf(0.0, amount)
	current_health = clampf(current_health - actual, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	damage_taken.emit(actual, source)
	if current_health <= 0.0:
		_on_died()
	return actual

func heal(amount: float) -> void:
	if is_dead:
		return
	var prev := current_health
	current_health = clampf(current_health + amount, 0.0, max_health)
	if current_health > prev:
		healed.emit(current_health - prev)
		health_changed.emit(current_health, max_health)
	if current_health >= max_health:
		health_restored_full.emit()

func set_max_health(new_max: float, heal_to_full: bool = false) -> void:
	max_health = new_max
	if heal_to_full:
		current_health = max_health
	else:
		current_health = clampf(current_health, 0.0, max_health)
	health_changed.emit(current_health, max_health)

func apply_invincibility(duration: float) -> void:
	_invincibility_timer = maxf(_invincibility_timer, duration)

func get_health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health

func is_full_health() -> bool:
	return current_health >= max_health

func _on_died() -> void:
	is_dead = true
	died.emit()
