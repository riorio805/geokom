extends Resource
class_name Circle

const MACHINE_EPS = 1e-7

var center:Vector2
var radius:float

static func create_circle(c:Vector2, r:float) -> Circle:
	var out = Circle.new()
	out.center = c
	out.radius = r
	return out


static func create_from_3_points(p1:Vector2, p2:Vector2, p3:Vector2) -> Circle:
	var wt = p3 - p1
	var wb = p2 - p1
	var w = Vector2(wt.dot(wb), wt.dot(Vector2(-wb.y, wb.x))) / wb.length_squared()
	
	var tmp = w - Vector2(w.length_squared(), 0)
	var tmp2 = Vector2(0,2*w.y)
	tmp = Vector2(tmp.dot(tmp2), tmp.dot(Vector2(-tmp2.y, tmp2.x))) / tmp2.length_squared()
	var c = Vector2(wb.x * tmp.x - wb.y * tmp.y, wb.x * tmp.y + wb.y * tmp.x) + p1
	var r = (p1 - c).length()
	
	return Circle.create_circle(c, r)

func _to_string():
	return "(c={0}, r={1})".format([center, radius])
