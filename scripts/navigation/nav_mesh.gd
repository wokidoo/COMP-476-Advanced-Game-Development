extends Node3D
class_name NavMesh

@export var nav_nodes: Array[NavigationNode3D] = []

# Grid generation settings
@export var generation_grid_columns: int = 10
@export var generation_grid_rows: int = 10
@export var generation_grid_cell_size: float = 1.0
@export var node_prefab: PackedScene
@export var obstacle_collision_mask: int = 1  # Layer mask for obstacles
@export_group("Debug")
@export var DEBUG_generate_grid: bool = false
@export var DEBUG_check_collisions: bool = false

var _pending_debug_generate: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("nav_mesh")
	if DEBUG_generate_grid:
		_pending_debug_generate = true
		set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if not _pending_debug_generate:
		set_physics_process(false)
		return
	if not _can_access_space_state():
		return

	_pending_debug_generate = false
	set_physics_process(false)
	generate_grid(DEBUG_check_collisions)


func _can_access_space_state() -> bool:
	if not is_inside_tree() or not Engine.is_in_physics_frame():
		return false
	return get_world_3d() != null

func clear() -> void:
	"""Clear all generated navigation nodes"""
	for node in nav_nodes:
		if is_instance_valid(node):
			node.queue_free()
	nav_nodes.clear()

func generate_grid(check_collisions: bool = false) -> void:
	"""
	Generate a grid of navigation nodes, avoiding obstacles.
	Similar to GridGraph.GenerateGrid in the C# reference.
	"""
	clear()
	
	# Calculate grid dimensions and starting position
	var width = (generation_grid_columns - 1) * generation_grid_cell_size if generation_grid_columns > 0 else 0.0
	var height = (generation_grid_rows - 1) * generation_grid_cell_size if generation_grid_rows > 0 else 0.0
	var gen_position = position - Vector3(width / 2.0, 0, height / 2.0)
	
	# First pass: generate nodes
	var node_grid: Array = []
	for r in range(generation_grid_rows):
		var row: Array = []
		var starting_x = gen_position.x
		
		for c in range(generation_grid_columns):
			# Check for collisions at this position
			if check_collisions and _has_collision_at(gen_position):
				gen_position.x += generation_grid_cell_size
				row.append(null)
				continue
			
			# Create or instantiate node
			var obj: NavigationNode3D
			if node_prefab != null:
				obj = node_prefab.instantiate() as NavigationNode3D
				if obj == null:
					push_error("node_prefab must instantiate NavigationNode3D")
					gen_position.x += generation_grid_cell_size
					row.append(null)
					continue
			else:
				obj = NavigationNode3D.new()

			obj.name = "NavNode_%d" % nav_nodes.size()
			
			obj.add_to_group("nav_node")
			add_child(obj)
			if obj.is_inside_tree():
				obj.global_position = gen_position
			else:
				obj.position = gen_position
			nav_nodes.append(obj)
			row.append(obj)
			
			gen_position.x += generation_grid_cell_size
		
		node_grid.append(row)
		gen_position.x = starting_x
		gen_position.z += generation_grid_cell_size
	
	# Second pass: create adjacency information (optional - store neighbors)
	_create_adjacency_lists(node_grid, check_collisions)

func _has_collision_at(check_position: Vector3) -> bool:
	"""Check if there's a collision at the given position using a sphere cast"""
	if not _can_access_space_state():
		return false
	var world = get_world_3d()
	if world == null:
		return false
	var space_state = world.direct_space_state
	if space_state == null:
		return false

	var query := PhysicsPointQueryParameters3D.new()
	query.position = check_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = obstacle_collision_mask

	var result = space_state.intersect_point(query)
	return result.size() > 0


func _create_adjacency_lists(node_grid: Array, check_collisions: bool) -> void:
	"""
	Create adjacency information between neighboring nodes.
	Stores neighbors in each node for pathfinding.
	"""
	# Directions: right, left, down, up, diagonals
	var operations = [
		[0, 1], [0, -1], [1, 0], [-1, 0],
		[1, 1], [1, -1], [-1, 1], [-1, -1]
	]
	
	for r in range(generation_grid_rows):
		for c in range(generation_grid_columns):
			var current_node = node_grid[r][c] as NavigationNode3D
			if current_node == null:
				continue

			current_node.connections.clear()
			
			for i in range(operations.size()):
				var neighbor_r = r + operations[i][0]
				var neighbor_c = c + operations[i][1]
				
				# Check bounds
				if neighbor_r < 0 or neighbor_r >= generation_grid_rows or neighbor_c < 0 or neighbor_c >= generation_grid_columns:
					continue
				
				var neighbor_node = node_grid[neighbor_r][neighbor_c] as NavigationNode3D
				if neighbor_node == null:
					continue
				
				# Check for collision between nodes (raycast)
				if check_collisions:
					var direction = neighbor_node.global_position - current_node.global_position
					if _raycast_collision(current_node.global_position, direction):
						continue
				
				current_node.connections.append(neighbor_node)


func _raycast_collision(start: Vector3, direction: Vector3) -> bool:
	"""Check if there's a collision along a ray between two nodes"""
	if not _can_access_space_state():
		return false
	var world = get_world_3d()
	if world == null:
		return false
	var space_state = world.direct_space_state
	if space_state == null:
		return false
	
	var query = PhysicsRayQueryParameters3D.create(start, start + direction)
	query.collision_mask = obstacle_collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	return result != null  # Returns true if hit something


func get_neighbors(node: NavigationNode3D) -> Array[NavigationNode3D]:
	"""Get the neighbors of a navigation node"""
	if node == null:
		return []
	return node.connections
