class_name BTNode
extends RefCounted
## Behavior Tree ノード基底クラス

enum Status {
	SUCCESS,
	FAILURE,
	RUNNING
}

func tick(delta: float, actor: Node) -> Status:
	return Status.FAILURE
