extends Resource	
class_name Vertex

var point:Vector2
var connected_edges:Array[Edge]

static func create_vertex(point:Vector2) -> Vertex:
	var out = Vertex.new()
	out.point = point
	return out

## Deprecated
static func init(point:Vector2) -> Vertex:
	return create_vertex(point)

func initialize(point:Vector2) -> Vertex:
	self.point = point
	return self

func _to_string():
	return str(point)


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
		func(max, vec):
			return max if vec.less_than(max) else vec
	)

static func get_min_vertex(arr:Array[Vertex]) -> Vertex:
	return arr.reduce(
		func(min, vec):
			return vec if vec.less_than(min) else min
	)

## Gets all other vertices connected to this vertex, except for `from_edge`
func get_other(from_edge:Edge) -> Array[Vertex]:
	return []
