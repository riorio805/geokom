extends Node

class_name HeapNode

var priority: int # y-position
var is_site_event: bool

# variabel jika is_site_event True
var idx_point

# variabel jika is_site_event False (circle event)
var left_focus:Vector2
var middle_node:AVLNode
var right_focus:Vector2
var intersection_point:Vector2
