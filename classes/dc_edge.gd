class_name DCEdge
extends Edge

#var start:Vertex ## Starting vertex of edge
#var end: Vertex ## Other vertex of edge
var face: Face ## Face connected to edge

var twin: DCEdge ## The other edge that is similar to this edge
var next: DCEdge ## Next edge i.e. CW to this edge (neg angle)
var prev: DCEdge ## Prev edge i.e. is CCW to this edge (pos angle)


func initialize(start_point:Vertex, end_point:Vertex, edge_face:Face):
	self.start = start_point
	self.end = end_point
	self.face = edge_face
	return self

static func create_dcedge(start_point:Vertex=null, end_point:Vertex=null, edge_face:Face=null) -> DCEdge:
	var out = DCEdge.new()
	out.start = start_point
	out.end = end_point
	out.face = edge_face
	return out


func _to_string():
	return "DCEdge: {} -> {}".format(str(start), str(end))

## Return length of edge
func length():
	return (end.point - start.point).length()

## Sets all connections
func set_edge_connection(next_edge:DCEdge=null, prev_edge:DCEdge=null, twin_edge:DCEdge=null):
	self.next = next_edge
	self.prev = prev_edge
	self.twin = twin_edge
