class_name AffixData
extends Resource
## アイテムアフィックス — ハクスラ的なランダム属性 (Diablo/PoE風)

enum AffixType {
	DAMAGE_FLAT,
	DAMAGE_PERCENT,
	ARMOR_FLAT,
	ARMOR_PERCENT,
	HEALTH_FLAT,
	HEALTH_PERCENT,
	MANA_FLAT,
	MANA_REGEN,
	CRIT_CHANCE,
	CRIT_MULTIPLIER,
	ATTACK_SPEED,
	MOVE_SPEED,
	LIFESTEAL,
	ELEMENTAL_DAMAGE,
	COOLDOWN_REDUCTION,
	TOWER_DAMAGE,
	TOWER_RANGE,
}

@export var affix_id: StringName
@export var display_name: String
@export var affix_type: AffixType = AffixType.DAMAGE_FLAT
@export var value: float = 0.0
@export var element: int = 0  ## ItemData.Element の値 (循環依存回避のため int)
@export var tier: int = 1

func affects_damage() -> bool:
	return affix_type == AffixType.DAMAGE_FLAT or affix_type == AffixType.DAMAGE_PERCENT or affix_type == AffixType.ELEMENTAL_DAMAGE

func affects_armor() -> bool:
	return affix_type == AffixType.ARMOR_FLAT or affix_type == AffixType.ARMOR_PERCENT

func get_display_text() -> String:
	match affix_type:
		AffixType.DAMAGE_FLAT: return "+%d ダメージ" % int(value)
		AffixType.DAMAGE_PERCENT: return "+%d%% ダメージ" % int(value)
		AffixType.ARMOR_FLAT: return "+%d 防御" % int(value)
		AffixType.ARMOR_PERCENT: return "+%d%% 防御" % int(value)
		AffixType.HEALTH_FLAT: return "+%d 最大HP" % int(value)
		AffixType.HEALTH_PERCENT: return "+%d%% 最大HP" % int(value)
		AffixType.MANA_FLAT: return "+%d 最大MP" % int(value)
		AffixType.MANA_REGEN: return "+%.1f MP再生/秒" % value
		AffixType.CRIT_CHANCE: return "+%d%% クリ率" % int(value)
		AffixType.CRIT_MULTIPLIER: return "+%d%% クリダメ" % int(value)
		AffixType.ATTACK_SPEED: return "+%d%% 攻撃速度" % int(value)
		AffixType.MOVE_SPEED: return "+%d%% 移動速度" % int(value)
		AffixType.LIFESTEAL: return "%d%% ライフスティール" % int(value)
		AffixType.ELEMENTAL_DAMAGE: return "+%d 属性ダメージ" % int(value)
		AffixType.COOLDOWN_REDUCTION: return "-%d%% CD" % int(value)
		AffixType.TOWER_DAMAGE: return "+%d%% タワーダメージ" % int(value)
		AffixType.TOWER_RANGE: return "+%d%% タワー射程" % int(value)
		_: return display_name
