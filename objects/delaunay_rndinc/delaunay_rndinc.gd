extends Node2D

const range_mod = 1

# :Array[DEdge]
var draw_edges:Array[DEdge] = []

var color = Color.CADET_BLUE
var line_width = 10

func _draw() -> void:
	for edge in draw_edges:
		draw_line(edge.start.point, edge.end.point, color, line_width, true)
		pass

func _process(_delta) -> void:
	if Input.is_action_just_pressed("debug"):
		#bottom_use_top_color = not bottom_use_top_color
		queue_redraw()


func update_with_points(nodes:Array):
	#print("========= UPDATE =========")
	if len(nodes) == 0:
		draw_edges = []
		queue_redraw()
		return
	var points = nodes.map(func (p): return p.position)
	points = _array_unique(points)
	var vertices:Array[Vertex] = []
	points.map(func (p): vertices.append(Vertex.create_vertex(p)))
	
	var min_vtx = Vertex.get_min_vertex(vertices)
	var max_vtx = Vertex.get_max_vertex(vertices)
	var yrange = (max_vtx.point.y - min_vtx.point.y) * range_mod + 50
	var pn1 = InfXVertex.create_infxvertex(
		min_vtx.point.y - yrange, InfXVertex.Direction.X_PLUS)
	pn1.point = Vector2(3e2, pn1.y)
	var pn2 = InfXVertex.create_infxvertex(
		max_vtx.point.y + yrange, InfXVertex.Direction.X_MIN)
	pn2.point = Vector2(-3e4, pn2.y)
	
	var root_tri = DTriangle.init_create_edges(max_vtx, pn1, pn2)
	#print("P-1: ", pn1)
	#print("P-2: ", pn2)
	#print("FIRST POINT: ", max_vtx)
	
	for vtx in vertices:
		if vtx != max_vtx:
			#print("NEW POINT: ", vtx)
			root_tri.split_at(vtx)
	
	draw_edges = root_tri.get_all_leaf_edges()
	queue_redraw()


func _array_unique(array: Array) -> Array:
	var unique: Array = []
	for item in array:
		if not unique.has(item):
			unique.append(item)
	return unique
