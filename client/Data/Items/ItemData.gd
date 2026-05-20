class_name ItemData
extends Resource
## アイテム定義 — Rarity / Affix / Element の組合せで装備を表現
## 設計書 10. データベース設計 の Item: UUID/Rarity/Affix/Element に対応

enum ItemCategory {
	WEAPON_MELEE,
	WEAPON_RANGED,
	WEAPON_MAGIC,
	ARMOR_HEAD,
	ARMOR_CHEST,
	ARMOR_HANDS,
	ARMOR_LEGS,
	ARMOR_FEET,
	ACCESSORY,
	CONSUMABLE,
	MATERIAL,
	BUILD_MATERIAL,
	GOLD,
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	MYTHIC,
}

enum Element {
	NONE,
	FIRE,
	ICE,
	LIGHTNING,
	HOLY,
	SHADOW,
	NATURE,
	ARCANE,
}

@export_group("識別")
@export var item_id: StringName
@export var display_name: String
@export var description: String = ""
@export var item_uuid: String = ""

@export_group("分類")
@export var category: ItemCategory = ItemCategory.MATERIAL
@export var rarity: Rarity = Rarity.COMMON
@export var element: Element = Element.NONE

@export_group("基本ステータス")
@export var base_damage: float = 0.0
@export var base_armor: float = 0.0
@export var base_health_bonus: float = 0.0
@export var base_mana_bonus: float = 0.0

@export_group("アフィックス")
@export var affixes: Array[AffixData] = []
@export var max_affixes: int = 4

@export_group("経済")
@export var stack_size: int = 1
@export var sell_price: int = 10
@export var quantity: int = 1

@export_group("見た目")
@export var icon: Texture2D
@export var model_path: String = ""

func _init() -> void:
	if item_uuid == "":
		item_uuid = _generate_uuid()

func _generate_uuid() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return "%08x-%04x-%04x" % [rng.randi(), rng.randi() & 0xFFFF, rng.randi() & 0xFFFF]

func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON: return Color(0.85, 0.85, 0.85)
		Rarity.UNCOMMON: return Color(0.4, 0.9, 0.4)
		Rarity.RARE: return Color(0.4, 0.6, 1.0)
		Rarity.EPIC: return Color(0.7, 0.4, 1.0)
		Rarity.LEGENDARY: return Color(1.0, 0.65, 0.0)
		Rarity.MYTHIC: return Color(1.0, 0.2, 0.4)
		_: return Color.WHITE

func get_total_damage() -> float:
	var total := base_damage
	for affix in affixes:
		if affix and affix.affects_damage():
			total += affix.value
	return total

func get_total_armor() -> float:
	var total := base_armor
	for affix in affixes:
		if affix and affix.affects_armor():
			total += affix.value
	return total
