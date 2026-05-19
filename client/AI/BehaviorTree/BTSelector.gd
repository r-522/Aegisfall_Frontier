class_name BTSelector
extends BTNode
## 選択ノード — 1つの子ノードが SUCCESS なれば SUCCESS
## 全て FAILURE なら FAILURE

var _children: Array[BTNode] = []
var _running_index: int = 0

func add_child(child: BTNode) -> BTSelector:
	_children.append(child)
	return self

func tick(delta: float, actor: Node) -> Status:
	var start := _running_index
	for i in range(start, _children.size()):
		var result := _children[i].tick(delta, actor)
		match result:
			Status.SUCCESS:
				_running_index = 0
				return Status.SUCCESS
			Status.RUNNING:
				_running_index = i
				return Status.RUNNING
			Status.FAILURE:
				continue
	_running_index = 0
	return Status.FAILURE
