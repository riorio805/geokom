class_name PriorityQueue

var pq = []

func make():
	pq = []
	
## item must have .pqval as comparison value
func push(item):
	pq.append(item)
	_max_heapify_reverse(pq, pq.size()-1)
	
func empty():
	return pq.empty()
	
func size():
	return pq.size()
	
func top():
	if empty():
		return null
	return pq[0]
	
func pop():
	var top = top()
	if top == null: 
		return null
	var back = pq.back()
	pq[0] = back
	pq.pop_back()
	if(!empty()):
		_max_heapify(pq, 0)
	return top
	
## heap
func _max_heapify(arr, curr):
	var largest = curr
	var left = 2*curr+1
	var right = 2*curr+2
	if left < arr.size() and arr[largest].pqval < arr[left].pqval:
		largest = left
	if right < arr.size() and arr[largest].pqval < arr[right].pqval:
		largest = right
	if largest != curr:
		var t = arr[curr]
		arr[curr] = arr[largest]
		arr[largest] = t
		_max_heapify(arr,largest)

func _max_heapify_reverse(arr, curr):
	var parent = (curr-1)/2
	if arr[curr].pqval > arr[parent].pqval:
		var t = arr[curr]
		arr[curr] = arr[parent]
		arr[parent] = t
		_max_heapify_reverse(arr, parent)
