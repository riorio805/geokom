extends Event
class_name CircleEvent

#var y:float
var arc1:ArcTreeNode
var arc2:ArcTreeNode
var arc3:ArcTreeNode

static func create_circle_event(y_val:float, a1:ArcTreeNode, a2:ArcTreeNode, a3:ArcTreeNode) -> CircleEvent:
	var out = CircleEvent.new()
	out.y = y_val
	out.arc1 = a1
	out.arc2 = a2
	out.arc3 = a3
	return out


func is_valid() -> bool:
	if arc1 == null or arc2 == null or arc3 == null: return false
	return arc1.next == arc2 and arc2.next == arc3

func _to_string():
	return "CircleEvent:: vtx: {0} - {1} - {2}, y={3}".format(
		[self.arc1.vertex, self.arc2.vertex, self.arc3.vertex, self.y])
