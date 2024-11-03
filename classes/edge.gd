extends Resource
class_name Edge


var start:Vertex
var end: Vertex

static func init_edge(start_point:Vertex, end_point:Vertex):
	var out = Edge.new()
	out.start = start_point
	out.end = end_point
	return out


func get_other_vertex(from_this:Vertex) -> Vertex:
	if from_this == start: return end
	elif from_this == end: return start
	print("Edge/get_other: Something has gone very wrong ; ", self, "; ", from_this)
	return null

func _to_string():
	return "Edge: {0} -> {1}".format([str(start), str(end)])
