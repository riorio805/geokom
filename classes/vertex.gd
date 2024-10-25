extends RefCounted
class_name Vertex

var point:Vector2
var connected_edges:Array[DCEdge]


func initialize(point:Vector2) -> Vertex:
	self.point = point
	return self

func _to_string():
	return str(point)
