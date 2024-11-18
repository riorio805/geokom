extends Object
class_name PriorityQueue ## MinHeap Priority Queue

var pq:Array = []
var value_func:Callable

static func create_pq(initial:Array=[], value_fn:Callable=func(x):return x ) -> PriorityQueue:
	var out = PriorityQueue.new()
	out.pq = initial
	out.value_func = value_fn
	out.heapify()
	return out

func _to_string():
	return str(pq.map(func(p): return [p, value_func.call(p)]))

func is_empty() -> bool:
	return len(pq) == 0

func add(value):
	pq.append(value)
	percolate_up(len(pq)-1)

func peek():
	return pq[0]

func remove():
	var out = pq[0]
	if len(pq) > 1:
		pq[0] = pq.pop_back()
		percolate_down(0)
	else:
		pq = []
	return out


func heapify():
	for i in range(len(pq)-1, -1, -1):
		percolate_down(i)

func get_min_child_index(curr:int) -> int:
	var left = 2 * curr + 1
	if left >= len(pq): return -1
	
	if left + 1 >= len(pq):
		return left
	elif (self.value_func.call(pq[left]) <=
		  self.value_func.call(pq[left + 1])):
		return left
	else:
		return left + 1

func percolate_down(index:int):
	assert(index >= 0 and index < len(pq), "percolate_down: Index {0} must be inside array bounds < {1}".format([index, len(pq)]))
	var min = get_min_child_index(index)
	if min != -1 and value_func.call(pq[min]) < value_func.call(pq[index]):
		var tmp = pq[min]
		pq[min] = pq[index]
		pq[index] = tmp
		
		percolate_down(min)

func percolate_up(index:int):
	assert(index >= 0 and index < len(pq), "percolate_up: Index must be inside array bounds")
	var par = (index - 1) / 2
	if index != 0 and value_func.call(pq[index]) < value_func.call(pq[par]):
		var tmp = pq[par]
		pq[par] = pq[index]
		pq[index] = tmp
		
		percolate_up(par)
