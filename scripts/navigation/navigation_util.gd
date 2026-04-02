extends RefCounted
class_name NavigationUtil

class NavPath extends RefCounted:
	var path:Array[NavigationNode3D] = []
	var _current_idx:int = 0
	
	func _init(_path:Array[NavigationNode3D] = []) -> void:
		path = _path.duplicate()
	
	func get_current_node() -> NavigationNode3D:
		return path[_current_idx] if not path.is_empty() else null
	
	func get_next_node() -> NavigationNode3D:
		_current_idx += 1
		_current_idx = clamp(_current_idx,0,path.size()-1)
		return path[_current_idx]
	
	func get_last_node() -> NavigationNode3D:
		var _last_node_idx = _current_idx -1
		_last_node_idx = clamp(_last_node_idx,0,path.size()-1)
		return path[_last_node_idx]
	
	func reached_last_node()->bool:
		return path.back() == path[_current_idx]
	
	func is_empty()->bool:
		return path.is_empty()

static func find_path(starting_pos: Vector3, target_pos: Vector3) -> NavPath:
	var start := find_nearest_node_to_position(starting_pos)
	var goal  := find_nearest_node_to_position(target_pos)

	if start == goal:
		return NavPath.new([start])

	# open_set: node -> {g, f, parent}
	var open_set: Dictionary = {}
	var closed_set: Dictionary = {}

	open_set[start] = { "g": 0.0, "f": _heuristic(start, goal), "parent": null }

	while not open_set.is_empty():
		var current: NavigationNode3D = _lowest_f(open_set)

		if current == goal:
			return _reconstruct_path(current, open_set, closed_set)

		var current_data: Dictionary = open_set[current]
		open_set.erase(current)
		closed_set[current] = current_data

		for neighbour in current.connections:
			if closed_set.has(neighbour):
				continue

			var tentative_g :float= current_data["g"] + current.get_distance_to_position(neighbour.global_position)

			if open_set.has(neighbour):
				if tentative_g < open_set[neighbour]["g"]:
					open_set[neighbour]["g"]      = tentative_g
					open_set[neighbour]["f"]      = tentative_g + _heuristic(neighbour, goal)
					open_set[neighbour]["parent"] = current
			else:
				open_set[neighbour] = {
					"g":      tentative_g,
					"f":      tentative_g + _heuristic(neighbour, goal),
					"parent": current
				}
	return NavPath.new()

static func _heuristic(a: NavigationNode3D, b: NavigationNode3D) -> float:
	return a.global_position.distance_to(b.global_position)

static func _lowest_f(open_set: Dictionary) -> NavigationNode3D:
	var best_node: NavigationNode3D = null
	var best_f := INF
	for node in open_set:
		if open_set[node]["f"] < best_f:
			best_f = open_set[node]["f"]
			best_node = node
	return best_node

static func _reconstruct_path(
		goal: NavigationNode3D,
		open_set: Dictionary,
		closed_set: Dictionary) -> NavPath:

	var path:Array[NavigationNode3D] = []
	var current: NavigationNode3D = goal

	while current != null:
		path.push_front(current)
		var data: Dictionary = open_set[current] if open_set.has(current) else closed_set[current]
		current = data["parent"]

	return NavigationUtil.NavPath.new(path)

static func find_nearest_node_to_position(global_pos: Vector3) -> NavigationNode3D:
	var root := Engine.get_main_loop() as SceneTree
	var nav_nodes:Array = root.get_nodes_in_group('nav_node')
	var best_node: NavigationNode3D = nav_nodes.front()
	var best_dist: float = best_node.get_distance_to_position(global_pos)
	for c:NavigationNode3D in nav_nodes:
		var dist := c.get_distance_to_position(global_pos)
		if dist < best_dist:
			best_dist = dist
			best_node = c
	return best_node
