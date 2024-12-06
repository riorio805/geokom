extends Node2D

const REALLY_HIGH = 1e4
const HALF_EDGE_DIST = 2e6

var bounding_box:Rect2 = Rect2()

var draw_faces:Array[Face] = []
var draw_circles:Array[Circle] = []

var color = Color.BLACK
const circle_event_color = Color.BLUE
var line_width = 5

func _draw() -> void:
	for face in draw_faces:
		#print(face.edge_list)
		for edge in face.edge_list:
			if edge.start != null and edge.end != null:
				draw_line(edge.start.point, edge.end.point, color, line_width, true)
	
	for circle in draw_circles:
		draw_circle(circle.center, circle.radius, circle_event_color, false, line_width, true)

func _process(_delta) -> void:
	if Input.is_action_just_pressed("debug"):
		queue_redraw()


func update_camera(bounds:Rect2):
	bounding_box = bounds

func update_with_points(nodes:Array):
	draw_faces = []
	if len(nodes) == 0:
		return
	
	#print("=============================")
	#print("=========== update ==========")
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
	var vertices = points.map(func (p): return Vertex.create_vertex_auto_face(p))
	#print("Points:", vertices)
	# create event queue initialize with site events
	var event_queue = PriorityQueue.create_pq(
		vertices.map(func(p): return SiteEvent.create_site_event(p)),
		func(p): return p.value()
	)
	
	var first:SiteEvent = event_queue.remove()
	#print("first site event: ", first)
	var root_arc = ArcTreeNode.create_node(first.vertex)
	root_arc.event_queue = event_queue
	
	# main loop
	#print(root_arc)
	#print(event_queue.peek())
	var circles:Array[Circle] = []
	while not event_queue.is_empty():
		var nxt_event = event_queue.remove()
		if nxt_event is SiteEvent:
			root_arc = root_arc.split_arc(nxt_event.vertex)
			#print(root_arc)
			#print(event_queue.peek())
		elif nxt_event is CircleEvent:
			if nxt_event.is_valid():
				# Add circle corresponding to this event to the circles
				circles.append(nxt_event.circle)
				root_arc = ArcTreeNode.delete_arc(nxt_event.arc, nxt_event.y)
				#print(root_arc)
				#print(event_queue.peek())
	print(root_arc)
	
	# handle infinite edges by extending using bisector
	var curr = root_arc
	while curr.prev != null: curr = curr.prev
	
	while curr != null:
		if curr.left_hedge != null:
			var direction = curr.prev.vertex.get_bisector(curr.vertex)[1]
			curr.left_hedge.start = Vertex.create_vertex(
				curr.left_hedge.end.point + direction * HALF_EDGE_DIST,
				curr.vertex.face)
			curr.vertex.face.edge_list.append(curr.left_hedge)
		
		if curr.right_hedge != null:
			var direction = curr.vertex.get_bisector(curr.next.vertex)[1]
			curr.right_hedge.end = Vertex.create_vertex(
				curr.right_hedge.start.point + direction * HALF_EDGE_DIST,
				curr.vertex.face)
			curr.vertex.face.edge_list.append(curr.right_hedge)
		curr = curr.next
	
	
	# get faces
	draw_faces = []
	for vtx in vertices:
		draw_faces.append(vtx.face)
		pass
	
	# get circles
	draw_circles = []
	if len(circles) > 0:
		var max_radius = -1
		for c in circles:
			if c.radius > max_radius:
				max_radius = c.radius
		for c in circles:
			if c.radius >= max_radius:
				draw_circles.append(c)
	
	queue_redraw()

func _array_unique(array: Array) -> Array:
	var unique: Array = []
	for item in array:
		if not unique.has(item):
			unique.append(item)
	return unique
