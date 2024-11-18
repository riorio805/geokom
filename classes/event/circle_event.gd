extends Event
class_name CircleEvent

#var y:float
var arc:ArcTreeNode
var vertex: Vertex

static func create_circle_event(y_val:float, a:ArcTreeNode, vtx:Vertex) -> CircleEvent:
	var out = CircleEvent.new()
	out.y = y_val
	out.arc = a
	out.vertex = vtx
	return out

func value():
	return [-y, 1, -self.vertex.point.x]

func is_valid() -> bool:
	return (not arc.is_deleted and arc.vertex == vertex)

func _to_string():
	return "CircleEvent:: {0}, y={1} ".format([self.arc.vertex, self.y])
