extends Camera2D

var is_dragged:bool
var drag_pos:Vector2

@export var zoom_base = 1.1
@export var zoom_smoothness = 8

var real_zoom_exp = 0
var zoom_exp = 0
var zoom_exp_min = -15
var zoom_exp_max = 15

func _process(delta):
	# zooming interpolation
	var lerp_weight = clampf(zoom_smoothness * delta, 0, 1)
	real_zoom_exp = lerpf(real_zoom_exp, zoom_exp, lerp_weight)
	var x = pow(zoom_base, real_zoom_exp)
	self.zoom = Vector2(x, x)
	pass

func start_drag() -> bool:
	# stop if already drag
	if is_dragged:
		return false
	is_dragged = true
	drag_pos = position
	return true

## Move camera to original location + rel, only works if already dragging
func drag_to(rel:Vector2) -> void:
	if is_dragged:
		position = drag_pos + rel

## Releases drag, only works if already dragging
func release_drag() -> void:
	is_dragged = false

func get_total_transform() -> Transform2D:
	var center_offset = get_viewport_rect().size/2
	return transform * Transform2D().scaled(zoom).translated(center_offset).translated(offset).affine_inverse()

func get_camera_rect() -> Rect2:
	return get_total_transform() * get_viewport_rect()


## Change the real camera zoom to the power `by` (constant base)
func change_zoom(by:int, point:Vector2=Vector2.ZERO):
	by = clampi(by, zoom_exp_min - zoom_exp, zoom_exp_max - zoom_exp)
	zoom_exp += by
	pass
