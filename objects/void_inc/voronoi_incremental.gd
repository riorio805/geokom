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
	
	var cur_points = []
	var p = points.pop_front()
	cur_points.append(p)
	
	for i in range(len(points)):
		pass
	













func create_bounding_box_face() -> Face:
	var f = Face.new()
	
	var ptl = bounding_box.position
	var ptr = Vector2(bounding_box.end.x, bounding_box.position.y)
	var pbr = bounding_box.end
	var pbl = Vector2(bounding_box.position.x, bounding_box.end.y)
	
	var e1 = DCEdge.new().initialize(ptl, ptr, f)
	var e2 = DCEdge.new().initialize(ptr, pbr, f)
	var e3 = DCEdge.new().initialize(pbr, pbl, f)
	var e4 = DCEdge.new().initialize(ptl, ptr, f)
	
	return null


func update_camera(bounds:Rect2):
	bounding_box = bounds

func _array_unique(array: Array) -> Array:
	var unique: Array = []
	for item in array:
		if not unique.has(item):
			unique.append(item)
	return unique
