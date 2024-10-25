extends Node2D

# :Array[Vector2]
var draw_top_points = []
var draw_bottom_points = []

var top_color = Color.CADET_BLUE
var bottom_color = Color.DARK_RED
var bottom_use_top_color = false
var line_width = 10

func _draw() -> void:
	if bottom_use_top_color:
		draw_polyline(draw_bottom_points, top_color, line_width, true)
	else:
		draw_polyline(draw_bottom_points, bottom_color, line_width, true)
	draw_polyline(draw_top_points, top_color, line_width, true)

func _process(_delta) -> void:
	if Input.is_action_just_pressed("debug"):
		bottom_use_top_color = not bottom_use_top_color
		queue_redraw()

# TODO: Implement Fortune's algorithm
func update_with_points(nodes:Array):
	var points = nodes.map(func (p): return p.position)
	# sort top to bottom, left to right
	points.sort_custom(func (p): return [p.y, p.x])
	# remove duplicate points
	
