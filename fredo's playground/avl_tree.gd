# AVLTree.gd
class_name AVLTreeFredo
const EPS = 2.0

var root: AVLNode = null

signal add_circle_event(y, x)
signal add_edge(from:Vector2, to:Vector2)
signal add_circle(center, radius)

# Helper functions
func _get_height(node: AVLNode) -> int:
	return node.height if node != null else 0

func _update_height(node: AVLNode) -> void:
	node.height = 1 + max(_get_height(node.left), _get_height(node.right))

func _balance_factor(node: AVLNode) -> int:
	return _get_height(node.left) - _get_height(node.right)

# Rotation functions
func _rotate_right(y: AVLNode) -> AVLNode:
	var x = y.left
	var t2 = x.right

	# Perform rotation
	x.right = y
	y.left = t2

	# update parents
	x.parent = y.parent
	y.parent = x
	if t2 != null:
		t2.parent = y

	# Update heights
	_update_height(y)
	_update_height(x)

	return x

func _rotate_left(x: AVLNode) -> AVLNode:
		 #x
	   #/   \
			 #y
		   #/  
		  #t2 
	var y = x.right
	var t2 = y.left

	# Perform rotation
	y.left = x
	x.right = t2
	
	# update parent
	y.parent = x.parent
	x.parent = y
	if t2 != null:
		t2.parent = x
	

	# Update heights
	_update_height(x)
	_update_height(y)

	return y

# Balance function with rotations
func _balance(node: AVLNode) -> AVLNode:
	_update_height(node)

	# Check balance factor and apply rotations
	if _balance_factor(node) > 1:
		# kiri lebih tinggi
		if _balance_factor(node.left) < 0:
			# kiri kanan lebih tinggi dari kiri kiri
			node.left = _rotate_left(node.left)
			node.left.parent = node
		return _rotate_right(node)
		
	elif _balance_factor(node) < -1:
		# kanan lebih tinggi
		if _balance_factor(node.right) > 0:
			node.right = _rotate_right(node.right)
			node.right.parent = node
		return _rotate_left(node)

	return node


func get_half_line_intersection(p1: Vector2, p2: Vector2, theta1: float, theta2: float):
	var d1 = Vector2(cos(theta1), -sin(theta1))
	var d2 = Vector2(cos(theta2), -sin(theta2))
	
	var denom = d1.x * d2.y - d1.y * d2.x
	if abs(denom) < 1e-8:
		print("Paralel")
		return null  # Parallel lines, no intersection
	
	# Menghitung titik potong garis
	var m1 = d1.y / d1.x
	var m2 = d2.y / d2.x
	
	var c1 = p1.y - m1 * p1.x
	var c2 = p2.y - m2 * p2.x
	
	var intersection_x = (c2 - c1) / (m1 - m2)
	var intersection_y = intersection_x * m1 + c1
	var intersection_point = Vector2(intersection_x, intersection_y)
	
	# Memvalidasi apakah titik potong berada di arah yang benar dari kedua garis half-line
	var valid1 = ((intersection_point.x - p1.x)*(d1.x) >= 0) && ((intersection_point.y - p1.y)*(d1.y) >= 0)
	var valid2 = ((intersection_point.x - p2.x)*(d2.x) >= 0) && ((intersection_point.y - p2.y)*(d2.y) >= 0)
	
	if valid1 and valid2:
		print(str(p1) + " (" + str(theta1).substr(0, 4) + ") berpotongan dengan " + str(p2) + " (" + str(theta2).substr(0, 4) + ") di " + str(intersection_point))
		return intersection_point
	else:
		print(str(p1) + " (" + str(theta1).substr(0, 4) + ") tidak berhimpit dengan " + str(p2) + " (" + str(theta2).substr(0, 4) + ")")
		return null

# update edge tepat di kanan arc & cek circle event
func _make_new_edge(node: AVLNode, start_point:Vector2, directrix_y) -> void:
	
	node.right_edge_start = start_point
	#add_circle.emit(node.right_edge_start, 10)
	var teta = atan2(-node.next.arc_focus.y + node.arc_focus.y , node.next.arc_focus.x - node.arc_focus.x)
	node.right_edge_direction = teta - PI/2
	
	if node.prev != null:
		# cek intersection left
		var voronoi_vertex = get_half_line_intersection(node.prev.right_edge_start, node.right_edge_start, node.prev.right_edge_direction, node.right_edge_direction)
		if voronoi_vertex != null:
			add_circle_event.emit(voronoi_vertex.y + voronoi_vertex.distance_to(node.arc_focus), node, voronoi_vertex)
			#add_circle.emit(voronoi_vertex, 10)
			#node.next.ends_in_directrix = voronoi_vertex.y
			add_circle.emit(voronoi_vertex, 10)
			add_circle.emit(voronoi_vertex, voronoi_vertex.distance_to(node.arc_focus))
			
	
	if node.next.next != null:
		# cek intersection right
		var voronoi_vertex = get_half_line_intersection(node.right_edge_start, node.next.right_edge_start, node.right_edge_direction, node.next.right_edge_direction)
		if voronoi_vertex != null:
			add_circle_event.emit(voronoi_vertex.y + voronoi_vertex.distance_to(node.next.arc_focus), node.next, voronoi_vertex)
			#add_circle.emit(voronoi_vertex, 8)
			add_circle.emit(voronoi_vertex, 10)
			add_circle.emit(voronoi_vertex, voronoi_vertex.distance_to(node.arc_focus))
	
# memeriksa edge kiri & kanan apakah berhimpit dengan sampingnya
func _check_circle_event_on_newly_inserted_arc(node: AVLNode, directrix_y) -> void:
	# asumsi edge sudah benar
	
	if node.prev.prev != null:
		# check edge intersection with prev
		var voronoi_vertex = get_half_line_intersection(node.prev.prev.right_edge_start, node.prev.right_edge_start, node.prev.prev.right_edge_direction, node.prev.right_edge_direction)
		if voronoi_vertex != null:
			add_circle_event.emit(voronoi_vertex.y + voronoi_vertex.distance_to(node.prev.arc_focus), node.prev, voronoi_vertex)
			#node.next.ends_in_directrix = voronoi_vertex.y
			add_circle.emit(voronoi_vertex, 10)
			add_circle.emit(voronoi_vertex, voronoi_vertex.distance_to(node.arc_focus))
	
	if node.next.next != null:
		# check edge intersection with next
		var voronoi_vertex = get_half_line_intersection(node.right_edge_start, node.next.right_edge_start, node.right_edge_direction, node.next.right_edge_direction)
		if voronoi_vertex != null:
			add_circle_event.emit(voronoi_vertex.y + voronoi_vertex.distance_to(node.next.arc_focus), node.next, voronoi_vertex)
			#node.prev.ends_in_directrix = voronoi_vertex.y
			add_circle.emit(voronoi_vertex, 10)
			add_circle.emit(voronoi_vertex, voronoi_vertex.distance_to(node.arc_focus))
	
func _insert_di_paling(node: AVLNode, data: Vector2, directrix_y, is_paling_kiri: bool) -> AVLNode:
	if node == null:
		var new_node = AVLNode.new(data)
		return new_node
	
	if is_paling_kiri:
		# insert at left
		node.left = _insert_di_paling(node.left, data, directrix_y, true)
		node.left.parent = node
	else:
		# insert at right
		node.right = _insert_di_paling(node.right, data, directrix_y, false)
		node.right.parent = node

	return _balance(node)

# Apabila menemukan site event
func _site_event(node: AVLNode, data: Vector2, directrix_y) -> AVLNode:
	if node == null:
		#print("new node")
		var new_node = AVLNode.new(data)
		return new_node
	assert(not node.is_deleted)

	var right_x = get_right_breakpoint(node, directrix_y).x
	var left_x = get_left_breakpoint(node, directrix_y).x
	
	#print(left_x, " <> ", right_x)
	
	if data.x < left_x:
		# check site event at left
		var a = _site_event(node.left, data, directrix_y)
		node.left = a
		a.parent = node
			
	elif data.x > right_x:
		# check site event at right
		var b = _site_event(node.right, data, directrix_y)
		node.right = b
		b.parent = node
		
	else:
		# TODO handle breakpoint at inf
		
		# sef method
		var arc_yg_di_split = node.arc_focus
		var arc_yg_di_tengah = data
		
		
		print("arc yang displit adalah " + str(arc_yg_di_split))
		
		# edge case: posisi y nya sama dengan arc_focus yang lain
		#if arc_yg_di_split.y == arc_yg_di_tengah.y:
			#if arc_yg_di_tengah.x > arc_yg_di_split.x:
		# ini nanti saja TODO
		
		if abs(arc_yg_di_tengah.y-arc_yg_di_split.y) < EPS and arc_yg_di_tengah.x == arc_yg_di_split.x:
			# tidak usah insert :)
			return node
		
		elif abs(arc_yg_di_tengah.y-arc_yg_di_split.y) < EPS and arc_yg_di_tengah.x < arc_yg_di_split.x:
			# insert at right saja
			print("insert di right saja")
			var a = insert_at_right(node, arc_yg_di_split, directrix_y)
			a.parent = node.parent
			node = a
			
			# ganti arc_focus di node jadi arc_yg_di_tengah
			node.arc_focus = arc_yg_di_tengah
			
			node.right_edge_start = Vector2((arc_yg_di_tengah.x + arc_yg_di_split.x)/2, VoronoiFredo.MIN_Y)
			#print("woi", node.right_edge_start)
			node.right_edge_direction = PI * 2 * 3 / 4 # bawah
			
		elif abs(arc_yg_di_tengah.y-arc_yg_di_split.y) < EPS and arc_yg_di_tengah.x > arc_yg_di_split.x:
			# insert at left saja
			print("insert di left saja")
			var a = insert_at_left(node, arc_yg_di_split, directrix_y)
			a.parent = node.parent
			node = a
			
			node.arc_focus = arc_yg_di_tengah
			
			node.prev.right_edge_start = Vector2((arc_yg_di_tengah.x + arc_yg_di_split.x)/2, VoronoiFredo.MIN_Y)
			node.prev.right_edge_direction = PI * 2 * 3 / 4 # bawah
			
		else:
			# insert at both
			var a = insert_at_right(node, arc_yg_di_split, directrix_y)
			a.parent = node.parent
			node = a
			
			var b = insert_at_left(node, arc_yg_di_split, directrix_y)
			b.parent = node.parent
			node = b
			
			# change arc_focus in middle
			node.arc_focus = arc_yg_di_tengah
			
			# update edge tepat kiri & tepat kanan
			var start = Vector2(data.x, node.prev.get_y(data.x, directrix_y))
			var teta = atan2(- node.arc_focus.y + node.prev.arc_focus.y , node.arc_focus.x - node.prev.arc_focus.x)
			# print("teta = " + str(teta))
			
			# tepat kiri
			node.prev.right_edge_start = start # node.get_left_breakpoint(directrix_y)
			node.prev.right_edge_direction = teta - PI/2
			
			# tepat kanan
			var arah = Vector2(cos(node.prev.right_edge_direction), -sin(node.prev.right_edge_direction))
			#add_edge.emit(start, start + 300 * arah)
			#add_circle.emit(start, 5)
			#add_edge.emit(start, start - 300 * arah)
			node.right_edge_start = start #node.get_right_breakpoint(directrix_y)
			node.right_edge_direction = teta + PI/2
			
			_check_circle_event_on_newly_inserted_arc(node, directrix_y)
		
	#debug()
		

	return _balance(node)

func insert_at_right(node: AVLNode, arc_focus, directrix_y):
	node.right = _insert_di_paling(node.right, arc_focus, directrix_y, true)
	node.right.parent = node
			
	var new_node_right = _get_min_value_node(node.right)
	
	# update prev/next
	new_node_right.prev = node
	new_node_right.next = node.next
	if node.next != null: node.next.prev = new_node_right
	node.next = new_node_right
	
	
	# update edge kanan kanan (kiri kiri tidak usah karena sudah otomatis)
	var edge_kanan = [node.right_edge_start, node.right_edge_direction]
	node.next.right_edge_start = edge_kanan[0]
	node.next.right_edge_direction = edge_kanan[1]
	
	return create_node_copy(node)
	
func insert_at_left(node: AVLNode, arc_focus, directrix_y):
	node.left = _insert_di_paling(node.left, arc_focus, directrix_y, false)
	if node.left != null:
		node.left.parent = node
			
	var new_node_left = _get_max_value_node(node.left)
	
	# update prev/next
	new_node_left.prev = node.prev
	new_node_left.next = node
	if node.prev != null: node.prev.next = new_node_left
	node.prev = new_node_left
	
	return create_node_copy(node)

func create_node_copy(node: AVLNode):
	
	assert(not node.is_deleted)
	
	# perbaruhi node
	var new_node = AVLNode.new(node.arc_focus)
	new_node.left = node.left
	new_node.right = node.right
	new_node.prev = node.prev
	new_node.next = node.next
	new_node.parent = node.parent
	new_node.height = node.height
	new_node.right_edge_start = node.right_edge_start
	new_node.right_edge_direction = node.right_edge_direction
	new_node.height = node.height
	
	if node.left != null: node.left.parent = new_node
	if node.right != null: node.right.parent = new_node
	if node.prev != null: node.prev.next = new_node
	if node.next != null: node.next.prev = new_node
	if node.parent != null:
		if node.parent.left == node:
			node.parent.left = new_node
		elif node.parent.right == node:
			node.parent.right = new_node
		else:
			assert(false, "this should never happen")
	
	node.is_deleted = true
	
	return new_node
	
	
# Public insert function
func site_event(data: Vector2, directrix_y) -> void:
	root = _site_event(root, data, directrix_y)

func debug2(directrix_y):
	if root == null: return
	
	var tmp = root
	while (tmp.left != null):
		tmp = tmp.left
	var debug2 = ""
	while (tmp != null):
		debug2 += '[' + str(tmp.arc_focus) + '] ' + str(get_right_breakpoint(tmp, directrix_y)) + " "
		tmp = tmp.next
	#print("prev/next: " + debug2)

func debug() -> void:
	if root == null: return
	
	var debug1 = _debug(root)
	print("left/right: " + debug1)
	
	var tmp = root
	while (tmp.left != null):
		tmp = tmp.left
	var debug2 = ""
	while (tmp != null):
		debug2 += str(tmp.arc_focus) + str(tmp.right_edge_direction).substr(0, 4) + " "
		tmp = tmp.next
	print("prev/next: " + debug2)
	
	tmp = root
	while (tmp.next != null):
		tmp = tmp.next
	var debug3 = ""
	while (tmp != null):
		debug3 = str(tmp.arc_focus)+ str(tmp.right_edge_direction).substr(0, 4) + " " + debug3
		tmp = tmp.prev
	print("next/prev: " + debug3)
	
	if debug2 == debug3 and debug1 == debug2:
		print("SAMA")
	else:
		print('TIDAK SAMA')
	
func _debug(node: AVLNode) -> String:
	if node == null: return ""
	return _debug(node.left) + str(node.arc_focus) + str(node.right_edge_direction).substr(0, 4) + " " + _debug(node.right)

func _remove_this_node(node:AVLNode, voronoi_vertex:Vector2):
	
	assert(node.prev != null)
	assert(node.next != null)
	
	#print("deleting arc", node.arc_focus)
	if node.left == null:
		# Node with only right child (or no child at all)
		# update prev & next
		var removed_node = node
		removed_node.prev.next = removed_node.next
		removed_node.next.prev = removed_node.prev
	
		# update tree
		removed_node.is_deleted = true
		if node.right != null: node.right.parent = node.parent
		node = node.right
		
		# close 2 edge
		add_edge.emit(removed_node.prev.right_edge_start, voronoi_vertex)
		add_edge.emit(removed_node.right_edge_start, voronoi_vertex)
		
		# create new edge
		_make_new_edge(removed_node.prev, voronoi_vertex, voronoi_vertex.y)
		
		
	elif node.right == null:
		# Node with only left child
		
		# update prev & next
		var removed_node = node
		removed_node.prev.next = removed_node.next
		removed_node.next.prev = removed_node.prev
		
		# update parent & child
		removed_node.is_deleted = true
		node.left.parent = node.parent
		node = node.left
		
		# close 2 edge
		add_edge.emit(removed_node.prev.right_edge_start, voronoi_vertex)
		add_edge.emit(removed_node.right_edge_start, voronoi_vertex)
		
		# create new edge
		_make_new_edge(removed_node.next.prev, voronoi_vertex, voronoi_vertex.y)
		
	else:
		# node has left & right child
		
		# tmp = node yang dipindahkan jadi root
		var removed_node = node
		var tmp := _get_min_value_node(node.right)
		
		
		tmp.is_deleted = true
		
		# detach from left/right from parent
		if tmp.parent.left == tmp:
			tmp.parent.left = tmp.right
			if tmp.right != null: tmp.right.parent = tmp.parent
		else:
			assert(tmp.parent.right == tmp)
			tmp.parent.right = tmp.right
			if tmp.right != null: tmp.right.parent = tmp.parent
		
		# detach from prev/next
		if tmp.prev != null: tmp.prev.next = tmp.next
		if tmp.next != null: tmp.next.prev = tmp.prev
		
		
		node = create_node_copy(node)
		node.arc_focus = tmp.arc_focus
		node.right_edge_start = tmp.right_edge_start
		node.right_edge_direction = tmp.right_edge_direction
		
		# close 2 edge
		add_edge.emit(removed_node.prev.right_edge_start, voronoi_vertex)
		add_edge.emit(removed_node.right_edge_start, voronoi_vertex)
		
		
		# create new edge
		_make_new_edge(node.prev, voronoi_vertex, voronoi_vertex.y)
		
		
		
	#removed_node.free()

	return _balance(node) if node != null else null


# Helper function to get the minimum value node
func _get_min_value_node(node: AVLNode) -> AVLNode:
	if node.left == null:
		return node
	return _get_min_value_node(node.left)
	
func _get_max_value_node(node: AVLNode) -> AVLNode:
	if node.right == null:
		return node
	return _get_max_value_node(node.right)

	
func remove2(left_focus:Vector2, middle_node:AVLNode, right_focus:Vector2, priority, intersection_point:Vector2):
	
	if (not middle_node.is_deleted) \
		and middle_node.prev.arc_focus == left_focus \
		and middle_node.next.arc_focus == right_focus:
		
		# remove now
		if middle_node.parent == null:
			root = _remove_this_node(middle_node, intersection_point)
			
		elif middle_node.parent.right == middle_node:
			var a = _remove_this_node(middle_node, intersection_point)
			if a != null: a.parent = middle_node.parent
			if middle_node.parent != null: middle_node.parent.right = a
			
		elif middle_node.parent.left == middle_node:
			var a = _remove_this_node(middle_node, intersection_point)
			if a != null: a.parent = middle_node.parent
			if middle_node.parent != null: middle_node.parent.left = a
			
		else:
			assert(false, "this should never happen")

func get_right_breakpoint(node:AVLNode, directrix_y):
	if node.next != null:
		return _get_breakpoint(node.arc_focus, node.next.arc_focus, directrix_y)
	return Vector2(INF, INF)

func get_left_breakpoint(node:AVLNode, directrix_y):
	if node.prev != null:
		#var i = _get_breakpoint(node.arc_focus, node.prev.arc_focus, directrix_y, true)
		#var j = _get_breakpoint(node.prev.arc_focus, node.arc_focus, directrix_y, true)
		#
		#var err_msg = str(_get_breakpoint(node.arc_focus, node.prev.arc_focus, directrix_y, true))\
				#+ str(_get_breakpoint(node.arc_focus, node.prev.arc_focus, directrix_y, false))\
				#+ str(_get_breakpoint(node.prev.arc_focus, node.arc_focus, directrix_y, true))\
				#+ str(_get_breakpoint(node.prev.arc_focus, node.arc_focus, directrix_y, false))
		#assert((i-j).length_squared() < 5, err_msg)
		return _get_breakpoint(node.prev.arc_focus, node.arc_focus, directrix_y)
	return Vector2(-INF, INF)

func _get_breakpoint(p1:Vector2, p2:Vector2, directrix_y):
	#if abs(p1.y - p2.y) < EPS:
	if p1.y == p2.y:
		return Vector2((p1.x+p2.x)/2, VoronoiFredo.MIN_Y)

	p1.y = -p1.y
	p2.y = -p2.y
	directrix_y = -directrix_y
	
	# asumsi parabola terletak pada y yang lebih besar daripada directrix_y
	var pembagi1 = 2.0*(p1.y-directrix_y)
	var pembagi2 = 2.0*(p2.y-directrix_y)
	
	var ans_x
	if pembagi1 == 0:
		ans_x = p1.x
		
	elif pembagi2 == 0:
		ans_x = p2.x
	
	else:
		#var a = 1.0 / pembagi1 - 1.0 / pembagi2
		var a = (pembagi2 - pembagi1)/(pembagi2*pembagi1)
		
		#var b = -2*p1.x/pembagi1 + 2*p2.x/pembagi2
		var b = (-2*p1.x*pembagi2 + 2*p2.x*pembagi1)/(pembagi1*pembagi2)
		
		#var c = (p1.x*p1.x + p1.y*p1.y - directrix_y*directrix_y)/pembagi1 - (p2.x*p2.x + p2.y*p2.y - directrix_y*directrix_y)/pembagi2
		var c = ((p1.x*p1.x + p1.y*p1.y - directrix_y*directrix_y)*pembagi2 - (p2.x*p2.x + p2.y*p2.y - directrix_y*directrix_y)*pembagi1)/(pembagi1*pembagi2)
		
		# Use quadratic formula
		var discriminant = b * b - 4.0 * a * c
		discriminant = max(0.0, discriminant)  # Avoid negative values due to floating point errors

		# Return leftmost intersection point for Fortune's algorithm
		var x1 = (-b - sqrt(discriminant)) / (2.0 * a)
		var x2 = (-b + sqrt(discriminant)) / (2.0 * a)
		#print("pembagi1 ", pembagi1)
		#print("pembagi2 ", pembagi2)
		
		p1.y = -p1.y
		p2.y = -p2.y
		directrix_y = -directrix_y
		

		#var ans_x = min(x1, x2) if take_min else max(x1, x2)
		#var ans_x = (p1.x-p2.x)*(p1.y-directrix_y)/(p2.y-p1.y) + p1.x
		if p1.y > p2.y: # p1 dibawah p2
			ans_x = max(x1, x2)
			pass
		else:
			ans_x = min(x1, x2)
			pass
		#var dydx = (ans_x - p1.x)/(p1.x-directrix_y)
		
		#ans_x += dydx
		
	var ans_y
	if p1.y != directrix_y:
		ans_y = (pow(ans_x,2) - 2*p1.x*ans_x + p1.x*p1.x + p1.y*p1.y - directrix_y*directrix_y)/pembagi1
	else:
		ans_y = (pow(ans_x,2) - 2*p2.x*ans_x + p2.x*p2.x + p2.y*p2.y - directrix_y*directrix_y)/pembagi2
	
	if ans_y < VoronoiFredo.MIN_Y:
		# TODO
		pass

	return Vector2(ans_x, ans_y)
	
