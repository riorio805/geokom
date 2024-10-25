extends Node2D

@onready var dots_node = $Dots
@onready var draw_node = $Draw
@onready var camera = $Camera2D

var mouse_input: Vector2
var mouse_start: Vector2
var mouse_vec: Vector2
var left_pressed: bool
var left_clicked: bool
var right_clicked: bool
var right_pressed: bool

func _process(delta) -> void:
	_handle_mouse_input(delta)
	if dots_node.consume_update():
		if draw_node.has_method("update_camera"):
			draw_node.update_camera(camera.get_camera_rect())
		draw_node.update_with_points(dots_node.dot_nodes)
	
	if Input.is_action_pressed("debug") and Input.is_action_just_pressed("debug_reset"):
		camera.position = Vector2()

func _unhandled_input(event)-> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			left_pressed = event.pressed
			if left_pressed:
				left_clicked = true
			mouse_start = camera.get_total_transform() * event.position
			mouse_vec = Vector2()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			right_pressed = event.pressed
			if right_pressed:
				right_clicked = true
			mouse_start = camera.get_total_transform() * event.position
			mouse_vec = Vector2()
	elif event is InputEventMouseMotion:
		var viewport_transform: Transform2D = get_tree().root.get_final_transform()
		mouse_input += event.xformed_by(viewport_transform).relative

func _handle_mouse_input(_delta) -> void:
	# use mouse input, reset to zero
	mouse_vec += mouse_input
	mouse_input = Vector2.ZERO
	
	if left_pressed:
		var created = false
		if left_clicked:
			created = dots_node.create_at(mouse_start)
			if created: print("Successfully created dot at ", mouse_start)
			else: 		print("Failed to create dot at ", mouse_start)	
		# handle dragging stuff if new dot not create
		if not created:
			if left_clicked:
				dots_node.start_drag_from(mouse_start)
			else:
				dots_node.move_dragged_dot(mouse_vec)
		left_clicked = false
		#print("Dragged from ", mouse_start, " to ", mouse_start + mouse_vec, " for ", left_pressed_time)
	else:
		# handle release
		dots_node.release_drag()
	
	if right_pressed:
		var deleted = false
		if right_clicked:
			deleted = dots_node.delete_at(mouse_start)
			if deleted:
				print("Successfully deleted dot at ", mouse_start)
			else:
				print("Failed to delete dot at ", mouse_start)
		
		if not deleted:
			if right_clicked:
				camera.start_drag()
			else:
				camera.drag_to(-mouse_vec)
		right_clicked = false
	else:
		camera.release_drag()
