extends Node2D

@export var dots_node:Node2D
@export var draw_node:Node2D

@onready var camera = $Camera2D
@onready var import_button = $CanvasLayer/ImportPoints

var mouse_input: Vector2
var mouse_start: Vector2
var mouse_vec: Vector2
var mouse_pos: Vector2
var left_pressed: bool
var left_clicked: bool
var right_clicked: bool
var right_pressed: bool
var zoom_delta:int


func _process(delta) -> void:
	mouse_pos = camera.get_total_transform() * get_viewport().get_mouse_position()
	_handle_mouse_input(delta)
	
	if dots_node.consume_update():
		if draw_node.has_method("update_camera"):
			draw_node.update_camera(camera.get_camera_rect())
		draw_node.update_with_points(dots_node.dot_nodes)
	
	if Input.is_action_pressed("debug"):
		print("mouse at  ", mouse_pos)
		pass
	
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
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_delta += 1
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_delta -= 1
	elif event is InputEventMouseMotion:
		var viewport_transform: Transform2D = camera.get_total_transform()
		mouse_input += event.xformed_by(viewport_transform).relative

func _handle_mouse_input(_delta) -> void:
	# use mouse input, reset to zero
	mouse_vec += mouse_input
	mouse_input = Vector2.ZERO
	
	# zooming
	if zoom_delta != 0:
		camera.change_zoom(zoom_delta)
		zoom_delta = 0
	
	if left_pressed:
		var created = false
		if left_clicked:
			created = dots_node.create_at(mouse_start)
			if created: print("Successfully created dot at ", mouse_start)
			else: 		print("Failed to create dot at ", mouse_start)	
		# handle dragging stuff if new dot not created
		if not created:
			if left_clicked:
				dots_node.start_drag_from(mouse_start)
			else:
				dots_node.move_dragged_dot(mouse_pos)
		left_clicked = false
	else:
		# handle release
		dots_node.release_drag()
	
	if right_pressed:
		var deleted = false
		if right_clicked and not dots_node.is_dragging():
			deleted = dots_node.delete_at(mouse_start)
			#if deleted:
				#print("Successfully deleted dot at ", mouse_start)
			#else:
				#print("Failed to delete dot at ", mouse_start)
		if not deleted:
			if right_clicked:
				camera.start_drag()
			else:
				camera.drag_to(-mouse_vec)
		right_clicked = false
	else:
		camera.release_drag()


func _on_import_points_pressed():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.use_native_dialog = true
	file_dialog.file_selected.connect(import_points)
	
	add_child(file_dialog)
	file_dialog.popup_centered()
	file_dialog.grab_focus()
	remove_child(file_dialog)

func import_points(path:String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	var points = PackedVector2Array()
	while not file.eof_reached():
		var line = file.get_csv_line()
		if len(line) != 2: return
		if not (line[0].is_valid_float() and line[1].is_valid_float()): return
		points.append(Vector2(float(line[0]), float(line[1])))
	
	dots_node.remove_all_dots()
	dots_node.create_dots(points)
