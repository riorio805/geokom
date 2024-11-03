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
			#if not nxt_tri.e1.is_infinite():
				edges.get_or_add(nxt_tri.e1, null)
			#if not nxt_tri.e2.is_infinite():
				edges.get_or_add(nxt_tri.e2, null)
			#if not nxt_tri.e3.is_infinite():
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
	print("is_in: ", leaf)
	# Case 1: point is inside triangle
	if leaf is DTriangle:
		# Create edges from vtx to triangle vertices
		var e_vt_p1 = DEdge.create_dedge(vtx, leaf.p1)
		var e_vt_p2 = DEdge.create_dedge(vtx, leaf.p2)
		var e_vt_p3 = DEdge.create_dedge(vtx, leaf.p3)
		var t1 = DTriangle.init_all(vtx, leaf.p1, leaf.p2, leaf.e3, e_vt_p2, e_vt_p1)
		var t2 = DTriangle.init_all(vtx, leaf.p2, leaf.p3, leaf.e1, e_vt_p3, e_vt_p2)
		var t3 = DTriangle.init_all(vtx, leaf.p3, leaf.p1, leaf.e2, e_vt_p1, e_vt_p3)
		leaf.e1.replace_triangle(self, t2)
		leaf.e2.replace_triangle(self, t3)
		leaf.e3.replace_triangle(self, t1)
		e_vt_p1.set_triangles(t3, t1)
		e_vt_p2.set_triangles(t1, t2)
		e_vt_p3.set_triangles(t2, t3)
		# Legalize triangle edges
		self.child_tris = [t1, t2, t3]
		t1.legalize_edge(vtx)
		t2.legalize_edge(vtx)
		t3.legalize_edge(vtx)
	# Case 2: point is on edge
	elif leaf is DEdge:
		pass


# + if p1 is to the left of p2-p3, 0 if near, -1 if to the right
static func det2(p1:Vector2, p2:Vertex, p3:Vertex) -> int:
	if p2 is InfXVertex and p3 is InfXVertex:
		# : p2p3 -> p-1p-2
		# assume p1 is always in the triangle p0p-1p-2
		assert(p2.direction != p3.direction)
		if abs(p2.y - p3.y) < EPS: return 0
		elif p2.y > p3.y: return 1
		return -1
	elif p2 is InfXVertex or p3 is InfXVertex:
		# : One of them is infinite (half edge)
		# , compare lexicographically
		var not_inf:Vertex
		var yes_inf:InfXVertex
		var flipped = 1
		if p2 is InfXVertex:
			yes_inf = p2
			not_inf = p3
		else:
			yes_inf = p3
			not_inf = p2
			flipped = -1
		var c = p1.y - not_inf.point.y
		if abs(c) < EPS: return 0
		return sign(c) * yes_inf.direction * flipped
	
	return ((p1.x - p3.point.x) * (p2.point.y - p3.point.y)
			- (p2.point.x - p3.point.x) * (p1.y - p3.point.y))

# + if p1 is to the left of p2-p3, 0 if near, -1 if to the right
static func det(p1:Vector2, p2:Vector2, p3:Vector2) -> int:
	return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)

## Checks whether or not the point is inside this triangle.
## Returns 1 if point is in triangle, -1 if point is outside triangle,
## and 0 if point is one of the edges (within EPS).
func is_in(pt:Vector2) -> int:
	# get determinants (sign -> pt side relative to vtx)
	var d1 = DTriangle.det2(pt, p1, p2)
	var d2 = DTriangle.det2(pt, p2, p3)
	var d3 = DTriangle.det2(pt, p3, p1)
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
	if len(child_tris) == 0: return self
	# else check every child
	for tri in child_tris:
		var check = tri.is_in(pt)
		if check == -1:
			continue
		elif check == 0:
			# assuming no 2 vertex are the same
			if abs(DTriangle.det2(pt, e1.start, e1.end)) < EPS:
				print("e1:", e1)
				return e1
			elif abs(DTriangle.det2(pt, e2.start, e2.end)) < EPS:
				print("e2:", e2)
				return e2
			else:
				print("e3:", e3)
				return e3
			pass
		else:
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
	var op_edge = opposite_edge(p_r)
	var op_triangle = op_edge.get_other_triangle(self)
	if op_triangle == null:
		# Special case: op_edge = edge of the outer triangle
		return
	var op_vtx = op_triangle.opposite_vertex(op_edge) # pk
	var vi = op_edge.start
	var vj = op_edge.end
	
	# Check if edge is illegal
	var illegal:bool
	if op_vtx is InfXVertex or vi is InfXVertex or vj is InfXVertex:
		# Special case: all other cases where there is an infinite vertex
		if not (op_vtx is InfXVertex):
			illegal = true
		elif (op_vtx is InfXVertex and not (vi is InfXVertex or vj is InfXVertex)):
			illegal = false
		else:
			var vinf:InfXVertex = vi if vi is InfXVertex else vj
			illegal = vinf.y > op_vtx.y
	else:
		# Normal case: none of the vertices is infinite
		# with the circle passing through all points in self
		# use inscribed angle theorem to find if the other point (p_l) is in or out of this circle
		var theta = (deg_to_rad(180)
			- abs(		 (op_edge.start.point - p_r.point)
				.angle_to(op_edge.end.point - p_r.point)))
		var theta2 = abs((op_edge.end.point - op_vtx.point)
				.angle_to(op_edge.start.point - op_vtx.point))
		illegal = theta2 < theta
	
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
	
	self.child_tris = [t1, t2]
	op_triangle.child_tris = [t1, t2]
	
	e_pr_vi.replace_triangle(self, t1)
	e_vi_vo.replace_triangle(op_triangle, t1)
	e_pr_vj.replace_triangle(self, t2)
	e_vj_vo.replace_triangle(op_triangle, t2)
	
	t1.legalize_edge(p_r)
	t2.legalize_edge(p_r)
