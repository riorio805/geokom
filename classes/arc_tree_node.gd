## Represents an arc.
## Implementation inspired by https://pvigier.github.io/2018/11/18/fortune-algorithm-details.html
extends RefCounted
class_name ArcTreeNode

const MACHINE_EPS = 10e-8

# Relations to other arcs
var parent:ArcTreeNode
var left:ArcTreeNode
var right:ArcTreeNode
# Focus of arc
var vertex:Vertex
# Extra arc references to help arc bounds calculations (breakpoints)
var prev:ArcTreeNode
var next:ArcTreeNode
# Half-edges associated with this arc
var left_hedge: DCEdge
var right_hedge: DCEdge
# Height for self-balancing
var height:int

## Initialize a arc
func initialize(focus:Vertex, arc_parent:ArcTreeNode=null) -> void:
	self.parent = arc_parent
	self.left_vertex = focus
	self.height = 1
	self.left = null
	self.right = null
	self.prev = null
	self.next = null


## Get the breakpoint between both parabola (from the vertices) with the directrix = l_y.
## Always returns the breakpoint where the left arc corresponds with the left vertex, and right arc with the right vertex.
## Throws an assertion error if both points are close to the directrix, or below.
static func get_breakpoint(left_vertex:Vertex, right_vertex:Vertex, l_y:float) -> Vector2:
	# Translate by (-(p1_x+p2_x)/2, -l_y) to make calculations easier
	# Since after translation, x1 = -x2, use 1 variable instead (r)
	var cx = (left_vertex.point.x + right_vertex.point.x)/2
	var r = left_vertex.point.x - cx
	var y1 = left_vertex.point.y - l_y
	var y2 = right_vertex.point.y - l_y
	
	assert (y1 >= 0 and y2 >= 0, "Points must be above the directrix")
	
	# Special case for y1 == 0 or y2 == 0, return vertical distance
	# never the case that both y1 == y2 == 0, only happens when first starting
	# and can be avoided by having directrix start 1 down from the highest point
	assert (not (y1 < MACHINE_EPS and y2 < MACHINE_EPS), "Both points cannot be close to the directrix")
	if y1 < MACHINE_EPS:
		var x = left_vertex.point.x
		# get y from other parabola at x
		var x2 = right_vertex.point.x
		# y = (x^2 - 2*x2 * x + x2^2 + y2^2)/y^2
		var y = (x**2 - 2 * x2 * x + x2**2 + y2**2) / (2*y2)
		# translate back by l_y
		y = y + l_y
		return Vector2(x, y)
	if y2 < MACHINE_EPS:
		var x = right_vertex.point.x
		# get y from other parabola at x
		var x1 = left_vertex.point.x
		# y = (x^2 - 2*x1 * x + x1^2 + y1^2)/y1^2
		var y = (x**2 - 2 * x1 * x + x1**2 + y1**2) / (2*y1)
		# translate back by l_y
		y = y + l_y
		return Vector2(x, y)
	
	# Solve (1-y1/y2)x^2 - 2 * (1+y1/y2)rx + (1-y1/y2) r^2 + y1^2 - y1y2 = 0
	var a = (1 - y1/y2)
	var b = -2 * r * (1 + y1/y2)
	var c = a * r**2 + y1**2 - y1 * y2
	var sols = Equation.quadratic_solve_real(a, b, c)
	assert (len(sols) >= 1, "No solutions exist")
	
	# Get correct x value
	var x = 0
	if len(sols) == 1:
		# single value for x
		x = sols[0]
	else:
		# 2 values for x
		# check sign of midpoint between x's to determine breakpoint
		# with the solved function
		var mid_x = (sols[0] + sols[1]) / 2
		var mid_y = a * (mid_x**2) + b * mid_x + c
		# if y > 0 use lower x
		if mid_y > 0:
			x = sols.min()
		# else use higher x
		else:
			x = sols.max()
	
	# Get the y value corresponding with the x value on the
	# parabola with focus (r, y1) (left parabola)
	# var y = a * (x**2) + b * x + c
	var y = (x**2 - 2 * r * x + r**2 + y1**2) / (2*y1)
	
	# Translate by ((p1_x+p2_x)/2, l_y) to revert initial translation
	x += cx
	y += l_y
	return Vector2(x, y)


## Get the bound points of this arc. (where this arc "ends")
## Assumes that both prev and next exists.
func get_bounds(l_y:float) -> Array[Vector2]:
	return [
		ArcTreeNode.get_breakpoint(self.prev.vertex, self.vertex, l_y),
		ArcTreeNode.get_breakpoint(self.vertex, self.next.vertex, l_y)
	]


# string representation
func _to_string():
	return ("=======================\n"
			+ _get_string("S----")
			+ "=======================")
func _get_string(indent:String, h:int=0) -> String:
	var out = ""
	if self.right_node != null:
		out += self.right_node._get_string("R----", h + 1)
	out += ("	".repeat(h)
			+ indent
			+ str(self.left_vertex)
			+ ((", " + str(self.right_vertex)) if not self.is_leaf else "")
			+ " // "
			+ str(self.height)) + "\n"
	if self.left_node != null:
		out += self.left_node._get_string("L----", h + 1)
	return out

## Update current node height based on childs
func update_height() -> void:
	var lh = 0 if (self.left_node == null) else self.left_node.height
	var rh = 0 if (self.right_node == null) else self.right_node.height
	self.height = max(lh, rh) + 1

## Returns difference between left_node and right_node heights.
## Returns negative if left_node is taller, positive if right_node is taller, and 0 for same heights.
func height_difference() -> int:
	var lh = 0 if (self.left_node == null) else self.left_node.height
	var rh = 0 if (self.right_node == null) else self.right_node.height
	return lh - rh

## Finds the beach line arc with sweep line = l_y corresponding to the x value
func find (x: float, l_y:float) -> ArcTreeNode:
	# special case: if node is on the edge, then return node
	if self.prev == null or self.next == null:
		return self
	var bounds = self.get_bounds(l_y)
	# if x is below bounds, check left
	if x < bounds[0].x:
		return self.left.find(x, l_y)
	# if x is above bounds, check right
	elif x > bounds[1].x:
		return self.right.find(x, l_y)
	# Return self if x is in bounds (inclusive)
	return self

# Add an arc with focus at vertex recursively
static func add_arc(
		node:ArcTreeNode, vertex:Vertex, _from_right:bool=true
	) -> ArcTreeNode:
	if node.prev != null and node.next != null:
		var bounds = node.get_bounds(vertex.point.y)
		# if x is below bounds, check left
		if vertex.point.x < bounds[0].x:
			return node.left.add_arc(node, vertex, false)
		# if x is above bounds, check right
		elif vertex.point.x > bounds[1].x:
			return node.right.add_arc(node, vertex, true)
	
	return node

# Assumes root node is not a leaf node
static func delete_leaf(
		node:ArcTreeNode, target:ArcTreeNode
	) -> ArcTreeNode:

	
	return node

"""
static TreeNode delete(TreeNode cur, int x) {
	if (cur == null) return null;
	if (x < cur.value) {
		cur.left = delete(cur.left, x);
	}
	else if (x > cur.value) {
		cur.right = delete(cur.right, x);
	}
	else {
		if (cur.right == null) {
			return cur.left;
		}
		else if (cur.left == null) {
			return cur.right;
		}
		cur.value = cur.left.findBiggest().value;
		cur.left = delete(cur.left, cur.value);
	}
	cur.updateHeight();
	return cur.balance();
}
"""

# =========
# Rotations
# =========

func _balance() -> ArcTreeNode:
	# left - right
	var hd = self.height_difference()
	if hd > 1:
		hd = self.left_node.height_difference()
		if hd >= 0:	return self._single_rotate_right()
		else:		return self._rotate_LR()
	elif hd < -1:
		hd = self.right_node.height_difference()
		if hd <= 0:	return self._single_rotate_left()
		else:		return self._rotate_RL()
	return self


func _single_rotate_left() -> ArcTreeNode:
	var tmp = self.right_node
	self.right_node = tmp.left_node
	tmp.left_node = self
	
	self.update_height()
	tmp.update_height()
	return tmp

func _single_rotate_right() -> ArcTreeNode:
	var tmp = self.left_node
	self.left_node = tmp.right_node
	tmp.right_node = self
	
	self.update_height()
	tmp.update_height()
	return tmp

func _rotate_LR() -> ArcTreeNode:
	self.left_node = self.left_node._single_rotate_left()
	var tmp = self._single_rotate_right()
	
	self.update_height()
	tmp.update_height()
	return tmp

func _rotate_RL() -> ArcTreeNode:
	self.right_node = self.right_node._single_rotate_right()
	var tmp = self._single_rotate_left()
	
	self.update_height()
	tmp.update_height()
	return tmp
