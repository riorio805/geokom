class_name AVLNode

# AVL stuff
var height: int = 1
var left: AVLNode = null
var right: AVLNode = null

# modified AVL : access predecessor & successor at O(1)
var prev: AVLNode = null
var next: AVLNode = null

# beach line
var arc_focus: Vector2

# edge
var right_edge_start
var right_edge_direction
#var ends_in_directrix

func _init(data:Vector2) -> void:
	arc_focus = data
	
func get_right_breakpoint(directrix_y):
	if next != null:
		return _get_breakpoint(arc_focus, next.arc_focus, directrix_y, false)
	return Vector2(INF, INF)

func get_left_breakpoint(directrix_y):
	if prev != null:
		return _get_breakpoint(arc_focus, prev.arc_focus, directrix_y, true)
	return Vector2(-INF, INF)

func _get_breakpoint(p1:Vector2, p2:Vector2, directrix_y, take_min:bool):
	p1.y = -p1.y
	p2.y = -p2.y
	directrix_y = -directrix_y
	
	# asumsi parabola terletak pada y yang lebih besar daripada directrix_y
	var pembagi1 = 2*(p1.y-directrix_y)
	var pembagi2 = 2*(p2.y-directrix_y)
	
	var a = 1.0 / pembagi1 - 1.0 / pembagi2
	var b = -2*p1.x/pembagi1 + 2*p2.x/pembagi2
	var c = (p1.x*p1.x + p1.y*p1.y - directrix_y*directrix_y)/pembagi1 - (p2.x*p2.x + p2.y*p2.y - directrix_y*directrix_y)/pembagi2
	
	# Use quadratic formula
	var discriminant = b * b - 4.0 * a * c
	discriminant = max(0.0, discriminant)  # Avoid negative values due to floating point errors

	# Return leftmost intersection point for Fortune's algorithm
	var x1 = (-b - sqrt(discriminant)) / (2.0 * a)
	var x2 = (-b + sqrt(discriminant)) / (2.0 * a)
	
	p1.y = -p1.y
	p2.y = -p2.y
	directrix_y = -directrix_y
	

	var ans_x = x1 if take_min else x2
	var ans_y = (pow(ans_x,2) - 2*p1.x*ans_x + p1.x*p1.x + p1.y*p1.y - directrix_y)/pembagi1

	return Vector2(ans_x, ans_y)
	

func get_y(x, directrix_y):
	var pembilang = x*x - 2*arc_focus.x*x + arc_focus.x*arc_focus.x + pow(arc_focus.y, 2) - pow(directrix_y,2)
	var penyebut = 2*(arc_focus.y-directrix_y)
	
	return pembilang/penyebut
