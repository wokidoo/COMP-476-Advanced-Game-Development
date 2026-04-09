@tool
extends Node3D
class_name NavMesh

# make this variable public and accessible from other scripts, but not editable in the inspector
@export var nav_nodes: Array[NavigationNode3D] = []

# Grid generation settings
@export var generation_grid_columns: int = 10
@export var generation_grid_rows: int = 10
@export var generation_grid_cell_size: float = 1.0
@export var node_prefab: PackedScene
@export var DEBUG_generate_grid: bool = false
@export var DEBUG_check_collisions: bool = false
@export_group("Visualize")
@export var DEBUG_draw_boundaries: bool = false:
	set(value):
		DEBUG_draw_boundaries = value
		if Engine.is_editor_hint():
			if (DEBUG_draw_boundaries):
				draw_nav_boundaries()
			else:
				clear()

var node_grid: Array = [NavigationNode3D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if DEBUG_generate_grid:
		if DEBUG_check_collisions:
			generate_grid(true)
		else:
			generate_grid(false)

func draw_nav_boundaries() -> void:
	"""Draw boundaries around the generated navigation nodes for visualization."""
	generate_grid(false)
	return

func clear() -> void:
	"""Clear all generated navigation nodes"""
	for node in nav_nodes:
		if is_instance_valid(node):
			node.queue_free()
	nav_nodes.clear()
	node_grid.clear()

func generate_grid(check_collisions: bool = false) -> void:
	"""
	Generate a grid of navigation nodes, avoiding obstacles.
	Similar to GridGraph.GenerateGrid in the C# reference.
	"""
	if !Engine.is_editor_hint():
		await get_tree().physics_frame
	
	clear()
	
	# Calculate grid dimensions and starting position
	var width = (generation_grid_columns - 1) * generation_grid_cell_size if generation_grid_columns > 0 else 0.0
	var height = (generation_grid_rows - 1) * generation_grid_cell_size if generation_grid_rows > 0 else 0.0
	var gen_position: Vector3 = position - Vector3(width / 2.0, 0, height / 2.0)
	
	# First pass: generate nodes
	for r in range(generation_grid_rows):
		var row: Array = []
		var starting_x = gen_position.x
		
		for c in range(generation_grid_columns):
			# Create or instantiate node
			var curr_node: NavigationNode3D
			if node_prefab != null:
				curr_node = node_prefab.instantiate() as NavigationNode3D
				if curr_node == null:
					push_error("node_prefab must instantiate NavigationNode3D")
					gen_position.x += generation_grid_cell_size
					row.append(null)
					continue
			else:
				curr_node = NavigationNode3D.new()
			
			# Update spawned node's info
			curr_node.name = "NavNode_%d" % nav_nodes.size()
			curr_node.add_to_group("nav_node")
			add_child(curr_node)
			if Engine.is_editor_hint():
				curr_node.owner = get_tree().edited_scene_root
			
			# Set node position
			if curr_node.is_inside_tree():
				curr_node.global_position = gen_position
			else:
				curr_node.position = gen_position
			
			# Check for collisions at this node
			if check_collisions and _has_collision_at(curr_node):
				gen_position.x += generation_grid_cell_size
				# destroy the node since it's colliding with an obstacle
				curr_node.get_parent().remove_child(curr_node)
				curr_node.queue_free()
				row.append(null)
				continue
			
			# Update nodes list
			nav_nodes.append(curr_node)
			row.append(curr_node)
			
			# Update spawn position
			gen_position.x += generation_grid_cell_size
		
		node_grid.append(row)
		gen_position.x = starting_x
		gen_position.z += generation_grid_cell_size
	
	# Second pass: create adjacency information (optional - store neighbors)
	_create_adjacency_lists()
	print("Done generating nav_mesh")

func _has_collision_at(check_node: NavigationNode3D) -> bool:
	return check_node.is_colliding_with_obstacle()

func _create_adjacency_lists() -> void:
	"""
	Create adjacency information between neighboring nodes.
	Stores neighbors in each node for pathfinding.
	"""
	#print("Generating nav_nodes neighbors:")
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

				current_node.connections.append(neighbor_node)
	## DEBUG
	#var root := Engine.get_main_loop() as SceneTree
	#if root == null:
		#return
	#var test_nodes: Array = root.get_nodes_in_group("nav_node")
	#for n in test_nodes:
		#var nav_node := n as NavigationNode3D
		#if nav_node != null:
			#print("\tNavNode: %s, Connections: %d" % [nav_node.name, nav_node.connections.size()])
