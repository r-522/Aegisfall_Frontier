## クライアント・サーバー共通定数

# ゲームバージョン
const GAME_VERSION: String = "0.1.0-prealpha"
const PROTOCOL_VERSION: int = 1

# コリジョンレイヤー (project.godotと一致)
const LAYER_WORLD: int = 1
const LAYER_PLAYERS: int = 2
const LAYER_ENEMIES: int = 4
const LAYER_TOWERS: int = 8
const LAYER_PROJECTILES: int = 16
const LAYER_HITBOXES: int = 32
const LAYER_DETECTION: int = 64

# アイテムレアリティ
const RARITY_COMMON: StringName = &"common"
const RARITY_UNCOMMON: StringName = &"uncommon"
const RARITY_RARE: StringName = &"rare"
const RARITY_EPIC: StringName = &"epic"
const RARITY_LEGENDARY: StringName = &"legendary"

# ゾーンID
const ZONE_RUINED_PLAINS: StringName = &"ruined_plains"
const ZONE_CURSED_FOREST: StringName = &"cursed_forest"
const ZONE_ANCIENT_AQUEDUCT: StringName = &"ancient_aqueduct"
const ZONE_VOLCANIC_BELT: StringName = &"volcanic_belt"
const ZONE_FROZEN_TUNDRA: StringName = &"frozen_tundra"
const ZONE_SKY_CASTLE: StringName = &"sky_castle_domain"
const ZONE_DEMON_TERRITORY: StringName = &"demon_territory"

# フェーズ同期メッセージ
const MSG_PHASE_CHANGE: int = 100
const MSG_WAVE_START: int = 101
const MSG_WAVE_END: int = 102
const MSG_PLAYER_DIED: int = 200
const MSG_ENEMY_SPAWN: int = 300
const MSG_TOWER_PLACED: int = 400
