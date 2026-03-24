extends RefCounted
class_name NavigationUtil

static func find_path(root: NavigationNode3D, starting_pos: Vector3, target_pos: Vector3) -> Array[NavigationNode3D]:
	var start := root.find_nearest_node_to_position(starting_pos)
	var goal  := root.find_nearest_node_to_position(target_pos)

	if start == goal:
		return [start]

	# open_set: node -> {g, f, parent}
	var open_set:   Dictionary = {}
	var closed_set: Dictionary = {}

	open_set[start] = { "g": 0.0, "f": _heuristic(start, goal), "parent": null }

	while not open_set.is_empty():
		var current: NavigationNode3D = _lowest_f(open_set)

		if current == goal:
			return _reconstruct_path(current, open_set, closed_set)

		var current_data: Dictionary = open_set[current]
		open_set.erase(current)
		closed_set[current] = current_data

		for neighbour in _get_neighbours(current):
			if closed_set.has(neighbour):
				continue

			var tentative_g :float= current_data["g"] + current.global_position.distance_to(neighbour.global_position)

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

	return [] # No path found

static func _get_neighbours(node: NavigationNode3D) -> Array[NavigationNode3D]:
	var neighbours: Array[NavigationNode3D] = []
	# Children are explicit connections
	neighbours.append_array(node.child_nodes)
	# Parent allows traversal back up the hierarchy
	if node.get_parent() is NavigationNode3D:
		neighbours.append(node.get_parent() as NavigationNode3D)
	return neighbours

static func _heuristic(a: NavigationNode3D, b: NavigationNode3D) -> float:
	return a.global_position.distance_to(b.global_position)

static func _lowest_f(open_set: Dictionary) -> NavigationNode3D:
	var best_node: NavigationNode3D = null
	var best_f := INF
	for node in open_set:
		if open_set[node]["f"] < best_f:
			best_f    = open_set[node]["f"]
			best_node = node
	return best_node

static func _reconstruct_path(
		goal: NavigationNode3D,
		open_set: Dictionary,
		closed_set: Dictionary) -> Array[NavigationNode3D]:

	var path:    Array[NavigationNode3D] = []
	var current: NavigationNode3D        = goal

	while current != null:
		path.push_front(current)
		var data: Dictionary = open_set[current] if open_set.has(current) else closed_set[current]
		current = data["parent"]

	return path
