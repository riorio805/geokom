## Represents a Face of the diagram
class_name Face
extends Resource

var vertex:Vertex

var edge_list: Array[DCEdge]

var _upel_flag: bool = false

static func create_face(vtx:Vertex) -> Face:
	var out = Face.new()
	out.vertex = vtx
	var tmp:Array[DCEdge] = []
	out.edge_list = tmp
	return out


func _update_edge_list() -> void:
	edge_list.sort_custom(
		func (p): return (p.end.point - p.start.point).angle()
	)
	_upel_flag = false


## Return true if p is in this face
func contains_point(p:Vector2) -> bool:
	if _upel_flag: _update_edge_list()
	for edge in edge_list:
		var v1 = edge.end.point - edge.start.point
		var v2 = p - edge.end.point
		if v1.angle_to(v2) < 0:
			return false
	return true


## Checks if face is has half-edges
func is_external() -> bool:
	if _upel_flag: _update_edge_list()
	for i in range(len(edge_list)):
		if not edge_list[i].end.is_equal_approx(
			edge_list[posmod(i+1, len(edge_list))].start):
			return false
	return true
