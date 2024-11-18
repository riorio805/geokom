extends Resource	
class_name Vertex

var point:Vector2
var face:Face = null
var connected_edges:Array[Edge]

static func create_vertex(at_point:Vector2, in_face:Face=null) -> Vertex:
	var out = Vertex.new()
	out.point = at_point
	out.face = in_face
	return out

static func create_vertex_auto_face(at_point:Vector2) -> Vertex:
	var out = Vertex.new()
	out.point = at_point
	out.face = Face.create_face(out)
	return out

## Deprecated
static func init(at_point:Vector2) -> Vertex:
	return create_vertex(at_point)

## Deprecated
func initialize(at_point:Vector2) -> Vertex:
	self.point = at_point
	return self

func _to_string():
	return "vtx:{0}".format([str(point)])


## Returns true if `self` is lexicographically smaller than `other`, in order of y, then x.
## If `other` has the same point as `self` this will return false.
func less_than(other) -> bool:
	if other is Vertex:
		if self.point.y < other.point.y: return true
		elif self.point.y > other.point.y: return false
		else: return self.point.x < other.point.x
	elif other is Vector2:
		if self.point.y < other.y: return true
		elif self.point.y > other.y: return false
		else: return self.point.x < other.x
	elif other is InfXVertex:
		if self.point.y < other.y: return true
		elif self.point.y > other.y: return false
		return other.direction == InfXVertex.Direction.X_PLUS
	print("Vertex/less_than: Something has gone very wrong ; ", self, "; ", other)
	return false

static func get_max_vertex(arr:Array[Vertex]) -> Vertex:
	return arr.reduce(
		func(max_vec, vec):
			return vec if max_vec.less_than(vec) else max_vec
	)

static func get_min_vertex(arr:Array[Vertex]) -> Vertex:
	return arr.reduce(
		func(min_vec, vec):
			return vec if vec.less_than(min_vec) else min_vec
	)
