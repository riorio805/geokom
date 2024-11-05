extends Node

# MinHeap class to manage HeapNode objects
class_name MinHeap


var heap: Array = []

# Swap two elements in the heap
func _swap(i: int, j: int) -> void:
	var temp = heap[i]
	heap[i] = heap[j]
	heap[j] = temp

# Insert a new HeapNode object into the min-heap
func insert(node: HeapNode) -> void:
	heap.append(node)
	_heapify_up(heap.size() - 1)

# Remove and return the HeapNode with the smallest priority
func pop() -> HeapNode:
	if heap.size() == 0:
		return null
	var min_node = heap[0]
	heap[0] = heap[heap.size() - 1]
	heap.pop_back()
	_heapify_down(0)
	return min_node

# Return the HeapNode with the smallest priority without removing it
func peek() -> HeapNode:
	if heap.size() == 0:
		return null
	return heap[0]

# Maintain min-heap property from bottom up based on priority
func _heapify_up(index: int) -> void:
	while index > 0:
		var parent_index = (index - 1) / 2
		if _compare_priority(heap[index], heap[parent_index]):
			_swap(index, parent_index)
			index = parent_index
		else:
			break

# Maintain min-heap property from top down based on priority
func _heapify_down(index: int) -> void:
	while true:
		var left_child = 2 * index + 1
		var right_child = 2 * index + 2
		var smallest = index

		if left_child < heap.size() and _compare_priority(heap[left_child], heap[smallest]):
			smallest = left_child
		if right_child < heap.size() and _compare_priority(heap[right_child], heap[smallest]):
			smallest = right_child

		if smallest != index:
			_swap(index, smallest)
			index = smallest
		else:
			break

# Utility to check if the heap is empty
func is_empty() -> bool:
	return heap.size() == 0

func _compare_priority(a, b): # true if a pop first
	if a.priority < b.priority:
		return true
	if a.priority > b.priority:
		return false
	if !a.is_site_event:
		return true # mau pop circle event dulu
	return false
	
	
