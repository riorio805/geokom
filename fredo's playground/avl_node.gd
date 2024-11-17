class_name AVLNode

# AVL stuff
var height: int = 1
var parent: AVLNode = null
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

var is_deleted = false

func _init(data:Vector2) -> void:
	arc_focus = data


func get_y(x, directrix_y):
	var pembilang = x*x - 2*arc_focus.x*x + arc_focus.x*arc_focus.x + pow(arc_focus.y, 2) - pow(directrix_y,2)
	var penyebut = 2*(arc_focus.y-directrix_y)
	
	return pembilang/penyebut
