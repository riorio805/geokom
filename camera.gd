extends Camera2D

var is_dragged:bool
var drag_pos:Vector2

func start_drag() -> bool:
	# stop if already drag
	if is_dragged:
		return false
	is_dragged = true
	drag_pos = position
	return true

## Move dragged dot to original location + rel, only works if already dragging
func drag_to(rel:Vector2) -> void:
	if is_dragged:
		position = drag_pos + rel

## Releases drag, only works if already dragging
func release_drag() -> void:
	is_dragged = false

func get_total_transform() -> Transform2D:
	return transform * Transform2D().scaled(zoom).translated(offset).affine_inverse()

func get_camera_rect() -> Rect2:
	var pos = global_position
	var half_size = get_viewport_rect().size
	return Rect2(pos, pos + half_size)
