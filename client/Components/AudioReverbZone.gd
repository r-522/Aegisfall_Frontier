extends Area3D
class_name AudioReverbZone
## エリア進入時にAudioManagerのReverbプリセットを切り替える。

@export var zone_type: int = 0
@export var revert_on_exit: bool = true

const _DEFAULT_ZONE: int = 0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	if revert_on_exit:
		body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if not _is_local_player(body):
		return
	var mgr := get_node_or_null("/root/AudioManager")
	if mgr != null:
		mgr.set_reverb_zone(zone_type)

func _on_body_exited(body: Node3D) -> void:
	if not _is_local_player(body):
		return
	var mgr := get_node_or_null("/root/AudioManager")
	if mgr != null:
		mgr.set_reverb_zone(_DEFAULT_ZONE)

func _is_local_player(body: Node) -> bool:
	if not body.is_in_group("players"):
		return false
	if body.has_method("is_local_player"):
		return body.is_local_player()
	return true
