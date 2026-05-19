class_name WaveData
extends Resource
## ウェーブ定義 — 敵のスポーン設定・報酬を保持

class SpawnEntry extends Resource:
	@export var enemy_data: EnemyData
	@export var count: int = 5
	@export var delay_between_spawns: float = 0.8
	@export var spawn_point_indices: Array[int] = [0]
	@export var spawn_delay_from_wave_start: float = 0.0
	@export var formation: SpawnFormation = SpawnFormation.RANDOM

	enum SpawnFormation {
		RANDOM,
		LINE,
		CLUSTER,
		FLANK
	}

@export_group("ウェーブ情報")
@export var wave_number: int = 1
@export var wave_name: String = ""
@export var time_limit: float = 0.0

@export_group("スポーン設定")
@export var spawn_entries: Array[SpawnEntry] = []
@export var boss_entry: SpawnEntry

@export_group("報酬")
@export var reward_build_material: int = 150
@export var reward_gold: int = 100
@export var bonus_material_per_survivor: int = 10

@export_group("環境設定")
@export var is_night_wave: bool = false
@export var weather_effect: WeatherEffect = WeatherEffect.NONE
@export var ambient_darkness: float = 0.0

@export_group("特殊条件")
@export var simultaneous_waves: bool = false
@export var elite_guaranteed: bool = false

enum WeatherEffect {
	NONE,
	RAIN,
	FOG,
	STORM,
	BLIZZARD
}

func get_total_enemy_count() -> int:
	var total := 0
	for entry in spawn_entries:
		total += entry.count
	if boss_entry and boss_entry.enemy_data:
		total += 1
	return total
