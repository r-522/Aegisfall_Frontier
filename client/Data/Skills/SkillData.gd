class_name SkillData
extends Resource
## スキルの設定値を保持するResourceクラス

@export_group("識別")
@export var skill_id: StringName
@export var display_name: String
@export var description: String
@export var skill_type: SkillType
@export var target_type: TargetType

@export_group("コスト・クールダウン")
@export var mana_cost: float = 25.0
@export var cooldown: float = 8.0
@export var cast_time: float = 0.0
@export var global_cooldown: float = 0.5

@export_group("効果量")
@export var damage: float = 0.0
@export var heal_amount: float = 0.0
@export var effect_radius: float = 0.0
@export var duration: float = 0.0
@export var knockback_force: float = 0.0
@export var slow_amount: float = 0.0
@export var damage_over_time: float = 0.0
@export var damage_over_time_interval: float = 1.0

@export_group("投射物")
@export var has_projectile: bool = false
@export var projectile_count: int = 1
@export var projectile_speed: float = 20.0
@export var projectile_spread_degrees: float = 0.0

@export_group("バフ効果")
@export var buff_attack_multiplier: float = 1.0
@export var buff_defense_add: float = 0.0
@export var buff_speed_multiplier: float = 1.0
@export var buff_tower_damage_bonus: float = 0.0

@export_group("ビジュアル")
@export var icon: Texture2D
@export var skill_color: Color = Color.WHITE
@export var animation_name: StringName = &"cast"

enum SkillType {
	ACTIVE,
	PASSIVE,
	ULTIMATE,
	TOGGLE
}

enum TargetType {
	SELF,
	ENEMY_SINGLE,
	ENEMY_AOE,
	ALLY_SINGLE,
	ALLY_AOE,
	GROUND,
	DIRECTIONAL,
	NONE
}
