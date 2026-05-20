class_name InventoryScreen
extends CanvasLayer
## インベントリ画面 — グリッドにアイテムを表示し、クリックで装備
## Toggle: I キー (InputMapper.is_inventory_just_pressed)

const SLOT_SIZE: Vector2 = Vector2(64, 64)
const GRID_COLUMNS: int = 10

@onready var _grid: GridContainer = $Panel/MarginContainer/HBox/Inventory/ScrollContainer/Grid
@onready var _equipment_container: VBoxContainer = $Panel/MarginContainer/HBox/Equipment/SlotList
@onready var _detail_label: RichTextLabel = $Panel/MarginContainer/HBox/Detail/RichLabel
@onready var _gold_label: Label = $Panel/MarginContainer/HBox/Equipment/GoldLabel

var _bound_inventory: InventoryComponent = null
var _slot_buttons: Array[Button] = []
var _equipment_buttons: Dictionary = {}

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.inventory_opened.connect(_on_inventory_opened)
	EventBus.inventory_closed.connect(_on_inventory_closed)

func bind_inventory(inventory: InventoryComponent) -> void:
	if _bound_inventory == inventory:
		return
	if _bound_inventory:
		_bound_inventory.inventory_changed.disconnect(_refresh)
		_bound_inventory.equipment_changed.disconnect(_refresh)
	_bound_inventory = inventory
	if _bound_inventory:
		_bound_inventory.inventory_changed.connect(_refresh)
		_bound_inventory.equipment_changed.connect(_refresh)
		_refresh()

func toggle() -> void:
	visible = not visible
	if visible:
		EventBus.inventory_opened.emit()
		_refresh()
	else:
		EventBus.inventory_closed.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"open_inventory"):
		toggle()
	elif visible and event.is_action_pressed(&"pause"):
		toggle()

func _refresh() -> void:
	if _bound_inventory == null:
		return
	_refresh_inventory_grid()
	_refresh_equipment()
	_refresh_gold()

func _refresh_inventory_grid() -> void:
	_clear_grid()
	for i in _bound_inventory.items.size():
		var btn := Button.new()
		btn.custom_minimum_size = SLOT_SIZE
		var item := _bound_inventory.items[i]
		if item:
			btn.text = "%s\nx%d" % [item.display_name, item.quantity]
			btn.modulate = item.get_rarity_color()
			btn.tooltip_text = item.description
		btn.pressed.connect(_on_slot_pressed.bind(i))
		btn.mouse_entered.connect(_on_slot_hovered.bind(i))
		_grid.add_child(btn)
		_slot_buttons.append(btn)

func _refresh_equipment() -> void:
	for child in _equipment_container.get_children():
		if child.name != "GoldLabel":
			child.queue_free()
	_equipment_buttons.clear()
	for category in [
		ItemData.ItemCategory.WEAPON_MELEE,
		ItemData.ItemCategory.ARMOR_HEAD,
		ItemData.ItemCategory.ARMOR_CHEST,
		ItemData.ItemCategory.ACCESSORY,
	]:
		var item := _bound_inventory.get_equipped(category)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 40)
		if item:
			btn.text = "%s: %s" % [_category_name(category), item.display_name]
			btn.modulate = item.get_rarity_color()
		else:
			btn.text = "%s: (なし)" % _category_name(category)
		btn.pressed.connect(_on_equipment_pressed.bind(category))
		_equipment_container.add_child(btn)
		_equipment_buttons[category] = btn

func _refresh_gold() -> void:
	_gold_label.text = "ゴールド: %d" % _bound_inventory.gold

func _clear_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_slot_buttons.clear()

func _on_slot_pressed(slot_index: int) -> void:
	if _bound_inventory == null:
		return
	var item := _bound_inventory.items[slot_index] if slot_index < _bound_inventory.items.size() else null
	if item == null:
		return
	if item.category < ItemData.ItemCategory.CONSUMABLE:
		_bound_inventory.equip(slot_index)

func _on_slot_hovered(slot_index: int) -> void:
	var item := _bound_inventory.items[slot_index] if slot_index < _bound_inventory.items.size() else null
	_show_detail(item)

func _on_equipment_pressed(category: int) -> void:
	_bound_inventory.unequip(category)

func _show_detail(item: ItemData) -> void:
	if item == null:
		_detail_label.text = "[i]アイテムを選択してください[/i]"
		return
	var color := item.get_rarity_color()
	var text := "[color=#%s][b]%s[/b][/color]\n" % [color.to_html(false), item.display_name]
	text += "[i]%s[/i]\n\n" % item.description
	text += "種別: %s\n" % _category_name(item.category)
	text += "レア度: %s\n" % _rarity_name(item.rarity)
	if item.element != ItemData.Element.NONE:
		text += "属性: %s\n" % _element_name(item.element)
	if item.base_damage > 0:
		text += "基礎ダメージ: %d\n" % int(item.base_damage)
	if item.base_armor > 0:
		text += "基礎防御: %d\n" % int(item.base_armor)
	if item.base_health_bonus > 0:
		text += "HP+%d\n" % int(item.base_health_bonus)
	if item.base_mana_bonus > 0:
		text += "MP+%d\n" % int(item.base_mana_bonus)
	for affix in item.affixes:
		if affix:
			text += "[color=#aaffaa]%s[/color]\n" % affix.get_display_text()
	text += "\n売却価格: %d G" % item.sell_price
	_detail_label.text = text

func _category_name(c: int) -> String:
	match c:
		ItemData.ItemCategory.WEAPON_MELEE: return "近接武器"
		ItemData.ItemCategory.WEAPON_RANGED: return "遠距離武器"
		ItemData.ItemCategory.WEAPON_MAGIC: return "魔法武器"
		ItemData.ItemCategory.ARMOR_HEAD: return "頭"
		ItemData.ItemCategory.ARMOR_CHEST: return "胴"
		ItemData.ItemCategory.ARMOR_HANDS: return "手"
		ItemData.ItemCategory.ARMOR_LEGS: return "脚"
		ItemData.ItemCategory.ARMOR_FEET: return "足"
		ItemData.ItemCategory.ACCESSORY: return "装飾品"
		ItemData.ItemCategory.CONSUMABLE: return "消耗品"
		_: return "その他"

func _rarity_name(r: int) -> String:
	match r:
		ItemData.Rarity.COMMON: return "コモン"
		ItemData.Rarity.UNCOMMON: return "アンコモン"
		ItemData.Rarity.RARE: return "レア"
		ItemData.Rarity.EPIC: return "エピック"
		ItemData.Rarity.LEGENDARY: return "レジェンダリ"
		ItemData.Rarity.MYTHIC: return "ミシック"
		_: return "?"

func _element_name(e: int) -> String:
	match e:
		ItemData.Element.FIRE: return "火"
		ItemData.Element.ICE: return "氷"
		ItemData.Element.LIGHTNING: return "雷"
		ItemData.Element.HOLY: return "聖"
		ItemData.Element.SHADOW: return "闇"
		ItemData.Element.NATURE: return "自然"
		ItemData.Element.ARCANE: return "秘術"
		_: return ""

func _on_inventory_opened() -> void:
	if not visible:
		visible = true

func _on_inventory_closed() -> void:
	if visible:
		visible = false
