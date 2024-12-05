## Represents an arc.
## Implementation inspired by https://pvigier.github.io/2018/11/18/fortune-algorithm-details.html
extends Resource
class_name ArcTreeNode

const HALF_EDGE_DIST = 1e6
const MACHINE_EPS = 1e-5

# Relations to other arcs
var parent:ArcTreeNode
var left:ArcTreeNode
var right:ArcTreeNode
# Focus of arc
var vertex:Vertex
# Extra arc references to help arc bounds calculations (breakpoints)
# and to help deletion
var prev:ArcTreeNode
var next:ArcTreeNode
# Half-edges associated with this arc
var left_hedge: DCEdge
var right_hedge: DCEdge
# Height for self-balancing
var height:int

# Circle event check
var is_deleted = false

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


## Get the breakpoint between two parabola (from the vertices) with the directrix = l_y.
## Always returns the breakpoint where the left arc corresponds with the left vertex, and right arc with the right vertex.
## Throws an assertion error if both points are close to the directrix, or below.
static func get_breakpoint(left_vertex:Vertex, right_vertex:Vertex, l_y:float) -> Vector2:
	# Translate by (-(p1_x+p2_x)/2, -l_y) to make calculations easier
	# Since after translation, x1 = -x2, use 1 variable instead (r)
	var cx = (left_vertex.point.x + right_vertex.point.x)/2
	var r = left_vertex.point.x - cx
	var y1 = left_vertex.point.y - l_y
	var y2 = right_vertex.point.y - l_y
	
	assert (y1 >= -0.01 and y2 >= -0.01, "Points must be above the directrix (y1={0}, y2={1})".format([y1, y2]))
	
	# Special case for y1 == 0 or y2 == 0, return vertical distance
	# never the case that both y1 == y2 == 0, only happens when first starting
	#print(y1, "; ", y2)
	if (y1 < MACHINE_EPS and y2 < MACHINE_EPS):
		print("Handle both points  close to the directrix (v1={0}, v2={1})".format([left_vertex, right_vertex]))
		return left_vertex.get_bisector(right_vertex)[0]
		
	assert (not (y1 < MACHINE_EPS and y2 < MACHINE_EPS), "")
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
	assert (len(sols) >= 1, "No solutions exist: left={0}, right={1}, l_y={2}"
						.format([left_vertex, right_vertex, l_y]))
	
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
	if h > 32: return "	".repeat(h) + indent + "Infinite loop?"
	if self.right != null:
		out += self.right._get_string("R----", h + 1)
	out += ("	".repeat(h)
			+ indent
			+ self._get_info()
			+ "\n")
	if self.left != null:
		out += self.left._get_string("L----", h + 1)
	return out
func _get_info() -> String:
	return (str(self.vertex)
			+ " | L:" + str(self.left_hedge)
			+ " | R:" + str(self.right_hedge)
			+ " // "
			+ str(self.height))


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

## Special case when point intersects the beachline really high up, just use a point on the bisector(s) as the intersect point
func add_arc(focus:Vertex) -> ArcTreeNode:
	#print("in add_arc::", self.vertex, " with focus: ", focus)
	var diff = focus.point.x - self.vertex.point.x
	# found arc, create new arc
	var new_arc = ArcTreeNode.create_node(focus)
	new_arc.event_queue = self.event_queue
	
	# focus to the right
	if diff > 0:
		# Get edge limit through bisector
		var bisector = focus.get_bisector(self.vertex)
		#print(bisector)
		bisector[1] *= HALF_EDGE_DIST
		var end_vertex = Vertex.create_vertex(bisector[0] + bisector[1])
		# Create edges 
		var edge_to_vtx_right = DCEdge.create_dcedge(end_vertex, null, self.vertex.face)
		var edge_from_fcs_left = DCEdge.create_dcedge(null, end_vertex, new_arc.vertex.face)
		edge_to_vtx_right.twin = edge_from_fcs_left
		edge_from_fcs_left.twin = edge_to_vtx_right
		
		# then attach them to the arc edges
		self.right_hedge = edge_to_vtx_right
		new_arc.left_hedge = edge_from_fcs_left
		
		# Do the same to other side of focus if self.next exists
		if self.next != null:
			var snext = self.next
			# Get edge limit through bisector
			var bisector2 = snext.vertex.get_bisector(focus)
			bisector2[1] *= HALF_EDGE_DIST
			var end_vertex2 = Vertex.create_vertex(bisector2[0] + bisector2[1])
			# Create edges 
			var edge_from_vtx_left = DCEdge.create_dcedge(null, end_vertex2, snext.vertex.face)
			var edge_to_fcs_right = DCEdge.create_dcedge(end_vertex2, null, new_arc.vertex.face)
			edge_from_vtx_left.twin = edge_to_fcs_right
			edge_to_fcs_right.twin = edge_from_vtx_left
			# then attach them to the arc edges
			snext.left_hedge = edge_from_vtx_left
			new_arc.right_hedge = edge_to_fcs_right
			pass
		
		# Add to tree
		if self.right == null:	 self.add_rightmost(new_arc)
		else:		self.right = self.right.add_leftmost(new_arc)
		
		# Check for arc triples that can cause an arc to disappear,
		if self.get_focus_angle() < -MACHINE_EPS:
			var circle = Circle.create_from_3_points(
				self.prev.vertex.point, self.vertex.point, self.next.vertex.point)
			var event = CircleEvent.create_circle_event(circle.center.y - circle.radius,
				self, self.vertex, circle)
			event_queue.add(event)
		if new_arc.get_focus_angle() < -MACHINE_EPS:
			var circle = Circle.create_from_3_points(
				new_arc.prev.vertex.point, new_arc.vertex.point, new_arc.next.vertex.point)
			var event = CircleEvent.create_circle_event(circle.center.y - circle.radius,
				new_arc, new_arc.vertex, circle)
			event_queue.add(event)
		
	# focus to the left
	else:
		# Get edge limit through bisector
		var bisector = self.vertex.get_bisector(focus)
		#print(bisector)
		bisector[1] *= HALF_EDGE_DIST
		var end_vertex = Vertex.create_vertex(bisector[0] + bisector[1])
		# Create edges 
		var edge_from_vtx_left = DCEdge.create_dcedge(null, end_vertex, self.vertex.face)
		var edge_to_fcs_right = DCEdge.create_dcedge(end_vertex, null, new_arc.vertex.face)
		edge_from_vtx_left.twin = edge_to_fcs_right
		edge_to_fcs_right.twin = edge_from_vtx_left
		
		# then attach them to the arc edges
		self.left_hedge = edge_from_vtx_left
		new_arc.right_hedge = edge_to_fcs_right
		
		# Check for arc triples that can cause an arc to disappear,
		if self.get_focus_angle() < -MACHINE_EPS:
			var circle = Circle.create_from_3_points(
				self.prev.vertex.point, self.vertex.point, self.next.vertex.point)
			var event = CircleEvent.create_circle_event(circle.center.y - circle.radius,
				self, self.vertex, circle)
			event_queue.add(event)
		
		# Do the same to other side of focus if self.prev exists
		if self.prev != null:
			var sprev = self.prev
			# Get edge limit through bisector
			var bisector2 = new_arc.vertex.get_bisector(sprev)
			bisector2[1] *= HALF_EDGE_DIST
			var end_vertex2 = Vertex.create_vertex(bisector2[0] + bisector2[1])
			# Create edges 
			var edge_to_vtx_right = DCEdge.create_dcedge(end_vertex2, null, sprev.vertex.face)
			var edge_from_fcs_left = DCEdge.create_dcedge(null, end_vertex2, new_arc.vertex.face)
			edge_to_vtx_right.twin = edge_from_fcs_left
			edge_from_fcs_left.twin = edge_to_vtx_right
			
			# then attach them to the arc edges
			sprev.right_hedge = edge_to_vtx_right
			new_arc.left_hedge = edge_from_fcs_left
			pass
		
		# Add to tree
		if self.left == null:	 self.add_leftmost(new_arc)
		else:		self.left = self.left.add_rightmost(new_arc)
		
		# Check for arc triples that can cause an arc to disappear,
		if self.get_focus_angle() < -MACHINE_EPS:
			var circle = Circle.create_from_3_points(
				self.prev.vertex.point, self.vertex.point, self.next.vertex.point)
			var event = CircleEvent.create_circle_event(circle.center.y - circle.radius,
				self, self.vertex, circle)
			event_queue.add(event)
		if new_arc.get_focus_angle() < -MACHINE_EPS:
			var circle = Circle.create_from_3_points(
				new_arc.prev.vertex.point, new_arc.vertex.point, new_arc.next.vertex.point)
			var event = CircleEvent.create_circle_event(circle.center.y - circle.radius,
				new_arc, new_arc.vertex, circle)
			event_queue.add(event)
	
	
	return self._balance()


# + if pt1 is to the left of pt2-pt3, 0 if near, -1 if to the right
static func det2(pt1:Vector2, pt2:Vertex, pt3:Vertex) -> float:
	return ((pt1.x - pt3.point.x) * (pt2.point.y - pt3.point.y)
			- (pt2.point.x - pt3.point.x) * (pt1.y - pt3.point.y))

# + if pt1 is to the left of pt2-pt3, 0 if near, -1 if to the right
func get_focus_angle() -> float:
	if self.prev == null or self.next == null:
		return 1
	return ArcTreeNode.det2(self.prev.vertex.point, self.vertex, self.next.vertex)

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
	
	# Sanity check: focus really is below arc, with the y-intercept below 1e7 over point
	# else just add directly to arc
	var y_at_point = self.get_y_at(focus.point.x, l_y)
	if y_at_point > self.vertex.point.y + 1e7:
		#print("Go into add_arc")
		return self.add_arc(focus)
	
	# found arc, create new arcs as split
	var old_vert = self.vertex
	self.vertex = focus
	var left_arc = ArcTreeNode.create_node(old_vert)
	var right_arc = ArcTreeNode.create_node(old_vert)
	left_arc.event_queue = self.event_queue
	right_arc.event_queue = self.event_queue
	# add created nodes to children, keeping position
	if self.left == null:	self.add_leftmost(left_arc)
	else:		self.left = self.left.add_rightmost(left_arc)
	self.prev = left_arc
	if self.right == null:	self.add_rightmost(right_arc)
	else:		self.right = self.right.add_leftmost(right_arc)
	self.next = right_arc
	
	# Create edges starting at the x of focus and the y at the parabola,
	var start_point = Vector2(focus.point.x, left_arc.get_y_at(focus.point.x, l_y))
	var edge_start = Vertex.create_vertex(start_point)
	var edge_top_vtx_right = DCEdge.create_dcedge(edge_start, null, old_vert.face)
	var edge_top_left_vtx = DCEdge.create_dcedge(null, edge_start, old_vert.face)
	var edge_btm_vtx_right = DCEdge.create_dcedge(edge_start, null, focus.face)
	var edge_btm_left_vtx = DCEdge.create_dcedge(null, edge_start, focus.face)
	# set edges relationship
	edge_top_vtx_right.set_edge_connection(null, edge_top_left_vtx, edge_btm_left_vtx)
	edge_top_left_vtx.set_edge_connection(edge_top_vtx_right, null, edge_btm_vtx_right)
	edge_btm_left_vtx.set_edge_connection(edge_btm_vtx_right, null, edge_top_vtx_right)
	edge_btm_vtx_right.set_edge_connection(null, edge_btm_left_vtx, edge_top_left_vtx)
	
	# then attach them to the arc edges
	left_arc.left_hedge = self.left_hedge
	right_arc.right_hedge = self.right_hedge
	self.left_hedge = edge_btm_left_vtx
	self.right_hedge = edge_btm_vtx_right
	left_arc.right_hedge = edge_top_vtx_right
	right_arc.left_hedge = edge_top_left_vtx
	
	# Check for arc triples that can cause an arc to disappear,
	# disappear candidates: left_arc, right_arc
	# Check by using foci angles
	#print("Left arc angle is ", left_arc.get_focus_angle())
	if left_arc.get_focus_angle() < -MACHINE_EPS:
		var circle = Circle.create_from_3_points(
			left_arc.prev.vertex.point, left_arc.vertex.point, left_arc.next.vertex.point)
		var event = CircleEvent.create_circle_event(circle.center.y - circle.radius,
			left_arc, left_arc.vertex, circle)
		#print(str(left_arc.vertex), ":: arc circle event at circle=", circle, ", y=", event.y)
		event_queue.add(event)
	#print("Right arc angle is ", right_arc.get_focus_angle())
	if right_arc.get_focus_angle() < -MACHINE_EPS:
		var circle = Circle.create_from_3_points(
			right_arc.prev.vertex.point, right_arc.vertex.point, right_arc.next.vertex.point)
		var event = CircleEvent.create_circle_event(circle.center.y - circle.radius,
			right_arc, right_arc.vertex, circle)
		#print(str(right_arc.vertex), ":: arc circle event at circle=", circle, ", y=", event.y)
		event_queue.add(event)
	
	return self._balance()

func add_rightmost(arc:ArcTreeNode) -> ArcTreeNode:
	#print("add_rightmost:: ", self.vertex, "; ", arc.vertex)
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
	#print("add_leftmost:: ", self.vertex, "; ", arc.vertex)
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
	to_delete.is_deleted = true
	# handle edges first
	var end_pos = Vertex.create_vertex(to_delete.get_bounds(l_y)[0])
	#print(end_pos)
	# complete the half edges
	to_delete.left_hedge.start = end_pos
	to_delete.right_hedge.end = end_pos
	to_delete.left_hedge.twin.end = end_pos
	to_delete.right_hedge.twin.start = end_pos
	to_delete.left_hedge.prev = to_delete.right_hedge
	to_delete.right_hedge.next = to_delete.left_hedge
	# add previous complete edges to vertex faces
	to_delete.vertex.face.edge_list.append(to_delete.left_hedge)
	to_delete.vertex.face.edge_list.append(to_delete.right_hedge)
	to_delete.prev.vertex.face.edge_list.append(to_delete.left_hedge.twin)
	to_delete.next.vertex.face.edge_list.append(to_delete.right_hedge.twin)
	
	# create new edges to put to prev.r and next.l
	var edge_to_prev_right = DCEdge.create_dcedge(end_pos, null, to_delete.prev.vertex.face)
	var edge_to_next_left = DCEdge.create_dcedge(null, end_pos, to_delete.next.vertex.face)
	#to_delete.prev.vertex.face.edge_list.append(edge_to_prev_right)
	#to_delete.next.vertex.face.edge_list.append(edge_to_next_left)
	edge_to_prev_right.set_edge_connection(null, to_delete.prev.right_hedge, edge_to_next_left)
	edge_to_next_left.set_edge_connection(to_delete.next.left_hedge, null, edge_to_prev_right)
	to_delete.prev.right_hedge.next = edge_to_prev_right
	to_delete.next.left_hedge.prev = edge_to_next_left
	to_delete.prev.right_hedge = edge_to_prev_right
	to_delete.next.left_hedge = edge_to_next_left
	
	# add arcs that change positions (prev until leaf)
	var to_change:Array[ArcTreeNode] = [to_delete]
	while not to_change[-1].is_leaf() and to_change[-1].prev != null:
		to_change.append(to_change[-1].prev)
	# if no leaf found go next until leaf instead
	if not to_change[-1].is_leaf():
		to_change = [to_delete]
		while not to_change[-1].is_leaf() and to_change[-1].next != null:
			to_change.append(to_change[-1].next)
	
	
	to_change.reverse()
	
	# keep parent for later check
	var tmp_par = to_change[0].parent
	
	# detach first node (leaf) from tree
	tmp_par.replace_child(to_change[0], null)
	#assert(to_change[0].left == null and to_change[0].right == null, "WHY DO YOU HAVE CHILDREN?????????")
	tmp_par.update_height()
	to_change[0].parent = null
	
	# reorder tree to remove `to_delete` from tree
	for idx in range(len(to_change)-1):
		# to_change[idx] has no effective connections, and will replace to_change[idx+1]
		var change_prev = to_change[idx]
		var change_next = to_change[idx+1]
		change_prev.parent = change_next.parent
		if change_prev.parent != null:
			change_prev.parent.replace_child(change_next, change_prev)
		change_next.parent = null
		
		change_prev.left = change_next.left
		if change_prev.left != null:
			change_prev.left.parent = change_prev
		change_next.left = null
		
		change_prev.right = change_next.right
		if change_prev.right != null:
			change_prev.right.parent = change_prev
		change_next.right = null
		
		change_prev.update_height()
	
	# remove `to_delete` from "linked list"
	var check_prev:ArcTreeNode = null
	if to_delete.prev != null:
		check_prev = to_delete.prev
		to_delete.prev.next = to_delete.next
	var check_next:ArcTreeNode = null	
	if to_delete.next != null:
		check_next = to_delete.next
		to_delete.next.prev = to_delete.prev
	
	# Check newly created circle events (prev and next)
	if check_prev != null and check_prev.get_focus_angle() < -MACHINE_EPS:
		var circle = Circle.create_from_3_points(
			check_prev.prev.vertex.point, check_prev.vertex.point, check_prev.next.vertex.point)
		var event = CircleEvent.create_circle_event(circle.center.y - circle.radius,
					check_prev, check_prev.vertex, circle)
		to_delete.event_queue.add(event)
	if check_next != null and check_next.get_focus_angle() < -MACHINE_EPS:
		var circle = Circle.create_from_3_points(
			check_next.prev.vertex.point, check_next.vertex.point, check_next.next.vertex.point)
		var event = CircleEvent.create_circle_event(circle.center.y - circle.radius,
					check_next, check_next.vertex, circle)
		to_delete.event_queue.add(event)
	
	# "delete" the arc
	to_delete.remove_all_references()
	# balance up until parent
	if tmp_par == null:
		return null
	if tmp_par == to_delete:
		to_change[0].update_height()
		if to_change[0].parent == null:
			return to_change[0]._balance()
		return to_change[0].parent._balance_up(to_change[0])
	
	tmp_par.update_height()
	if tmp_par.parent == null:
		return tmp_par._balance()
	return tmp_par.parent._balance_up(tmp_par)
	


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
	#print(self)
	self.update_height()
	var hd = self.height_difference()
	if hd > 1:
		hd = self.left.height_difference()
		if hd >= 0:	return self._single_rotate_right()
		else:		return self._rotate_LR()
		#print("changed===\n", self)
	elif hd < -1:
		hd = self.right.height_difference()
		if hd <= 0:	return self._single_rotate_left()
		else:		return self._rotate_RL()
	self.update_height()
	return self


func _single_rotate_left() -> ArcTreeNode:
	var tmp = self.right
	if self.parent != null:
		self.parent.replace_child(self, tmp)
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
	if self.parent != null:
		self.parent.replace_child(self, tmp)
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
