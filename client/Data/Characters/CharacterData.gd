class_name CharacterData
extends Resource
## キャラクタークラスの全統計値を保持するResourceクラス
## .tres ファイルとして保存し、スクリプトからロード

@export_group("識別")
@export var character_id: StringName
@export var display_name: String
@export var description: String
@export var class_category: ClassCategory

@export_group("基本ステータス")
@export var max_health: float = 200.0
@export var base_defense: float = 10.0
@export var max_mana: float = 100.0
@export var mana_regen_rate: float = 5.0

@export_group("移動")
@export var move_speed: float = 5.5
@export var run_speed: float = 8.0
@export var crouch_speed_multiplier: float = 0.45
@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 1.2
@export var jump_force: float = 7.5

@export_group("攻撃")
@export var base_attack_damage: float = 25.0
@export var base_heavy_attack_damage: float = 55.0
@export var attack_speed: float = 1.5
@export var attack_range: float = 1.8
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0

@export_group("タワー特性")
@export var preferred_tower_category: TowerCategory
@export var tower_build_speed_bonus: float = 0.0
@export var tower_damage_bonus: float = 0.0
@export var tower_health_bonus: float = 0.0

@export_group("スキル")
@export var skills: Array[SkillData] = []

@export_group("アニメーション")
@export var animation_attack_speed_base: float = 1.0

enum ClassCategory {
	MELEE,
	MAGIC,
	SUPPORT,
	AGILE,
	SPECIAL
}

enum TowerCategory {
	NONE,
	DEFENSE,
	ATTACK,
	SUPPORT,
	SPECIAL
}
