class_name DCEdge
extends Edge

#var start: Vector2 ## Starting vertex of edge
#var end: Vector2 ## Other vertex of edge
var face: Face ## Face connected to edge

var twin: DCEdge ## The other edge that is similar to this edge
var next: DCEdge ## Next edge i.e. CW to this edge (neg angle)
var prev: DCEdge ## Prev edge i.e. is CCW to this edge (pos angle)


func initialize(start_point:Vertex, end_point:Vertex, face:Face):
	self.start = start_point
	self.end = end_point
	self.face = face
	return self



func _to_string():
	return "DCEdge: {} -> {}".format(str(start), str(end))

## Return length of edge
func length():
	return (end.point - start.point).length()

## Sets all connections in one go (using weak references)
func set_edge_connection(next_edge:DCEdge=null, prev_edge:DCEdge=null, twin_edge:DCEdge=null):
	self.set_next_edge(next_edge)
	self.set_prev_edge(prev_edge)
	self.set_twin_edge(twin_edge)

## Sets next edge (using weak references)
func set_next_edge(next_edge:DCEdge):
	self.next = weakref(next_edge)

## Sets prev edge (using weak references)
func set_prev_edge(prev_edge:DCEdge):
	self.prev = weakref(prev_edge)

## Sets twin edge (using weak references)
func set_twin_edge(twin_edge:DCEdge):
	self.twin = weakref(twin_edge)
