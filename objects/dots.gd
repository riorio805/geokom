extends Node2D

const dot_scene = preload("res://objects/dot.tscn")

var dot_nodes:Array[Sprite2D] = []
var dragged_index:int
var drag_offset:Vector2

var updated:bool

func _process(_delta) -> void:
	# debug
	if Input.is_action_pressed("debug") and Input.is_action_just_pressed("debug_print"):
		print(dot_nodes)

## Consumes an update check if dots has been updated since last time (true if update, false if no update)
func consume_update() -> bool:
	var tmp = updated
	updated = false
	return tmp

## Starts a dot drag with the dot at pos, failing if no dot exists or already in a drag
func start_drag_from(pos:Vector2) -> bool:
	# stop if already drag
	if dragged_index != -1:
		return false
	# get new drag
	dragged_index = get_dot_at(pos)
	if dragged_index == -1:
		return false
	
	drag_offset = dot_nodes[dragged_index].position - pos
	return true

func is_dragging() -> bool:
	return dragged_index != -1

## Move dragged dot to original location + rel, only works if already dragging
func move_dragged_dot(to:Vector2) -> void:
	if dragged_index != -1:
		dot_nodes[dragged_index].position = to + drag_offset
		updated = true

## Releases drag, only works if already dragging
func release_drag() -> void:
	dragged_index = -1

## Tries to create a dot at position pos, failing if a dot already exist at that pos.
func create_at(pos:Vector2) -> bool:
	# Check if dot exist at pos
	if get_dot_at(pos) != -1:
		return false
	# No dots at pos, create new
	var new_dot = dot_scene.instantiate()
	dot_nodes.append(new_dot)
	new_dot.position = pos
	add_child(new_dot, true)
	updated = true
	return true

## Tries to delete a dot at position pos, returning true if deleted and false otherwise.
func delete_at(pos:Vector2) -> bool:
	var index = get_dot_at(pos)
	if index == -1:
		return false
	var dot = dot_nodes.pop_at(index)
	dot.queue_free()
	updated = true
	return true

## Get position of dot containing pos, earliest occurence (-1 if no dot)
func get_dot_at(pos:Vector2) -> int:
	for i in range(len(dot_nodes)-1, -1, -1):
		var dot = dot_nodes[i]
		var bounds = dot.get_rect().abs()
		bounds = dot.transform * bounds
		if bounds.has_point(pos):
			return i
	return -1
