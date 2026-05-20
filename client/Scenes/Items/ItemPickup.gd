class_name ItemPickup
extends Area3D
## ワールド上に落ちているアイテムピックアップ
## プレイヤーが触れると InventoryComponent.add_item() を呼び出し queue_free()

@export var item_data: ItemData
@export var pickup_distance: float = 1.5
@export var bob_amplitude: float = 0.15
@export var bob_speed: float = 2.0
@export var rotation_speed: float = 1.5
@export var lifetime: float = 120.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _light: OmniLight3D = $OmniLight3D

var _initial_y: float = 0.0
var _elapsed: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	_initial_y = global_position.y
	_apply_rarity_visuals()
	if lifetime > 0.0:
		get_tree().create_timer(lifetime).timeout.connect(_expire)

func set_item_data(data: ItemData) -> void:
	item_data = data
	if is_inside_tree():
		_apply_rarity_visuals()

func _process(delta: float) -> void:
	_elapsed += delta
	global_position.y = _initial_y + sin(_elapsed * bob_speed) * bob_amplitude
	rotation.y += rotation_speed * delta

func _apply_rarity_visuals() -> void:
	if item_data == null:
		return
	var color := item_data.get_rarity_color()
	if _mesh and _mesh.get_active_material(0):
		var mat := _mesh.get_active_material(0) as StandardMaterial3D
		if mat:
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = 1.5
	if _light:
		_light.light_color = color
		_light.light_energy = 1.5

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(&"players"):
		return
	var inventory: InventoryComponent = body.get_node_or_null("InventoryComponent")
	if inventory == null:
		return
	if inventory.add_item(item_data):
		EventBus.item_picked_up.emit(item_data, body)
		queue_free()

func _expire() -> void:
	if is_instance_valid(self):
		queue_free()
