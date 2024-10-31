extends Node

class_name HeapNode

var priority: int # y-position
var is_site_event: bool
var idx_point_or_x_pos


func _init(priority: int, is_site_event: bool, idx_point_or_x_pos):
	self.priority = priority
	self.is_site_event = is_site_event
	self.idx_point_or_x_pos = idx_point_or_x_pos
