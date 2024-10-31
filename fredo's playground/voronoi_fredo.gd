extends Node2D

var draw_edges = []
# format elemen: [[Vector2 from, Vector2 to], ...]
var draw_circles = []
# format: [[Vector2 point, float radius], ...]

const site_event_color = Color.DARK_RED
const circle_event_color = Color.BLUE
const voronoi_color = Color.BLACK
const line_width = 1

var min_heap = MinHeap.new()

func _draw() -> void:
	# draw edges
	for edge in draw_edges:
		#draw_line(edge[0], edge[1], line_color, line_width, true)
		draw_polyline(edge, voronoi_color, line_width, true)
	for c in draw_circles:
		#draw_circle(c[0], c[1], circle_event_color, false, line_width, true)
		pass
	
	print(draw_edges)
		

func _process(_delta) -> void:
	if Input.is_action_pressed("debug") and Input.is_action_just_pressed("debug_color"):
		pass
		queue_redraw()

func update_with_points(nodes:Array):
	# get positions of nodes
	var points := nodes.map(func (p): return p.position)
	points.sort_custom(compare_y)
	
	# add points to min heap
	for i in range(len(points)):
		min_heap.insert(HeapNode.new(points[i].y, true, i))
	# print(len(points))
	
	
	var beachlines := AVLTree.new()
	beachlines.add_circle_event.connect(add_circle_event)
	beachlines.add_edge.connect(add_edge)
	beachlines.add_circle.connect(add_circle)
	
	
	draw_edges = []
	draw_circles = []
	queue_redraw()
	
	while !min_heap.is_empty():
		var heap_node : HeapNode = min_heap.pop()
		
		if heap_node.is_site_event:
			# if site event
			# replace that (arc0) to (arc0,edge1,arc1,edge1,arc0)
			print("Site event")
			
			# make new arc
			var p = points[heap_node.idx_point_or_x_pos]
			
			beachlines.site_event(p, heap_node.priority)
			
		else:
			# if circle event
			# (edge0,arc0,edge0) -> (edge1)
			print("Circle event")
			# add_edge(Vector2(0, heap_node.priority), Vector2(1500, heap_node.priority))
			beachlines.remove(heap_node.idx_point_or_x_pos, heap_node.priority)
		beachlines.debug()
		
	# min heap habis tapi heap masih sisa beachlines
	var tmp = beachlines.root
	while (tmp.prev != null):
		tmp = tmp.prev
	while (tmp.next != null): # karena arc terakhir tidak ada edge dikanannya
		# tmp ini dipake buat draw edge
		add_edge(tmp.right_edge_start, tmp.right_edge_start + 1000 * Vector2(cos(tmp.right_edge_direction), -sin(tmp.right_edge_direction)))
		tmp = tmp.next
	
	#beachlines.free()
	queue_redraw()
	print("- - - - DONE - - - -")

func add_circle_event(y_sweepline, x):
	print("- add circle event")
	min_heap.insert(HeapNode.new(y_sweepline, false, x))

func add_edge(from:Vector2, to:Vector2):
	#print("GAMBAR EDGEE")
	draw_edges.append([from, to])
	queue_redraw()

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
