class_name SkillComponent
extends Node
## スキル管理コンポーネント — クールダウン・MP消費・発動を一元管理

signal skill_used(skill_index: int, skill_data: SkillData)
signal skill_ready(skill_index: int)
signal skill_failed(skill_index: int, reason: StringName)
signal all_skills_on_cooldown()

const REASON_ON_COOLDOWN := &"on_cooldown"
const REASON_NO_MANA := &"no_mana"
const REASON_CASTING := &"casting"
const REASON_DEAD := &"dead"
const REASON_INVALID := &"invalid_slot"

@export var skills: Array[SkillData] = []

var _cooldown_timers: Array[float] = []
var _global_cooldown_timer: float = 0.0
var _is_casting: bool = false
var _cast_timer: float = 0.0
var _pending_skill_index: int = -1

func _ready() -> void:
	_cooldown_timers.resize(skills.size())
	_cooldown_timers.fill(0.0)

func _process(delta: float) -> void:
	_global_cooldown_timer = maxf(0.0, _global_cooldown_timer - delta)

	if _is_casting:
		_cast_timer -= delta
		if _cast_timer <= 0.0:
			_is_casting = false
			_execute_pending_skill()

	for i in _cooldown_timers.size():
		if _cooldown_timers[i] > 0.0:
			_cooldown_timers[i] = maxf(0.0, _cooldown_timers[i] - delta)
			if _cooldown_timers[i] == 0.0:
				skill_ready.emit(i)

func try_use_skill(index: int, mana_comp: ManaComponent) -> bool:
	if index < 0 or index >= skills.size():
		skill_failed.emit(index, REASON_INVALID)
		return false

	var skill: SkillData = skills[index]
	if skill == null:
		skill_failed.emit(index, REASON_INVALID)
		return false

	if _cooldown_timers[index] > 0.0:
		skill_failed.emit(index, REASON_ON_COOLDOWN)
		return false

	if _global_cooldown_timer > 0.0 and skill.skill_type != SkillData.SkillType.ULTIMATE:
		skill_failed.emit(index, REASON_ON_COOLDOWN)
		return false

	if mana_comp != null and not mana_comp.has_mana(skill.mana_cost):
		skill_failed.emit(index, REASON_NO_MANA)
		return false

	if mana_comp != null:
		mana_comp.spend(skill.mana_cost)

	_cooldown_timers[index] = skill.cooldown
	_global_cooldown_timer = skill.global_cooldown

	if skill.cast_time > 0.0:
		_is_casting = true
		_cast_timer = skill.cast_time
		_pending_skill_index = index
	else:
		skill_used.emit(index, skill)

	return true

func force_use_skill(index: int) -> void:
	if index < 0 or index >= skills.size():
		return
	var skill: SkillData = skills[index]
	if skill == null:
		return
	_cooldown_timers[index] = skill.cooldown
	skill_used.emit(index, skill)

func reset_cooldown(index: int) -> void:
	if index < 0 or index >= _cooldown_timers.size():
		return
	_cooldown_timers[index] = 0.0

func reset_all_cooldowns() -> void:
	_cooldown_timers.fill(0.0)

func interrupt_cast() -> void:
	if _is_casting:
		_is_casting = false
		_pending_skill_index = -1

func get_cooldown_ratio(index: int) -> float:
	if index < 0 or index >= skills.size() or skills[index] == null:
		return 0.0
	if skills[index].cooldown <= 0.0:
		return 0.0
	return _cooldown_timers[index] / skills[index].cooldown

func get_remaining_cooldown(index: int) -> float:
	if index < 0 or index >= _cooldown_timers.size():
		return 0.0
	return _cooldown_timers[index]

func is_on_cooldown(index: int) -> bool:
	if index < 0 or index >= _cooldown_timers.size():
		return false
	return _cooldown_timers[index] > 0.0

func _execute_pending_skill() -> void:
	if _pending_skill_index < 0 or _pending_skill_index >= skills.size():
		return
	skill_used.emit(_pending_skill_index, skills[_pending_skill_index])
	_pending_skill_index = -1
