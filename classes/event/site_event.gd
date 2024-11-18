extends Event
class_name SiteEvent

#var y:float
var vertex: Vertex

static func create_site_event(vtx:Vertex) -> SiteEvent:
	var out = SiteEvent.new()
	out.vertex = vtx
	out.y = vtx.point.y
	return out

func value():
	return [-y, 0, -self.vertex.point.x]

func is_valid() -> bool:
	return true

func _to_string():
	return "SiteEvent:: {0}, y={1}".format(
		[self.vertex, self.y])
