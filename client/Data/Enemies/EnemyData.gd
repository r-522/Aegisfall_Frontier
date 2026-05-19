class_name EnemyData
extends Resource
## 敵ユニットの統計値・AI設定を保持するResourceクラス

@export_group("識別")
@export var enemy_id: StringName
@export var display_name: String
@export var enemy_type: EnemyType

@export_group("ステータス")
@export var max_health: float = 100.0
@export var defense: float = 0.0
@export var move_speed: float = 3.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 1.5
@export var attack_cooldown: float = 1.5

@export_group("報酬")
@export var xp_reward: int = 10
@export var gold_reward: int = 5
@export var build_material_reward: float = 0.5
@export var loot_weight: float = 1.0

@export_group("AI設定")
@export var target_priority: TargetPriority = TargetPriority.NEAREST
@export var movement_type: MovementType = MovementType.GROUND
@export var detection_range: float = 12.0
@export var can_attack_structures: bool = false
@export var structure_damage_multiplier: float = 1.0
@export var flee_health_threshold: float = 0.0

@export_group("フラグ")
@export var is_elite: bool = false
@export var is_boss: bool = false
@export var can_fly: bool = false
@export var fly_height: float = 3.0
@export var can_summon_minions: bool = false
@export var minion_type_id: StringName = &""
@export var minion_count: int = 3

@export_group("特殊効果")
@export var on_death_effect_id: StringName = &""
@export var on_hit_effect_id: StringName = &""

enum EnemyType {
	SWARM,
	TANK,
	SIEGE,
	FLYING,
	ASSASSIN,
	GOBLIN,
	ORC,
	MAGE,
	BOSS,
	ELITE
}

enum TargetPriority {
	NEAREST,
	TOWER_FIRST,
	PLAYER_FIRST,
	SUPPORT_FIRST,
	STRUCTURE_ONLY
}

enum MovementType {
	GROUND,
	FLYING,
	BURROWING
}
