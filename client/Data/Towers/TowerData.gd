class_name TowerData
extends Resource
## タワーの設定値・挙動を保持するResourceクラス

@export_group("識別")
@export var tower_id: StringName
@export var display_name: String
@export var description: String
@export var category: TowerCategory
@export var attack_behavior: AttackBehavior = AttackBehavior.NONE

@export_group("コスト")
@export var build_cost: int = 100
@export var upgrade_cost: int = 150
@export var sell_value: int = 70

@export_group("耐久")
@export var max_health: float = 300.0

@export_group("攻撃 (攻撃塔のみ)")
@export var attack_damage: float = 40.0
@export var attack_range: float = 10.0
@export var attack_cooldown: float = 1.5
@export var aoe_radius: float = 0.0
@export var projectile_speed: float = 25.0
@export var piercing: bool = false

@export_group("支援 (支援塔のみ)")
@export var buff_type: StringName = &""
@export var buff_value: float = 0.0
@export var buff_radius: float = 6.0
@export var buff_tick_rate: float = 0.5
@export var heal_per_tick: float = 0.0
@export var mana_restore_per_tick: float = 0.0

@export_group("特殊")
@export var special_effect_id: StringName = &""
@export var special_effect_radius: float = 0.0
@export var slow_multiplier: float = 1.0
@export var pull_force: float = 0.0

@export_group("ビジュアル")
@export var preview_color: Color = Color(0.2, 0.8, 0.2, 0.5)

enum TowerCategory {
	DEFENSE,
	ATTACK,
	SUPPORT,
	SPECIAL
}

enum AttackBehavior {
	NONE,
	PROJECTILE,
	AREA_BURST,
	CONTINUOUS_BEAM,
	TRAP,
	AURA
}
