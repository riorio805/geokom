extends Node2D

const REALLY_HIGH = 1e4
const REALLY_LOW = -1e5
const HALF_EDGE_DIST = 1e7

var bounding_box:Rect2 = Rect2()

var draw_faces:Array[Face] = []

var color = Color.BLACK
var line_width = 5

func _draw() -> void:
	for face in draw_faces:
		#print(face.edge_list)
		for edge in face.edge_list:
			if edge.start != null and edge.end != null:
				draw_line(edge.start.point, edge.end.point, color, line_width)

func _process(_delta) -> void:
	if Input.is_action_just_pressed("debug"):
		queue_redraw()


func update_camera(bounds:Rect2):
	bounding_box = bounds

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
	#print(points)
	# add a point really high up to handle 2 points near the top
	#var first_vertex = Vertex.create_vertex_auto_face(points[0] + Vector2(0, REALLY_HIGH))
	# into vertice with face
	var vertices = points.map(func (p): return Vertex.create_vertex_auto_face(p))
	# create event queue initialize with site events
	var event_queue = PriorityQueue.create_pq(
		vertices.map(func(p): return SiteEvent.create_site_event(p)),
		func(p): return p.value()
	)
	
	var first:SiteEvent = event_queue.remove()
	var root_arc = ArcTreeNode.create_node(first.vertex)
	root_arc.event_queue = event_queue
	
	# main loop
	var last_ly = 0
	while not event_queue.is_empty():
		print(event_queue)
		var nxt_event = event_queue.remove()
		last_ly = nxt_event.y + REALLY_LOW
		if nxt_event is SiteEvent:
			root_arc = root_arc.split_arc(nxt_event.vertex)
		elif nxt_event is CircleEvent:
			if nxt_event.is_valid():
				root_arc = ArcTreeNode.delete_arc(nxt_event.arc, nxt_event.y)
		print(root_arc)
	
	
	# TODO: Change infinite edge handling to extend only (dont use beachline at directrix l_y)
	# handle infinite edges
	var curr = root_arc
	while curr.prev != null: curr = curr.prev
	
	while curr.next != null:
		var bounds = curr.get_bounds(last_ly)
		if curr.left_hedge != null:
			curr.left_hedge.start = Vertex.create_vertex(bounds[0], curr.vertex.face)
		if curr.right_hedge != null:
			curr.right_hedge.end = Vertex.create_vertex(bounds[1], curr.vertex.face)
		curr = curr.next
	
	draw_faces = []
	for vtx in vertices:
		draw_faces.append(vtx.face)
		pass
	
	queue_redraw()

func _array_unique(array: Array) -> Array:
	var unique: Array = []
	for item in array:
		if not unique.has(item):
			unique.append(item)
	return unique
