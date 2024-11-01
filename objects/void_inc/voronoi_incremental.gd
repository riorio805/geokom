## https://github.com/khuyentran1401/Voronoi-diagram
extends Node2D

var bounding_box:Rect2

var faces:Array[Face]

#var top_color = Color.CADET_BLUE
#var bottom_color = Color.DARK_RED
#var bottom_use_top_color = false
#var line_width = 10

func _draw() -> void:
	pass

func _process(_delta) -> void:
	pass

# Use incremental algorithm O(n^2)
func update_with_points(nodes:Array):
	var points = nodes.map(func (p): return p.position)
	# remove duplicate points
	points = _array_unique(points)
	# remove points outside of bounding box
	points.filter(func(p): return bounding_box.has_point(p))
	# sort based on distance
	points.sort_custom(func(p): return p.length_squared())
	
	# map to node points
	points = points.map(func (p): return Vertex.new().initialize(p))
	
	var cur_faces = []
	var p = points.pop_front()
	cur_faces.append(create_bounding_box_face(p))
	
	while len(points) > 0:
		p = points.pop_front()
	













func create_bounding_box_face(v:Vertex) -> Face:
	var f = Face.new()
	# vertex
	var pbl = bounding_box.position
	var pbr = Vector2(bounding_box.end.x, bounding_box.position.y)
	var ptr = bounding_box.end
	var ptl = Vector2(bounding_box.position.x, bounding_box.end.y)
	# edges
	var e1 = DCEdge.init(ptl, ptr, f)
	var e2 = DCEdge.init(ptr, pbr, f)
	var e3 = DCEdge.init(pbr, pbl, f)
	var e4 = DCEdge.init(ptl, ptr, f)
	# connection
	e1.set_edge_connection(e2, e4)
	e2.set_edge_connection(e3, e1)
	e3.set_edge_connection(e4, e2)
	e4.set_edge_connection(e1, e3)
	# face edge list
	f._update_edge_list()
	
	return f


func update_camera(bounds:Rect2):
	bounding_box = bounds

func _array_unique(array: Array) -> Array:
	var unique: Array = []
	for item in array:
		if not unique.has(item):
			unique.append(item)
	return unique
