class_name InventoryComponent
extends Node
## インベントリ管理 — アイテム所持・装備・スタックを担当
## 装備変更時に equipment_changed シグナルでステータス再計算を要求

signal item_added(item: ItemData, slot_index: int)
signal item_removed(item: ItemData, slot_index: int)
signal item_equipped(item: ItemData, category: int)
signal item_unequipped(item: ItemData, category: int)
signal inventory_changed
signal equipment_changed

const MAX_INVENTORY_SLOTS: int = 60

var items: Array[ItemData] = []
var equipped: Dictionary = {}
var gold: int = 0

func _ready() -> void:
	items.resize(MAX_INVENTORY_SLOTS)

func add_item(item: ItemData) -> bool:
	if item == null:
		return false
	if item.category == ItemData.ItemCategory.GOLD:
		gold += item.quantity
		EventBus.gold_changed.emit(gold)
		return true
	if item.stack_size > 1:
		for i in items.size():
			var existing := items[i]
			if existing != null and existing.item_id == item.item_id and existing.quantity < existing.stack_size:
				var room := existing.stack_size - existing.quantity
				var add_amount := min(room, item.quantity)
				existing.quantity += add_amount
				item.quantity -= add_amount
				inventory_changed.emit()
				if item.quantity <= 0:
					return true
	var slot := _find_empty_slot()
	if slot < 0:
		return false
	items[slot] = item
	item_added.emit(item, slot)
	inventory_changed.emit()
	return true

func remove_item(slot_index: int) -> ItemData:
	if slot_index < 0 or slot_index >= items.size():
		return null
	var item := items[slot_index]
	if item == null:
		return null
	items[slot_index] = null
	item_removed.emit(item, slot_index)
	inventory_changed.emit()
	return item

func equip(slot_index: int) -> bool:
	var item := items[slot_index] if slot_index < items.size() else null
	if item == null or not _is_equippable(item):
		return false
	var category := item.category
	if equipped.has(category):
		var previous: ItemData = equipped[category]
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
	var item: ItemData = equipped[category]
	equipped.erase(category)
	if not add_item(item):
		equipped[category] = item
		return false
	item_unequipped.emit(item, category)
	equipment_changed.emit()
	return true

func get_equipped(category: int) -> ItemData:
	return equipped.get(category, null)

func get_total_damage_bonus() -> float:
	var total := 0.0
	for category in equipped:
		var item: ItemData = equipped[category]
		if item:
			total += item.get_total_damage()
	return total

func get_total_armor_bonus() -> float:
	var total := 0.0
	for category in equipped:
		var item: ItemData = equipped[category]
		if item:
			total += item.get_total_armor()
	return total

func get_total_health_bonus() -> float:
	var total := 0.0
	for category in equipped:
		var item: ItemData = equipped[category]
		if item == null:
			continue
		total += item.base_health_bonus
		for affix in item.affixes:
			if affix and affix.affix_type == AffixData.AffixType.HEALTH_FLAT:
				total += affix.value
	return total

func _find_empty_slot() -> int:
	for i in items.size():
		if items[i] == null:
			return i
	return -1

func _is_equippable(item: ItemData) -> bool:
	return item.category < ItemData.ItemCategory.CONSUMABLE
