class_name BTLeaf
extends BTNode
## 葉ノード — Callableをラップして条件チェックまたはアクションを実行

var _callable: Callable

func _init(callable: Callable) -> void:
	_callable = callable

func tick(delta: float, actor: Node) -> Status:
	if not _callable.is_valid():
		return Status.FAILURE
	var result = _callable.call(delta, actor)
	if result is int:
		return result as Status
	if result is bool:
		return Status.SUCCESS if result else Status.FAILURE
	return Status.SUCCESS
