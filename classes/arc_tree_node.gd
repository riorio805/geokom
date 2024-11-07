## Represents an arc.
## Implementation inspired by https://pvigier.github.io/2018/11/18/fortune-algorithm-details.html
extends Resource
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

# Keep a reference to the global event_queue
var event_queue:PriorityQueue

## Initialize a arc
func initialize(focus_vtx:Vertex, arc_parent:ArcTreeNode=null) -> void:
	self.parent = arc_parent
	self.vertex = focus_vtx
	self.height = 1

static func create_node(focus_vtx:Vertex, arc_parent:ArcTreeNode=null) -> ArcTreeNode:
	var out = ArcTreeNode.new()
	out.initialize(focus_vtx, arc_parent)
	return out


func remove_all_references():
	self.parent = null
	self.left = null
	self.right = null
	self.vertex = null
	self.prev = null
	self.next = null
	self.left_hedge = null
	self.right_hedge = null
	self.event_queue = null


func is_leaf():
	return self.left == null and self.right == null


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
		@warning_ignore("confusable_local_declaration")
		var x = left_vertex.point.x
		# get y from other parabola at x
		var x2 = right_vertex.point.x
		# y = (x^2 - 2*x2 * x + x2^2 + y2^2)/y^2
		@warning_ignore("confusable_local_declaration")
		var y = (x**2 - 2 * x2 * x + x2**2 + y2**2) / (2*y2)
		# translate back by l_y
		y = y + l_y
		return Vector2(x, y)
	if y2 < MACHINE_EPS:
		@warning_ignore("confusable_local_declaration")
		var x = right_vertex.point.x
		# get y from other parabola at x
		var x1 = left_vertex.point.x
		# y = (x^2 - 2*x1 * x + x1^2 + y1^2)/y1^2
		@warning_ignore("confusable_local_declaration")
		var y = (x**2 - 2 * x1 * x + x1**2 + y1**2) / (2*y1)
		# translate back by l_y
		y = y + l_y
		return Vector2(x, y)
	
	# Solve (1-y1/y2)x^2 - 2 * (1+y1/y2)rx + (1-y1/y2) r^2 + y1^2 - y1y2 = 0
	var a = (1 - y1/y2)
	var b = -2 * r * (1 + y1/y2)
	var c = a * r**2 + y1**2 - y1 * y2
	var sols = Equation.quadratic_solve_real(a, b, c)
	assert (len(sols) >= 1, "No solutions exist: left={0}, right={1}".format([left_vertex, right_vertex]))
	
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


## Gets the y position of the arc given an x value and directrix l_y
func get_y_at(x:float, l_y:float) -> float:
	var p = vertex.point
	
	# get coefs a,b,c,d, then sub x in y=a(x^2 + b.x + c)
	var a = 1/(2 * (p.y - l_y))
	var b = -2 * p.x
	var c = pow(p.x, 2) + pow(p.y, 2) - pow(l_y, 2)
	
	return a * (pow(x, 2) + b * (x) + c)


## Get the bound points of this arc. (where this arc "ends")
## Assumes that both prev and next exists.
func get_bounds(l_y:float) -> Array[Vector2]:
	var out:Array[Vector2] = [Vector2(), Vector2()]
	if self.prev != null:
		out[0] = ArcTreeNode.get_breakpoint(self.prev.vertex, self.vertex, l_y)
	if self.next != null:
		out[1] = ArcTreeNode.get_breakpoint(self.vertex, self.next.vertex, l_y)
	return out


# string representation
func _to_string():
	return ("=======================\n"
			+ _get_string("S----")
			+ "=======================")
func _get_string(indent:String, h:int=0) -> String:
	var out = ""
	if self.right != null:
		out += self.right._get_string("R----", h + 1)
	out += ("	".repeat(h)
			+ indent
			+ str(self.vertex)
			+ " // "
			+ str(self.height)) + "\n"
	if self.left != null:
		out += self.left._get_string("L----", h + 1)
	return out

## Finds the beach line arc with sweep line = l_y corresponding to the x value
func find (x: float, l_y:float) -> ArcTreeNode:
	# special case: if node is on the edge, then return node
	var bounds = self.get_bounds(l_y)
	# if x is below left bound (if exists), check left
	if self.left != null and x < bounds[0].x:
		return self.left.find(x, l_y)
	# if x is above right bound (if exists), check right
	elif self.right != null and x > bounds[1].x:
		return self.right.find(x, l_y)
	# Return self if x is in bounds (inclusive)
	return self

## Replace the child node `from` to the node `to`
func replace_child(from:ArcTreeNode, to:ArcTreeNode):
	if self.left == from:
		self.left = to
	elif self.right == from:
		self.right = to


# ==================
# Add/split arcs
# ==================

func get_focus_angle() -> float:
	if self.prev == null or self.next == null:
		return 1
	var left_edge = self.vertex.point - self.prev.vertex.point
	var right_edge = self.next.vertex.point - self.vertex.point
	return left_edge.angle_to(right_edge)

## Split an arc given a new vertex
func split_arc(focus:Vertex) -> ArcTreeNode:
	var l_y = focus.point.y
	var bounds = self.get_bounds(l_y)
	
	# if x is below bounds, check left
	if self.left != null and focus.point.x < bounds[0].x:
		self.left = self.left.split_arc(focus)
		return self._balance()
	# if x is above bounds, check right
	elif self.right != null and focus.point.x > bounds[1].x:
		self.right = self.right.split_arc(focus)
		return self._balance()
	
	# found arc, create new arcs as split
	var left_arc = ArcTreeNode.create_node(self.vertex)
	var right_arc = ArcTreeNode.create_node(self.vertex)
	left_arc.event_queue = self.event_queue
	right_arc.event_queue = self.event_queue
	self.vertex = focus
	# add created nodes to children, keeping position
	if self.left == null:	self.add_leftmost(left_arc)
	else:		self.left = self.left.add_rightmost(left_arc)
	self.prev = left_arc
	if self.right == null:	self.add_rightmost(right_arc)
	else:		self.right = self.right.add_leftmost(right_arc)
	self.next = right_arc
	
	# Create edges starting at the x of focus and the y at the parabola,
	var edge_start = Vertex.create_vertex(
		Vector2(focus.point.x, self.get_y_at(focus.point.x, l_y)))
	var edge_from_right_top = DCEdge.create_dcedge(edge_start, null, self.vertex.face)
	var edge_to_left_top = DCEdge.create_dcedge(null, edge_start, self.vertex.face)
	var edge_from_left_btm = DCEdge.create_dcedge(null, edge_start, focus.face)
	var edge_to_right_btm = DCEdge.create_dcedge(edge_start, null, focus.face)
	edge_from_right_top.set_edge_connection(
			edge_to_left_top, null, edge_to_right_btm)
	edge_to_left_top.set_edge_connection(
			null, edge_from_right_top, edge_from_left_btm)
	edge_from_left_btm.set_edge_connection(
			edge_to_right_btm, null, edge_to_left_top)
	edge_to_right_btm.set_edge_connection(
			null, edge_from_left_btm, edge_from_right_top)
	
	# then attach them to the arc edges
	left_arc.left_hedge = self.left_hedge
	right_arc.right_hedge = self.right_hedge
	self.left_hedge = edge_from_left_btm
	self.right_hedge = edge_to_right_btm
	left_arc.right_hedge = edge_to_left_top
	right_arc.left_hedge = edge_from_right_top
	
	# Check for arc triples that can cause an arc to disappear,
	# disappear candidates: left_arc, right_arc
	# Check by using foci angles
	if left_arc.get_focus_angle() < -MACHINE_EPS:
		var circle = Circle.create_from_3_points(
			left_arc.prev.vertex.point, left_arc.vertex.point, left_arc.next.vertex.point)
		var event = CircleEvent.create_circle_event(circle.center.y - circle.radius,
			left_arc.prev, left_arc, left_arc.next)
		print(event)
		#event_queue.add(event)
	if right_arc.get_focus_angle() < -MACHINE_EPS:
		var circle = Circle.create_from_3_points(
			right_arc.prev.vertex.point, right_arc.vertex.point, right_arc.next.vertex.point)
		var event = CircleEvent.create_circle_event(circle.center.y - circle.radius,
			right_arc.prev, right_arc, right_arc.next)
		print(event)
		#event_queue.add(event)
	
	return self._balance()

func add_rightmost(arc:ArcTreeNode) -> ArcTreeNode:
	if self.right != null:
		self.right = self.right.add_rightmost(arc)
	else:
		arc.next = self.next
		if arc.next != null:
			arc.next.prev = arc
		arc.prev = self
		arc.parent = self
		self.right = arc
		self.next = arc
	self.update_height()
	return self._balance()

func add_leftmost(arc:ArcTreeNode) -> ArcTreeNode:
	if self.left != null:
		self.left = self.left.add_leftmost(arc)
	else:
		arc.prev = self.prev
		if arc.prev != null:
			arc.prev.next = arc
		arc.next = self
		arc.parent = self
		self.left = arc
		self.prev = arc
	self.update_height()
	return self._balance()



# ==================
# Delete arc
# ==================

static func delete_arc(to_delete:ArcTreeNode, l_y:float) -> ArcTreeNode:
	# handle edges first
	var end_pos = Vertex.create_vertex(to_delete.get_bounds(l_y)[0])
	to_delete.left_hedge.start = end_pos
	to_delete.left_hedge.twin.end = end_pos
	to_delete.right_hedge.end = end_pos
	to_delete.right_hedge.twin.start = end_pos
	
	# add arcs that change positions (prev until leaf)
	var to_change:Array[ArcTreeNode] = [to_delete]
	while not to_change[-1].is_leaf():
		to_change.append(to_delete.prev)
	to_change.reverse()
	
	# keep parent for later check
	var tmp_par = to_delete.parent
	
	# reorder tree to remove `to_delete` from tree
	for idx in range(len(to_change)-1):
		# to_change[idx] has no effective connections, and will replace to_change[idx+1]
		var change_prev = to_change[idx]
		var change_next = to_change[idx+1]
		change_prev.parent = change_next.parent
		change_prev.left = change_next.left
		change_prev.right = change_next.right
		change_next.parent.replace_child(change_next, change_prev)
	# final replace
	if len(to_change) < 2:
		to_delete.parent.replace_child(to_delete, null)
	else:
		to_delete.parent.replace_child(to_delete, to_change[-2])
	
	# remove `to_delete` from "linked list"
	if to_delete.prev != null:
		to_delete.prev.next = to_delete.next
	if to_delete.next != null:
		to_delete.next.prev = to_delete.prev
	
	# "delete" the arc
	to_delete.remove_all_references()
	if len(to_change) < 2:
		if tmp_par.parent == null:
			return tmp_par._balance()
		return tmp_par.parent._balance_up(tmp_par)
	# rebalance up until root node
	if to_change[-2].parent == null:
		return to_change[-2]._balance()
	return to_change[-2].parent._balance_up(to_change[-2])


# Balance recursively up until root node reached
func _balance_up(from:ArcTreeNode):
	# balance from child
	if self.left == from:
		self.left = self.left._balance()
	elif self.right == from:
		self.right = self.right._balance()
	
	# recurse into parent (if root then return balanced root)
	if self.parent == null:
		return self._balance()
	else:
		return self.parent._balance_up(self)




# =============
# Balancing
# =============

## Update current node height based on childs
func update_height() -> void:
	var lh = 0 if (self.left == null) else self.left.height
	var rh = 0 if (self.right == null) else self.right.height
	self.height = max(lh, rh) + 1

## Returns difference between left_node and right_node heights.
## Returns negative if left_node is taller, positive if right_node is taller, and 0 for same heights.
func height_difference() -> int:
	var lh = 0 if (self.left == null) else self.left.height
	var rh = 0 if (self.right == null) else self.right.height
	return lh - rh

func _balance() -> ArcTreeNode:
	# left - right
	var hd = self.height_difference()
	if hd > 1:
		hd = self.left.height_difference()
		if hd >= 0:	return self._single_rotate_right()
		else:		return self._rotate_LR()
	elif hd < -1:
		hd = self.right.height_difference()
		if hd <= 0:	return self._single_rotate_left()
		else:		return self._rotate_RL()
	self.update_height()
	return self


func _single_rotate_left() -> ArcTreeNode:
	var tmp = self.right
	tmp.parent = self.parent
	self.right = tmp.left
	if self.right != null:
		self.right.parent = self
	tmp.left = self
	self.parent = tmp
	
	self.update_height()
	tmp.update_height()
	return tmp

func _single_rotate_right() -> ArcTreeNode:
	var tmp = self.left
	tmp.parent = self.parent
	self.left = tmp.right
	if self.left != null:
		self.left.parent = self
	tmp.right = self
	self.parent = tmp
	
	self.update_height()
	tmp.update_height()
	return tmp

func _rotate_LR() -> ArcTreeNode:
	self.left = self.left._single_rotate_left()
	var tmp = self._single_rotate_right()
	
	self.update_height()
	tmp.update_height()
	return tmp

func _rotate_RL() -> ArcTreeNode:
	self.right = self.right._single_rotate_right()
	var tmp = self._single_rotate_left()
	
	self.update_height()
	tmp.update_height()
	return tmp
