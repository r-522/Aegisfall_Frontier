class_name BTSequence
extends BTNode
## 順次実行ノード — 全子ノードが SUCCESS になれば SUCCESS
## 1つでも FAILURE なら即座に FAILURE

var _children: Array[BTNode] = []
var _running_index: int = 0

func add_child(child: BTNode) -> BTSequence:
	_children.append(child)
	return self

func tick(delta: float, actor: Node) -> Status:
	var start := _running_index
	for i in range(start, _children.size()):
		var result := _children[i].tick(delta, actor)
		match result:
			Status.FAILURE:
				_running_index = 0
				return Status.FAILURE
			Status.RUNNING:
				_running_index = i
				return Status.RUNNING
			Status.SUCCESS:
				continue
	_running_index = 0
	return Status.SUCCESS
