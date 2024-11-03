extends Node

func _ready() -> void:
	#print(rad_to_deg(Vector2(0,1).angle_to(Vector2(1,0))))
	var p1 = Vertex.create_vertex(Vector2(0,0))
	var p2 = Vertex.create_vertex(Vector2(0,5))
	var p3 = Vertex.create_vertex(Vector2(-4,0))
	
	
	#print(Vertex.get_max_vertex([p1, p2, p3]))
	#print(Vertex.get_min_vertex([p1, p2, p3]))
	print(InfXVertex.Direction.X_PLUS)
	print(InfXVertex.Direction.X_MIN * sign(-1))
	pass
