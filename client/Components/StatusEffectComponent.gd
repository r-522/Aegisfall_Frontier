class_name StatusEffectComponent
extends Node
## バフ・デバフ・DoTを時間管理するコンポーネント

signal effect_applied(effect_id: StringName, duration: float, stacks: int)
signal effect_removed(effect_id: StringName)
signal effect_ticked(effect_id: StringName, value: float)

class StatusEffect:
	var effect_id: StringName
	var duration: float
	var max_duration: float
	var stacks: int
	var value: float
	var tick_rate: float
	var tick_timer: float
	var is_permanent: bool

	func _init(id: StringName, dur: float, val: float, tick: float, st: int = 1) -> void:
		effect_id = id
		duration = dur
		max_duration = dur
		value = val
		tick_rate = tick
		tick_timer = tick
		stacks = st
		is_permanent = (dur <= 0.0)

const EFFECT_SLOW := &"slow"
const EFFECT_FROZEN := &"frozen"
const EFFECT_BURN := &"burn"
const EFFECT_POISON := &"poison"
const EFFECT_BLESSED := &"blessed"
const EFFECT_SHIELDED := &"shielded"
const EFFECT_HASTE := &"haste"
const EFFECT_WEAKENED := &"weakened"
const EFFECT_STUNNED := &"stunned"
const EFFECT_GRAVITY_WELL := &"gravity_well"

const MAX_STACKS: int = 5

var _active_effects: Dictionary = {}

func _process(delta: float) -> void:
	var to_remove: Array[StringName] = []

	for effect_id in _active_effects:
		var effect: StatusEffect = _active_effects[effect_id]

		if effect.is_permanent:
			_process_tick(effect, delta)
			continue

		effect.duration -= delta

		if effect.tick_rate > 0.0:
			_process_tick(effect, delta)

		if effect.duration <= 0.0:
			to_remove.append(effect_id)

	for id in to_remove:
		remove_effect(id)

func apply_effect(effect_id: StringName, duration: float, value: float = 0.0, tick_rate: float = 0.0, stacks: int = 1) -> void:
	if _active_effects.has(effect_id):
		var existing: StatusEffect = _active_effects[effect_id]
		existing.duration = maxf(existing.duration, duration)
		existing.stacks = mini(existing.stacks + stacks, MAX_STACKS)
		effect_applied.emit(effect_id, duration, existing.stacks)
		EventBus.status_effect_applied.emit(get_parent(), effect_id, duration)
		return

	var effect := StatusEffect.new(effect_id, duration, value, tick_rate, stacks)
	_active_effects[effect_id] = effect
	effect_applied.emit(effect_id, duration, stacks)
	EventBus.status_effect_applied.emit(get_parent(), effect_id, duration)

func remove_effect(effect_id: StringName) -> void:
	if _active_effects.erase(effect_id):
		effect_removed.emit(effect_id)
		EventBus.status_effect_removed.emit(get_parent(), effect_id)

func has_effect(effect_id: StringName) -> bool:
	return _active_effects.has(effect_id)

func get_effect_stacks(effect_id: StringName) -> int:
	if not _active_effects.has(effect_id):
		return 0
	return _active_effects[effect_id].stacks

func get_effect_remaining(effect_id: StringName) -> float:
	if not _active_effects.has(effect_id):
		return 0.0
	return _active_effects[effect_id].duration

func get_speed_multiplier() -> float:
	var mult := 1.0
	if has_effect(EFFECT_SLOW):
		mult *= 1.0 - (_active_effects[EFFECT_SLOW].value * _active_effects[EFFECT_SLOW].stacks)
	if has_effect(EFFECT_FROZEN):
		mult = 0.0
	if has_effect(EFFECT_STUNNED):
		mult = 0.0
	if has_effect(EFFECT_HASTE):
		mult *= 1.0 + _active_effects[EFFECT_HASTE].value
	return clampf(mult, 0.0, 3.0)

func is_stunned() -> bool:
	return has_effect(EFFECT_STUNNED) or has_effect(EFFECT_FROZEN)

func clear_all_effects() -> void:
	var ids := _active_effects.keys().duplicate()
	for id in ids:
		remove_effect(id)

func _process_tick(effect: StatusEffect, delta: float) -> void:
	if effect.tick_rate <= 0.0:
		return
	effect.tick_timer -= delta
	if effect.tick_timer <= 0.0:
		effect.tick_timer = effect.tick_rate
		effect_ticked.emit(effect.effect_id, effect.value * effect.stacks)
