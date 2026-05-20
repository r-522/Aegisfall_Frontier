class_name InventoryComponent
extends Node
## インベントリ管理 — アイテム所持・装備・スタックを担当
## 装備変更時に equipment_changed シグナルでステータス再計算を要求

signal item_added(item: Resource, slot_index: int)
signal item_removed(item: Resource, slot_index: int)
signal item_equipped(item: Resource, category: int)
signal item_unequipped(item: Resource, category: int)
signal inventory_changed
signal equipment_changed

const MAX_INVENTORY_SLOTS: int = 60

var items: Array = []
var equipped: Dictionary = {}
var gold: int = 0

func _ready() -> void:
	items.resize(MAX_INVENTORY_SLOTS)

func add_item(item: Resource) -> bool:
	if item == null:
		return false
	var item_data = item as Object
	if item_data.get("category") != null:
		var cat = item_data.get("category")
		if cat == 12:  ## ItemData.ItemCategory.GOLD
			gold += item_data.get("quantity") if item_data.get("quantity") != null else 1
			EventBus.gold_changed.emit(gold)
			return true
		if item_data.get("stack_size") != null and item_data.get("stack_size") > 1:
			for i in items.size():
				var existing = items[i]
				if existing == null:
					continue
				var e_id = existing.get("item_id") if existing != null else null
				var s_id = item_data.get("item_id")
				if e_id == s_id and existing.get("quantity") < existing.get("stack_size"):
					var room: int = existing.get("stack_size") - existing.get("quantity")
					var add_amount: int = min(room, item_data.get("quantity"))
					existing.set("quantity", existing.get("quantity") + add_amount)
					item_data.set("quantity", item_data.get("quantity") - add_amount)
					inventory_changed.emit()
					if item_data.get("quantity") <= 0:
						return true
	var slot := _find_empty_slot()
	if slot < 0:
		return false
	items[slot] = item
	item_added.emit(item, slot)
	inventory_changed.emit()
	return true

func remove_item(slot_index: int) -> Resource:
	if slot_index < 0 or slot_index >= items.size():
		return null
	var item = items[slot_index]
	if item == null:
		return null
	items[slot_index] = null
	item_removed.emit(item, slot_index)
	inventory_changed.emit()
	return item

func equip(slot_index: int) -> bool:
	var item = items[slot_index] if slot_index < items.size() else null
	if item == null or not _is_equippable(item):
		return false
	var category = item.get("category")
	if equipped.has(category):
		var previous = equipped[category]
		add_item(previous)
		item_unequipped.emit(previous, category)
	equipped[category] = item
	items[slot_index] = null
	item_equipped.emit(item, category)
	equipment_changed.emit()
	inventory_changed.emit()
	return true

func unequip(category: int) -> bool:
	if not equipped.has(category):
		return false
	var item = equipped[category]
	equipped.erase(category)
	if not add_item(item):
		equipped[category] = item
		return false
	item_unequipped.emit(item, category)
	equipment_changed.emit()
	return true

func get_equipped(category: int) -> Resource:
	return equipped.get(category, null)

func get_total_damage_bonus() -> float:
	var total := 0.0
	for category in equipped:
		var item = equipped[category]
		if item and item.has_method("get_total_damage"):
			total += item.call("get_total_damage")
	return total

func get_total_armor_bonus() -> float:
	var total := 0.0
	for category in equipped:
		var item = equipped[category]
		if item and item.has_method("get_total_armor"):
			total += item.call("get_total_armor")
	return total

func get_total_health_bonus() -> float:
	var total := 0.0
	for category in equipped:
		var item = equipped[category]
		if item == null:
			continue
		var hp = item.get("base_health_bonus")
		if hp != null:
			total += hp
		var affixes = item.get("affixes")
		if affixes == null:
			continue
		for affix in affixes:
			if affix == null:
				continue
			var atype = affix.get("affix_type")
			if atype == 4:  ## AffixType.HEALTH_FLAT
				var val = affix.get("value")
				if val != null:
					total += val
	return total

func _find_empty_slot() -> int:
	for i in items.size():
		if items[i] == null:
			return i
	return -1

func _is_equippable(item: Resource) -> bool:
	var cat = item.get("category")
	if cat == null:
		return false
	return cat < 9  ## ItemCategory.CONSUMABLE = 9
