extends Node2D

class_name VoronoiFredo # untuk access MIN_Y melalui avl_tree

var draw_edges = []
# format elemen: [[Vector2 from, Vector2 to], ...]
var draw_circles = []
# format: [[Vector2 point, float radius], ...]
var draw_sketch_edges = [] # untuk debug circle event

# Draw settings
const site_event_color = Color.DARK_RED
const circle_event_color = Color.BLUE
const voronoi_color = Color.BLACK
const line_width = 10

# Min heap for storing events
var min_heap = MinHeap.new()

# Bounding box size
var bounding_box:Rect2 = Rect2()
static var MIN_Y = -2000
static var MAX_Y = 2500
static var MIN_X = -2500
static var MAX_X = 2000

# Update bounding box
func update_camera(bounds:Rect2):
	bounding_box = bounds
	MIN_X = bounding_box.position.x
	MAX_X = bounding_box.end.x
	MIN_Y = bounding_box.position.y
	MAX_Y = bounding_box.end.y

func _draw() -> void:
	# draw boundary
	draw_polyline([Vector2(MIN_X, MIN_Y), Vector2(MIN_X, MAX_Y), Vector2(MAX_X, MAX_Y), Vector2(MAX_X, MIN_Y), Vector2(MIN_X, MIN_Y)], voronoi_color, line_width, true)
	
	# draw edges
	for edge in draw_edges:
		draw_polyline(edge, voronoi_color, line_width, true)
	for edge in draw_sketch_edges:
		#edge[0].y = clamp(edge[0].y, -1000, 5000)
		#edge[1].y = clamp(edge[1].y, -1000, 5000)
		
		#draw_line(edge[0], edge[1], line_color, line_width, true)
		#draw_polyline(edge, circle_event_color, line_width, true)
		pass
	
	
	if len(draw_circles) > 0:
		var best_radius = 0
		var circles = []
		for c in draw_circles:
			if c[1] >= best_radius:
				best_radius = c[1]
				circles = [c]
			elif c[1] == best_radius:
				circles.append(c)
		for c in circles:
			draw_circle(c[0], c[1], circle_event_color, false, line_width, true)
		
	#for c in draw_circles:
		#draw_circle(c[0], c[1], circle_event_color, false, line_width/2, true)
		

func _process(_delta) -> void:
	if Input.is_action_pressed("debug") and Input.is_action_just_pressed("debug_color"):
		queue_redraw()

# when points is updated
func update_with_points(nodes:Array):
	# get positions of nodes
	var points := nodes.map(func (p): return p.position)
	points.sort_custom(compare_y)
	
	# add points to min heap
	for i in range(len(points)):
		var new_heap_node = HeapNode.new()
		new_heap_node.priority = points[i].y
		new_heap_node.is_site_event = true
		new_heap_node.idx_point = i
		min_heap.insert(new_heap_node)
	# print(len(points))
	
	# create beachlines (avl tree)
	var beachlines := AVLTreeFredo.new()
	
	# connect singals
	beachlines.add_circle_event.connect(add_circle_event)
	beachlines.add_edge.connect(add_edge)
	beachlines.add_circle.connect(add_circle)
	
	# create fresh edges to draw
	draw_edges = []
	draw_sketch_edges = []
	draw_circles = []
	queue_redraw()
	
	# pop until heap is empty
	while !min_heap.is_empty():
		var heap_node : HeapNode = min_heap.pop()
		
		if heap_node.is_site_event:
			# if site event
			print("Site event")
			
			# insert the new site into beachlines
			var p = points[heap_node.idx_point]
			beachlines.site_event(p, heap_node.priority)
			
		else:
			# if circle event
			print("Circle event")
			
			# draw line
			draw_sketch_edges.append([Vector2(MIN_X, heap_node.priority), Vector2(MAX_X, heap_node.priority)])
			beachlines.circle_event(heap_node.left_focus, heap_node.middle_node, heap_node.right_focus, heap_node.priority, heap_node.intersection_point)
			
			
		#beachlines.debug()
		#beachlines.debug2(heap_node.priority)
		
	# min heap habis tapi heap masih sisa beachlines
	var tmp = beachlines.root
	if tmp != null:
		
		# start form leftmost
		while (tmp.prev != null):
			tmp = tmp.prev
		
		# handle each unfinished edge
		while (tmp.next != null):
			
			var start = tmp.right_edge_start
			var dir = tmp.right_edge_direction
			if start.y < MIN_Y:
				start.x += (start.y-MIN_Y) / tan(dir)
				start.y = MIN_Y
			
			add_edge(start, start + 10000 * Vector2(cos(dir), -sin(dir)))
			tmp = tmp.next
	
	queue_redraw()
	print("- - - - DONE - - - -")

# add circle_event into beachlines, this function is called by beachlines itself
func add_circle_event(y_sweepline, middle_arc:AVLNode, intersection_point:Vector2):
	print("- add circle event")
	
	var circle_event = HeapNode.new()
	
	circle_event.priority = y_sweepline
	circle_event.is_site_event = false
	circle_event.left_focus = middle_arc.prev.arc_focus
	circle_event.middle_node = middle_arc
	circle_event.right_focus = middle_arc.next.arc_focus
	circle_event.intersection_point = intersection_point
	
	min_heap.insert(circle_event)

# add edge to draw, this function is called by beachlines
func add_edge(from:Vector2, to:Vector2):
	draw_edges.append([from, to])
	queue_redraw()

# add circle to draw, this function is called by beachlines
func add_circle(center, radius):
	draw_circles.append([center, radius])
	queue_redraw()
	
# sort by y-value ascending
func compare_y(a:Vector2, b:Vector2):
	return a.y<b.y

## Positive if turn left, negative if turn right
func angle_between_points(p1:Vector2, p2:Vector2, p3:Vector2):
	# https://stackoverflow.com/a/2150475
	var a = p2 - p1
	var b = p3 - p2
	return atan2(a.x*b.y - a.y*b.x, a.x*b.x + a.y*b.y)
