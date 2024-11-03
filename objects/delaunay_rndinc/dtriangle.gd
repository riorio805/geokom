extends Resource
class_name DTriangle

const EPS = 1e-5

var p1:Vertex # Never is a InfXVertex
var p2:Vertex
var p3:Vertex
# edges opposite the points
var e1:DEdge
var e2:DEdge
var e3:DEdge

var child_tris: Array[DTriangle] = [] # dag implementation

## Automatically creates edges of the triangle
static func init_create_edges(pt1:Vertex, pt2:Vertex, pt3:Vertex) -> DTriangle:
	var out = DTriangle.new()
	out.p1 = pt1
	out.p2 = pt2
	out.p3 = pt3
	out.e1 = DEdge.create_dedge(pt2, pt3, out)
	out.e2 = DEdge.create_dedge(pt3, pt1, out)
	out.e3 = DEdge.create_dedge(pt1, pt2, out)
	return out


static func init_all(
	pt1:Vertex, pt2:Vertex, pt3:Vertex,
	ed1:DEdge, ed2: DEdge, ed3: DEdge) -> DTriangle:
	var out = DTriangle.new()
	out.p1 = pt1
	out.p2 = pt2
	out.p3 = pt3
	out.e1 = ed1
	out.e2 = ed2
	out.e3 = ed3
	return out

static func init() -> DTriangle:
	var out = DTriangle.new()
	return out

func _to_string():
	return "DTriangle: {0} -> {1} -> {2}".format([str(p1), str(p2), str(p3)])


## Returns all edges that are part of the triangulation,
## except the ones connected to an infinite vertex
func get_all_leaf_edges() -> Array[DEdge]:
	var edges = Dictionary()
	var tris:Array[DTriangle] = [self]
	while not tris.is_empty():
		var nxt_tri:DTriangle = tris.pop_front()
		if len(nxt_tri.child_tris) == 0:
			if not nxt_tri.e1.is_infinite():
				edges.get_or_add(nxt_tri.e1, null)
			if not nxt_tri.e2.is_infinite():
				edges.get_or_add(nxt_tri.e2, null)
			if not nxt_tri.e3.is_infinite():
				edges.get_or_add(nxt_tri.e3, null)
		else:
			for e in nxt_tri.child_tris:
				tris.append(e)
	var out:Array[DEdge] = []
	for e in edges.keys():
		out.append(e)
	return out



func split_at(vtx:Vertex):
	var leaf = self.get_leaf_containing(vtx.point)
	#print("split_at,is_in: ", leaf)
	# Case 1: point is inside triangle
	if leaf is DTriangle:
		# Create edges from vtx to triangle vertices
		var e_vt_p1 = DEdge.create_dedge(vtx, leaf.p1)
		var e_vt_p2 = DEdge.create_dedge(vtx, leaf.p2)
		var e_vt_p3 = DEdge.create_dedge(vtx, leaf.p3)
		var t1 = DTriangle.init_all(vtx, leaf.p1, leaf.p2, leaf.e3, e_vt_p2, e_vt_p1)
		var t2 = DTriangle.init_all(vtx, leaf.p2, leaf.p3, leaf.e1, e_vt_p3, e_vt_p2)
		var t3 = DTriangle.init_all(vtx, leaf.p3, leaf.p1, leaf.e2, e_vt_p1, e_vt_p3)
		leaf.e1.replace_triangle(leaf, t2)
		leaf.e2.replace_triangle(leaf, t3)
		leaf.e3.replace_triangle(leaf, t1)
		e_vt_p1.set_triangles(t3, t1)
		e_vt_p2.set_triangles(t1, t2)
		e_vt_p3.set_triangles(t2, t3)
		# Legalize triangle edges
		var children:Array[DTriangle] = [t1, t2, t3]
		leaf.child_tris = children
		t1.legalize_edge(vtx)
		t2.legalize_edge(vtx)
		t3.legalize_edge(vtx)
	# Case 2: point is on edge
	elif leaf is DEdge:
		var vei = leaf.start
		var vej = leaf.end
		var vk = leaf.t1.opposite_vertex(leaf)
		var vl = leaf.t2.opposite_vertex(leaf)
		var e_vt_vei = DEdge.create_dedge(vtx, vei)
		var e_vt_vej = DEdge.create_dedge(vtx, vej)
		var e_vt_vk = DEdge.create_dedge(vtx, vk)
		var e_vt_vl = DEdge.create_dedge(vtx, vl)
		var t1 = DTriangle.init_all(
			vtx, vk, vei, leaf.t1.opposite_edge(vej), e_vt_vei, e_vt_vk)
		var t2 = DTriangle.init_all(
			vtx, vej, vk, leaf.t1.opposite_edge(vei), e_vt_vk, e_vt_vej)
		var t3 = DTriangle.init_all(
			vtx, vei, vl, leaf.t2.opposite_edge(vej), e_vt_vl, e_vt_vei)
		var t4 = DTriangle.init_all(
			vtx, vl, vej, leaf.t2.opposite_edge(vei), e_vt_vej, e_vt_vl)
		leaf.t1.opposite_edge(vej).replace_triangle(leaf.t1, t1)
		leaf.t1.opposite_edge(vei).replace_triangle(leaf.t1, t2)
		leaf.t2.opposite_edge(vej).replace_triangle(leaf.t2, t3)
		leaf.t2.opposite_edge(vei).replace_triangle(leaf.t2, t4)
		e_vt_vei.set_triangles(t1, t3)
		e_vt_vej.set_triangles(t4, t2)
		e_vt_vk.set_triangles(t2, t1)
		e_vt_vl.set_triangles(t3, t4)
		# Legalize triangle edges
		var ch1:Array[DTriangle] = [t1, t2]
		var ch2:Array[DTriangle] = [t3, t4]
		leaf.t1.child_tris = ch1
		leaf.t2.child_tris = ch2
		t1.legalize_edge(vtx)
		t2.legalize_edge(vtx)
		t3.legalize_edge(vtx)
		t4.legalize_edge(vtx)
		pass


# + if pt1 is to the left of pt2-pt3, 0 if near, -1 if to the right
static func det2(pt1:Vector2, pt2:Vertex, pt3:Vertex) -> float:
	if pt2 is InfXVertex and pt3 is InfXVertex:
		# : pt2pt3 -> p-1p-2
		# assume pt1 is always in the triangle p0p-1p-2
		assert(pt2.direction != pt3.direction)
		if pt2.direction == InfXVertex.Direction.X_PLUS:
			return -1
		elif pt2.direction == InfXVertex.Direction.X_MIN:
			return 1
	elif pt2 is InfXVertex and not pt3 is InfXVertex:
		if pt3.less_than(pt1):
			return -1 * pt2.direction
		elif pt3.point.is_equal_approx(pt1):
			return 0
		else:
			return 1 * pt2.direction
	elif not pt2 is InfXVertex and pt3 is InfXVertex:
		if pt2.less_than(pt1):
			return 1 * pt3.direction
		elif pt2.point.is_equal_approx(pt1):
			return 0
		else:
			return -1 * pt3.direction
	
	return ((pt1.x - pt3.point.x) * (pt2.point.y - pt3.point.y)
			- (pt2.point.x - pt3.point.x) * (pt1.y - pt3.point.y))

## Checks whether or not the point is inside this triangle.
## Returns 1 if point is in triangle, -1 if point is outside triangle,
## and 0 if point is one of the edges (within EPS).
func is_in(pt:Vector2) -> int:
	# get determinants (sign -> pt side relative to vtx)
	var d1 = DTriangle.det2(pt, p1, p2)
	#print("is_in:: ", pt, "; ", p1, "; ", p2, "; ", d1)
	var d2 = DTriangle.det2(pt, p2, p3)
	#print("is_in:: ",pt, "; ", p2, "; ", p3, "; ", d2)
	var d3 = DTriangle.det2(pt, p3, p1)
	#print("is_in:: ",pt, "; ", p3, "; ", p1, "; ", d3)
	# check on line, left side of vtx, right side (with tolerance EPS as on_line)
	var on_line = (abs(d1) < EPS) or (abs(d2) < EPS) or (abs(d3) < EPS)
	var has_neg = (d1 < -EPS) or (d2 < -EPS) or (d3 < -EPS)
	var has_pos = (d1 > EPS) or (d2 > EPS) or (d3 > EPS)
	
	if on_line:
		if has_neg != has_pos: return 0
	else:
		if not (has_neg and has_pos): return 1
	return -1

## Gets the triangle or edge (if point is on edge within EPS) containing
func get_leaf_containing(pt:Vector2):
	# base case: no child
	if len(child_tris) == 0:
		var check = self.is_in(pt)
		if check == 0:
			# assuming no 2 vertex are the same
			if abs(DTriangle.det2(pt, e1.start, e1.end)) < EPS:
				#print("e1:", e1)
				return e1
			elif abs(DTriangle.det2(pt, e2.start, e2.end)) < EPS:
				#print("e2:", e2)
				return e2
			else:
				#print("e3:", e3)
				return e3
		else:
			return self
	# else check every child
	for tri in child_tris:
		var check = tri.is_in(pt)
		if check == -1:
			#print(pt, " not in ", tri)
			continue
		else:
			#print("go down")
			return tri.get_leaf_containing(pt)
	

func opposite_edge(p:Vertex) -> DEdge:
	if p == p1: return e1
	elif p == p2: return e2
	else: return e3

func opposite_vertex(e:DEdge) -> Vertex:
	if e == e1: return p1
	elif e == e2: return p2
	else: return p3


# delaunay triangulation
func legalize_edge(p_r:Vertex):
	# get edge opposite p_r, then the triangle opposite p_r
	assert(not p_r is InfXVertex)
	#print("Legalize edge opposite {0} in {1}".format([p_r, self]))
	var op_edge = opposite_edge(p_r)
	#print("\t op_edge: {0}".format([op_edge]))
	var op_triangle = op_edge.get_other_triangle(self)
	#print("\t op_triangle: {0}".format([op_triangle]))
	if op_triangle == null:
		# Special case: op_edge = edge of the outer triangle
		return
	var op_vtx = op_triangle.opposite_vertex(op_edge) # pk
	#print("\t op_vtx: {0}".format([op_vtx]))
	var vi = op_edge.start
	var vj = op_edge.end
	#print("\t vi: {0}, vj: {1}".format([vi, vj]))
	
	# Check if edge is illegal
	var illegal:bool
	if op_vtx is InfXVertex or vi is InfXVertex or vj is InfXVertex:
		#print("\t Special case")
		# Special case: all other cases where there is an infinite vertex
		# both vi and vj cannot be InfXVertex, since that is already handled by outer triangle case
		if vi is InfXVertex or vj is InfXVertex:
			illegal = true
			#print("\t -> Infinite edge (vi or vj is infinite)")
			
		elif (op_vtx is InfXVertex and not (vi is InfXVertex or vj is InfXVertex)):
			#print("\t -> not infinite edge (vi and vj is finite, op_vtx is infinite)")
			illegal = false
		else:
			#print("\t -> multiple infinite")
			var vinf:InfXVertex = vi if vi is InfXVertex else vj
			illegal = not (vinf.direction == InfXVertex.Direction.X_PLUS and op_vtx.direction == InfXVertex.Direction.X_MIN)
	else:
		#print("\t Normal case")
		# Normal case: none of the vertices is infinite
		# with the circle passing through all points in self
		# use inscribed angle theorem to find if the other point (p_l) is in or out of this circle
		var theta = (deg_to_rad(180)
			- abs(		 (vi.point - p_r.point)
				.angle_to(vj.point - p_r.point)))
		var theta2 = abs((vj.point - op_vtx.point)
				.angle_to(vi.point - op_vtx.point))
		#print("\t angles: ", theta, " ", theta2)
		illegal = theta2 > theta
	
	# final check: flip would create inside-out triangle -> always not illegal
	if illegal:
		#print("\t Check inside-out")
		var d1 = DTriangle.det2(p_r.point, op_vtx, vi)
		var d2 = DTriangle.det2(p_r.point, op_vtx, vj)
		#print("\t -> Calc; d1:{0}, d2:{1}".format([d1, d2]))
		if (sign(d1) * sign(d2)) <= 0:
			#print("\t -> Would not create inside out triangle ")
			illegal = true
		else:
			#print("\t -> Would create inside out triangle")
			illegal = false
	
	#print("\t Illegal: ", illegal)
	if not illegal:
		return
	
	# if illegal, flip edge, then legalize resulting triangles
	var e_pr_vo = DEdge.create_dedge(p_r, op_vtx)
	var e_pr_vi = self.opposite_edge(vj)
	var e_vi_vo = op_triangle.opposite_edge(vj)
	var e_pr_vj = self.opposite_edge(vi)
	var e_vj_vo = op_triangle.opposite_edge(vi)
	
	var t1 = DTriangle.init_all(
		p_r, vi, op_vtx, e_vi_vo, e_pr_vo, e_pr_vi)
	var t2 = DTriangle.init_all(
		p_r, op_vtx, vj, e_vj_vo, e_pr_vj, e_pr_vo)
	e_pr_vo.set_triangles(t1, t2)
	
	var children:Array[DTriangle] = [t1, t2]
	self.child_tris = children
	op_triangle.child_tris = children
	
	e_pr_vi.replace_triangle(self, t1)
	e_vi_vo.replace_triangle(op_triangle, t1)
	e_pr_vj.replace_triangle(self, t2)
	e_vj_vo.replace_triangle(op_triangle, t2)
	
	#print("\t Fixed: ")
	#print("\t t1: ", t1)
	#print("\t t2: ", t2)
	
	t1.legalize_edge(p_r)
	t2.legalize_edge(p_r)
