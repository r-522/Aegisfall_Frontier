class_name ManaComponent
extends Node
## MP/エナジー管理コンポーネント

signal mana_changed(new_mana: float, max_mana: float)
signal mana_depleted()
signal mana_restored_full()

@export var max_mana: float = 100.0
@export var regen_rate: float = 5.0
@export var regen_delay_after_spend: float = 2.0

var current_mana: float
var _regen_delay_timer: float = 0.0

func _ready() -> void:
	current_mana = max_mana

func _process(delta: float) -> void:
	if _regen_delay_timer > 0.0:
		_regen_delay_timer -= delta
		return
	if current_mana < max_mana and regen_rate > 0.0:
		restore(regen_rate * delta)

func spend(amount: float) -> bool:
	if current_mana < amount:
		return false
	current_mana = clampf(current_mana - amount, 0.0, max_mana)
	_regen_delay_timer = regen_delay_after_spend
	mana_changed.emit(current_mana, max_mana)
	if current_mana <= 0.0:
		mana_depleted.emit()
	return true

func restore(amount: float) -> void:
	var prev := current_mana
	current_mana = clampf(current_mana + amount, 0.0, max_mana)
	if current_mana != prev:
		mana_changed.emit(current_mana, max_mana)
	if current_mana >= max_mana and prev < max_mana:
		mana_restored_full.emit()

func has_mana(amount: float) -> bool:
	return current_mana >= amount

func get_mana_ratio() -> float:
	if max_mana <= 0.0:
		return 0.0
	return current_mana / max_mana

func set_max_mana(new_max: float, restore_to_full: bool = false) -> void:
	max_mana = new_max
	if restore_to_full:
		current_mana = max_mana
	else:
		current_mana = clampf(current_mana, 0.0, max_mana)
	mana_changed.emit(current_mana, max_mana)
