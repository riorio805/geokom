extends Node2D

# 
var draw_faces:Array[Face] = []

var color = Color.BLACK
var line_width = 5

func _draw() -> void:
	for face in draw_faces:
		print(face.edge_list)
		for edge in face.edge_list:
			if edge.start != null and edge.end != null:
				draw_line(edge.start.point, edge.end.point, color, line_width)

func _process(_delta) -> void:
	if Input.is_action_just_pressed("debug"):
		queue_redraw()



func update_with_points(nodes:Array):
	draw_faces = []
	if len(nodes) == 0:
		return
	
	print("=============================")
	print("=========== update ==========")
	var points = nodes.map(func (p): return p.position)
	# remove duplicate points
	points = _array_unique(points)
	# sort top to bottom, left to right
	points.sort_custom(func (a,b):
		if a.y > b.y: return true
		if a.y < b.y: return false
		return a.x > b.x
	)
	print(points)
	
	queue_redraw()

func _array_unique(array: Array) -> Array:
	var unique: Array = []
	for item in array:
		if not unique.has(item):
			unique.append(item)
	return unique
