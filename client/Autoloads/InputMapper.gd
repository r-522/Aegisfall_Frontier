extends Node
## 全入力を抽象化するレイヤー
## ゲームプレイコードはInputMapperのメソッドのみ呼び出し、Input.*は直接使用しない
## これによりキーリバインドを全コードに影響なく実装可能

var _mouse_delta: Vector2 = Vector2.ZERO
var _mouse_captured: bool = false

func _ready() -> void:
	capture_mouse()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_delta = event.relative

func _process(_delta: float) -> void:
	_mouse_delta = Vector2.ZERO

# === マウス制御 ===
func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_mouse_captured = true

func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_mouse_captured = false

func is_mouse_captured() -> bool:
	return _mouse_captured

func get_mouse_delta() -> Vector2:
	return _mouse_delta if _mouse_captured else Vector2.ZERO

# === 移動入力 ===
func get_move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back")

func is_moving() -> bool:
	return get_move_vector().length_squared() > 0.01

# === アクション入力 ===
func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("jump")

func is_dash_pressed() -> bool:
	return Input.is_action_pressed("dash")

func is_crouch_pressed() -> bool:
	return Input.is_action_pressed("crouch")

func is_crouch_just_pressed() -> bool:
	return Input.is_action_just_pressed("crouch")

func is_interact_just_pressed() -> bool:
	return Input.is_action_just_pressed("interact")

func is_dodge_just_pressed() -> bool:
	return Input.is_action_just_pressed("dodge")

# === 攻撃入力 ===
func is_attack_normal_just_pressed() -> bool:
	return Input.is_action_just_pressed("attack_normal")

func is_attack_heavy_just_pressed() -> bool:
	return Input.is_action_just_pressed("attack_heavy")

func is_attack_normal_pressed() -> bool:
	return Input.is_action_pressed("attack_normal")

# === スキル入力 ===
func is_skill_just_pressed(slot: int) -> bool:
	match slot:
		0: return Input.is_action_just_pressed("skill_1")
		1: return Input.is_action_just_pressed("skill_2")
		2: return Input.is_action_just_pressed("skill_3")
		3: return Input.is_action_just_pressed("ultimate")
	return false

func get_pressed_skill_slot() -> int:
	for i in 4:
		if is_skill_just_pressed(i):
			return i
	return -1

# === UI入力 ===
func is_pause_just_pressed() -> bool:
	return Input.is_action_just_pressed("pause")

func is_inventory_just_pressed() -> bool:
	return Input.is_action_just_pressed("open_inventory")

func is_build_menu_just_pressed() -> bool:
	return Input.is_action_just_pressed("open_build_menu")

# === ゲームパッド対応 (将来実装用スタブ) ===
func get_gamepad_move_vector() -> Vector2:
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func remap_action(action: StringName, new_event: InputEvent) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_event)
