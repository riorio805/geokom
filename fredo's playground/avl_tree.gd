# AVLTree.gd
class_name AVLTree

const EPS = 0.2
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

	# Update heights
	_update_height(y)
	_update_height(x)

	# Update successor and predecessor pointers
	#y.predecessor = x
	#x.successor = y
	#if t2 != null:
		#t2.predecessor = y
		#y.successor = t2

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
	

	# Update heights
	_update_height(x)
	_update_height(y)

	# Update successor and predecessor pointers
	#x.successor = y
	#y.predecessor = x
	#if t2 != null:
		#t2.successor = x
		#x.predecessor = t2

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
		return _rotate_right(node)
	elif _balance_factor(node) < -1:
		# kanan lebih tinggi
		if _balance_factor(node.right) > 0:
			node.right = _rotate_right(node.right)
		return _rotate_left(node)

	return node


func get_half_line_intersection(p1: Vector2, p2: Vector2, theta1: float, theta2: float):
	#p1.y = -p1.y
	#p2.y = -p2.y
	var d1 = Vector2(cos(theta1), -sin(theta1))
	var d2 = Vector2(cos(theta2), -sin(theta2))
	
	var denom = d1.x * d2.y - d1.y * d2.x
	if denom == 0:
		print("paralel")
		return null  # Parallel lines, no intersection
	
	
	var m1 = d1.y/d1.x
	var m2 = d2.y/d2.x
	
	var c1 = p1.y - m1 * p1.x
	var c2 = p2.y - m2 * p2.x
	
	var intersection_x = (c2 - c1)/(m1 - m2)
	
	
	var valid1 = (intersection_x > p1.x) == (d1.x>0)
	var valid2 = (intersection_x > p2.x) == (d2.x>0)

	if valid1 and valid2:
		#p1.y = -p1.y
		#p2.y = -p2.y
		
		var ans = Vector2(intersection_x, intersection_x*m1+c1)
		print(str(p1) + str(theta1).substr(0, 4) + " berpotongan dengan " + str(p2) + str(theta2).substr(0, 4) + " di " + str(ans))
		
		return ans
	else:
		print(str(p1) + str(theta1).substr(0, 4) + " tidak berhimpit " + str(p2) + str(theta2).substr(0, 4))
		return null
		

# Helper to set predecessor and successor during insertion
func _make_new_edge(node: AVLNode, start_point:Vector2, directrix_y) -> void:
	# update edge tepat di kanan arc & cek circle event
	
	node.right_edge_start = start_point
	#add_circle.emit(node.right_edge_start, 10)
	var teta = atan2(-node.next.arc_focus.y + node.arc_focus.y , node.next.arc_focus.x - node.arc_focus.x)
	node.right_edge_direction = teta - PI/2
	
	if node.prev != null:
		# cek intersection left
		var voronoi_vertex = get_half_line_intersection(node.prev.right_edge_start, node.right_edge_start, node.prev.right_edge_direction, node.right_edge_direction)
		if voronoi_vertex != null:
			add_circle_event.emit(voronoi_vertex.y + voronoi_vertex.distance_to(node.arc_focus), voronoi_vertex.x)
			#add_circle.emit(voronoi_vertex, 10)
			#node.next.ends_in_directrix = voronoi_vertex.y
	
	if node.next.next != null:
		# cek intersection right
		var voronoi_vertex = get_half_line_intersection(node.right_edge_start, node.next.right_edge_start, node.right_edge_direction, node.next.right_edge_direction)
		if voronoi_vertex != null:
			add_circle_event.emit(voronoi_vertex.y + voronoi_vertex.distance_to(node.next.arc_focus), voronoi_vertex.x)
			#add_circle.emit(voronoi_vertex, 8)
	
	
func _check_circle_event_on_newly_inserted_arc(node: AVLNode, directrix_y) -> void:
	# asumsi edge sudah benar
	
	if node.prev.prev != null:
		print('cek kiri')
		# check edge intersection with prev
		var voronoi_vertex = get_half_line_intersection(node.prev.prev.right_edge_start, node.prev.right_edge_start, node.prev.prev.right_edge_direction, node.prev.right_edge_direction)
		if voronoi_vertex != null:
			print('cek kiri berhasil')
			add_circle_event.emit(voronoi_vertex.y + voronoi_vertex.distance_to(node.prev.arc_focus), voronoi_vertex.x)
			#node.next.ends_in_directrix = voronoi_vertex.y
			add_circle.emit(voronoi_vertex, 10)
			add_circle.emit(voronoi_vertex, voronoi_vertex.distance_to(node.arc_focus))
	
	if node.next.next != null:
		# check edge intersection with next
		var voronoi_vertex = get_half_line_intersection(node.right_edge_start, node.next.right_edge_start, node.right_edge_direction, node.next.right_edge_direction)
		if voronoi_vertex != null:
			add_circle_event.emit(voronoi_vertex.y + voronoi_vertex.distance_to(node.next.arc_focus), voronoi_vertex.x)
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
	else:
		# insert at right
		node.right = _insert_di_paling(node.right, data, directrix_y, false)

	return _balance(node)

# Recursive insert function that also balances the tree and updates predecessors and successors
func _site_event(node: AVLNode, data: Vector2, directrix_y) -> AVLNode:
	if node == null:
		var new_node = AVLNode.new(data)
		return new_node

	var right_x = node.get_right_breakpoint(directrix_y).x
	var left_x = node.get_left_breakpoint(directrix_y).x
	
	if data.x < left_x:
		# check site event at left
		node.left = _site_event(node.left, data, directrix_y)
			
	elif data.x > right_x:
		# check site event at right
		node.right = _site_event(node.right, data, directrix_y)
			
	else:
		# sef method
		var arc_yg_di_split = node.arc_focus
		var arc_yg_di_tengah = data
		
		
		print("arc yang displit adalah " + str(arc_yg_di_split))
		
		# insert at left
		node.left = _insert_di_paling(node.left, arc_yg_di_split, directrix_y, false)
		
		var new_node_left = _get_max_value_node(node.left)
		new_node_left.prev = node.prev
		new_node_left.next = node
		if node.prev != null: node.prev.next = new_node_left
		node.prev = new_node_left
		
		
		# insert at right
		node.right = _insert_di_paling(node.right, arc_yg_di_split, directrix_y, true)
		
		var new_node_right = _get_min_value_node(node.right)
		new_node_right.prev = node
		new_node_right.next = node.next
		if node.next != null: node.next.prev = new_node_right
		node.next = new_node_right
		
		# change arc_focus in middle
		node.arc_focus = arc_yg_di_tengah
		
		
		# update edge kanan kanan (kiri kiri tidak usah karena sudah otomatis)
		var edge_kanan = [node.right_edge_start, node.right_edge_direction]
		new_node_right.right_edge_start = edge_kanan[0]
		new_node_right.right_edge_direction = edge_kanan[1]
		
		
		# update edge tepat kiri & tepat kanan
		var start = Vector2(data.x, new_node_left.get_y(data.x, directrix_y))
		var teta = atan2(- node.arc_focus.y + node.prev.arc_focus.y , node.arc_focus.x - node.prev.arc_focus.x)
		# print("teta = " + str(teta))
		
		node.prev.right_edge_start = start # node.get_left_breakpoint(directrix_y)
		node.prev.right_edge_direction = teta - PI/2
		
		var arah = Vector2(cos(node.prev.right_edge_direction), -sin(node.prev.right_edge_direction))
		#add_edge.emit(start, start + 300 * arah)
		#add_circle.emit(start, 5)
		#add_edge.emit(start, start - 300 * arah)
		
		node.right_edge_start = start #node.get_right_breakpoint(directrix_y)
		node.right_edge_direction = teta + PI/2
		
		_check_circle_event_on_newly_inserted_arc(node, directrix_y)
		
	#debug()
		

	return _balance(node)

# Public insert function
func site_event(data: Vector2, directrix_y) -> void:
	root = _site_event(root, data, directrix_y)

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

func _remove_min(node:AVLNode):
	# syarat node harus bukan null
	if node.left == null:
		return null
	return _balance(node)

func _is_ded(node: AVLNode, directrix_y):
	if node.prev == null or node.next == null: return false
	
	#var point = Vector2(node.arc_focus.x, node.get_y())
	
	#var dist1 = point.distance_squared_to(node.prev.arc_focus)
	#var dist2 = point.distance_squared_to(node.next.arc_focus)
	#var dist3 = (directrix_y - node.arc_focus.y)/2
	#
	#if dist1 == dist2 and dist1 == dist3:
		#return true
	#else:
		#return false

# Recursive remove function that also balances the tree
func _remove(node: AVLNode, data_x, directrix_y) -> AVLNode:
	if node == null:
		return null

	var right_x = node.get_right_breakpoint(directrix_y).x
	var left_x = node.get_left_breakpoint(directrix_y).x
	print(str(node.arc_focus) + "left: " + str(left_x) + ", right: " + str(right_x))
	
	
	# Find the node to be removed
	if not (abs(right_x-left_x) <= EPS and data_x <= right_x + EPS and data_x >= left_x - EPS):
	#if !_is_ded(node, directrix_y):
		if data_x < left_x + EPS:
			# delete left
			node.left = _remove(node.left, data_x, directrix_y)
		elif data_x > right_x - EPS:
			# delete right
			node.right = _remove(node.right, data_x, directrix_y)
		else:
			# not valid
			print("Circle Event not valid anymore")
	else:
		# delete current
		print("deleting arc")
		
		
			
		var voronoi_vertex = Vector2(data_x, node.get_y(data_x, directrix_y))
		
		if node.left == null:
			# Node with only right child (or no child at all)
			# update prev & next
			var removed_node = node
			removed_node.prev.next = removed_node.next
			removed_node.next.prev = removed_node.prev
		
			# update tree
			node = node.right
			
			# close 2 edge
			add_edge.emit(removed_node.prev.right_edge_start, voronoi_vertex)
			add_edge.emit(removed_node.right_edge_start, voronoi_vertex)
			
			# create new edge
			_make_new_edge(removed_node.prev, voronoi_vertex, directrix_y)
			
			
		elif node.right == null:
			# Node with only left child
			
			# update prev & next
			var removed_node = node
			removed_node.prev.next = removed_node.next
			removed_node.next.prev = removed_node.prev
			
			# update tree
			node = node.left
			
			# close 2 edge
			add_edge.emit(removed_node.prev.right_edge_start, voronoi_vertex)
			add_edge.emit(removed_node.right_edge_start, voronoi_vertex)
			
			# create new edge
			_make_new_edge(removed_node.next.prev, voronoi_vertex, directrix_y)
			
		else:
			# node has left & right child
			
			# update tree
			var tmp := _get_min_value_node(node.right)
			node.arc_focus = tmp.arc_focus
			node.right = _remove_min(node.right)
			
			# update prev & next
			if node.right != null:
				var tmp1 = _get_min_value_node(node.right)
				node.next = tmp1
				tmp1.prev = node
			else:
				node.next = null
			
			# close 2 edge
			add_edge.emit(node.prev.right_edge_start, voronoi_vertex)
			add_edge.emit(node.right_edge_start, voronoi_vertex)
			
			# update edge kanan
			node.right_edge_start = tmp.right_edge_start
			node.right_edge_direction = tmp.right_edge_direction
			
			# create new edge
			_make_new_edge(node.prev, voronoi_vertex, directrix_y)
			
			
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

# Public remove function
func remove(data, directrix_y) -> void:
	print("mau remove " + str(data))
	root = _remove(root, data, directrix_y)
