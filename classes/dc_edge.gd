class_name DCEdge
extends Resource

var start: Vector2 ## Starting vertex of edge
var end: Vector2 ## Other vertex of edge
var face: Face ## Face connected to edge

var twin: DCEdge ## The other edge that is similar to this edge
var next: DCEdge ## Next edge i.e. CW to this edge (neg angle)
var prev: DCEdge ## Prev edge i.e. is CCW to this edge (pos angle)

static func init(start_point:Vector2, end_point:Vector2, face:Face) -> DCEdge:
	var out = DCEdge.new()
	out.start = start_point
	out.end = end_point
	out.face = face
	return out


func _to_string():
	return "DCEdge: {} -> {}".format(str(start), str(end))

## Return length of edge
func length():
	return (end - start).length()

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
