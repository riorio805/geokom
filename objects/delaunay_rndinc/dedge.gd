extends Edge
class_name DEdge

#var start:Vertex
#var end: Vertex
#	var connected_edges:Array[Edge]
#	var point:Vector2
var t1: DTriangle
var t2: DTriangle
# Define p0p-1p-2 as the triangle with no other triangle neighboring

static func create_dedge(
		start_point:Vertex, end_point:Vertex, tri_1:DTriangle=null, tri_2:DTriangle=null):
	var out = DEdge.new()
	out.start = start_point
	out.end = end_point
	out.t1 = tri_1
	out.t2 = tri_2
	return out

func set_triangles(tri_1:DTriangle, tri_2:DTriangle):
	self.t1 = tri_1
	self.t2 = tri_2

func _to_string():
	return "DEdge: {0} -> {1}".format([str(start), str(end)])

func get_other_triangle(other:DTriangle) -> DTriangle:
	if other == t1: 		return t2
	elif other == t2: 	return t1
	print("DEdge/get_other_triangle: Something has gone very wrong; e:{3}\n\t t1:{0}, t2:{1}, other:{2}".format([t1, t2, other, self]))
	return null

func replace_triangle(from:DTriangle, to:DTriangle) -> void:
	if from == t1: 		t1 = to
	elif from == t2: 	t2 = to
	pass

## Return true if edge is an edge of the outer triangle
func is_outer() -> bool:
	return t1 == null or t2 == null

func is_infinite() -> bool:
	return start is InfXVertex or end is InfXVertex
