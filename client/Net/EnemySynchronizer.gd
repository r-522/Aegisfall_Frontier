class_name EnemySynchronizer
extends Node
## 敵エンティティの同期 — サーバー権限のみがAI/物理を実行
## クライアントはMultiplayerSynchronizerで位置を受信・補間

# サーバー側: 全エネミーをトラッキング
var _tracked_enemies: Dictionary = {}  # node_path -> Node

func _ready() -> void:
	if not multiplayer.is_server():
		return
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.enemy_died.connect(_on_enemy_died)

func _on_enemy_spawned(enemy: Node) -> void:
	if not multiplayer.is_server():
		return
	_tracked_enemies[enemy.get_path()] = enemy

func _on_enemy_died(enemy: Node, _pos: Vector3, _xp: int) -> void:
	_tracked_enemies.erase(enemy.get_path())

@rpc("authority", "call_remote", "unreliable")
func update_enemy_transform(enemy_path: NodePath, pos: Vector3, rot: float) -> void:
	var enemy := get_node_or_null(enemy_path)
	if enemy == null:
		return
	enemy.global_position = enemy.global_position.lerp(pos, 0.3)
	enemy.rotation.y = lerp_angle(enemy.rotation.y, rot, 0.3)

@rpc("authority", "call_remote", "reliable")
func spawn_enemy_on_client(scene_path: String, pos: Vector3, enemy_id: int) -> void:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		return
	var enemy: Node3D = scene.instantiate()
	enemy.name = "Enemy_%d" % enemy_id
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = pos

@rpc("authority", "call_remote", "reliable")
func despawn_enemy_on_client(enemy_path: NodePath) -> void:
	var enemy := get_node_or_null(enemy_path)
	if enemy:
		enemy.queue_free()
