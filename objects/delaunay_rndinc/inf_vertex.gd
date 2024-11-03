extends Vertex	
class_name InfXVertex

enum Direction {
	X_PLUS = 1,
	X_MIN = -1,
}

var y: float
var direction:Direction

func _to_string() -> String:
	return "(y={0}, dir={1})".format([y, direction])

static func create_infxvertex(y_pos:float, dir:Direction) -> InfXVertex:
	var out = InfXVertex.new()
	out.y = y_pos
	out.direction = dir
	return out


## Returns true if `self` is lexicographically smaller than `other`, in order of y, then x.
## If `other` has the same point as `self` this will return false.
func less_than(other) -> bool:
	if other is Vertex:
		if self.y < other.point.y: return true
		elif self.y > other.point.y: return false
		else: self.direction == InfXVertex.Direction.X_MIN
	elif other is Vector2:
		if self.point.y < other.y: return true
		elif self.point.y > other.y: return false
		else: self.direction == InfXVertex.Direction.X_MIN
	elif other is InfXVertex:
		if self.y < other.y: return true
		elif self.y > other.y: return false
		return self.direction == InfXVertex.Direction.X_MIN and other.direction == InfXVertex.Direction.X_PLUS
	print("InfXVertex/less_than: Something has gone very wrong ; ", self, "; ", other)
	return false
