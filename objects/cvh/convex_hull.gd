extends Node2D

# :Array[Vector2]
var draw_top_points = []
var draw_bottom_points = []

var top_color = Color.CADET_BLUE
var bottom_color = Color.DARK_RED
var bottom_use_top_color = false
var line_width = 5

func _draw() -> void:
	if len(draw_bottom_points) >= 2:
		if bottom_use_top_color:
			draw_polyline(draw_bottom_points, top_color, line_width, true)
		else:
			draw_polyline(draw_bottom_points, bottom_color, line_width, true)
	if len(draw_top_points) >= 2:
		draw_polyline(draw_top_points, top_color, line_width, true)

func _process(_delta) -> void:
	if Input.is_action_pressed("debug") and Input.is_action_just_pressed("debug_color"):
		bottom_use_top_color = not bottom_use_top_color
		queue_redraw()

func update_with_points(nodes:Array):
	# get positions of nodes
	var points = nodes.map(func (p): return p.position)
	points.sort()
	# Less than 2 points
	if len(points) <= 2:
		draw_top_points = points
		draw_bottom_points = points
		queue_redraw()
		return
	# Top side of chull
	var out_top = [points[0], points[1]]
	for i in range(2, len(points)):
		out_top.append(points[i])
		while (len(out_top) >= 3
			and angle_between_points(out_top[-3], out_top[-2], out_top[-1]) < 0):
			out_top.remove_at(len(out_top)-2)
	# Bottomside of chull
	points.reverse()
	var out_bottom = [points[0], points[1]]
	for i in range(2, len(points)):
		out_bottom.append(points[i])
		while (len(out_bottom) >= 3
			and angle_between_points(out_bottom[-3], out_bottom[-2], out_bottom[-1]) < 0):
			out_bottom.remove_at(len(out_bottom)-2)
	
	draw_top_points = out_top
	draw_bottom_points = out_bottom
	queue_redraw()

## Positive if turn left, negative if turn right
func angle_between_points(p1:Vector2, p2:Vector2, p3:Vector2):
	# https://stackoverflow.com/a/2150475
	var a = p2 - p1
	var b = p3 - p2
	return atan2(a.x*b.y - a.y*b.x, a.x*b.x + a.y*b.y)
