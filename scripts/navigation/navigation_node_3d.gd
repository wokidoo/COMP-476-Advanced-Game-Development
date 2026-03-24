@tool
extends Node3D
class_name NavigationNode3D

var DEBUG_MESH_MAT:Material = load("uid://du6cknqxsiyj3")


@export var exclude_in_path:bool = false
@export_tool_button("Update Connections") 
var _update_connctions: Callable = func():
	propagate_call('update_connections',[],true)

# Maximum distance to auto-connect to neighbouring nodes
@export var horizontal_boundry_distance: float = 2.0
# How high above this node the raycast checks for ceiling clearance
@export var vertical_boundry_distance: float = 2.0
@export var child_nodes: Array[NavigationNode3D] = []
@export var connections:Dictionary[NavigationNode3D,Vector3] = {}

@export_group("Debug")
@export var debug:bool = true:
	set(value):
		debug = value
		for c in child_nodes:
			c.debug = debug
		propagate_call('update_debug_mesh',[],true)

@export var mesh_radius:float = 0.1:
	set(Value):
		mesh_radius = Value
		for c in child_nodes:
			c.mesh_radius = mesh_radius
		propagate_call('update_debug_mesh',[],true)

var debug_sphere:MeshInstance3D

func _ready() -> void:
	debug_sphere = MeshInstance3D.new()
	debug_sphere.mesh = SphereMesh.new()
	debug_sphere.material_override = DEBUG_MESH_MAT
	add_child(debug_sphere)
	update_debug_mesh()
	update_connections()

func is_position_in_boundry(global_pos:Vector3) -> bool:
	var h_pos:Vector3 = global_pos
	var self_h_pos:Vector3 = global_position
	self_h_pos.y = 0.0
	h_pos.y = 0.0
	var v_pos = global_pos.y
	if abs(v_pos-global_position.y) < vertical_boundry_distance:
		if self_h_pos.distance_to(h_pos) < horizontal_boundry_distance:
			return true
	return false
	

func get_nearest_node()->NavigationNode3D:
	var best_node = child_nodes.front()
	var best_dist = best_node.global_position.distance_to(global_position)
	for c in child_nodes:
		var dist = c.global_position.distance_to(global_position)
		if dist < best_dist:
			best_dist = dist
			best_node = c
	return best_node

func find_nearest_node_to_position(global_pos: Vector3) -> NavigationNode3D:
	if child_nodes.is_empty():
		return self

	var best_node: NavigationNode3D = self  # or null if parents shouldn't qualify
	var best_dist: float = global_position.distance_to(global_pos)
	
	for child in child_nodes:
		var result := child.find_nearest_node_to_position(global_pos)
		var dist := result.global_position.distance_to(global_pos)
		if dist < best_dist:
			best_dist = dist
			best_node = result
	return best_node

func get_world_position() -> Vector3:
	return global_position

func get_distance_to_position(pos:Vector3)->float:
	return (pos - global_position).length()

func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		update_connections()

func update_debug_mesh():
	debug_sphere.visible = debug
	debug_sphere.mesh.radius = mesh_radius
	debug_sphere.mesh.height = mesh_radius*2.0
	notify_property_list_changed()

func update_connections():
	if not is_inside_tree():
		return
		
	child_nodes.clear()
	connections.clear()
	for c in get_children():
		if c is NavigationNode3D:
			child_nodes.append(c)
			connections.set(c,(c.global_position - self.global_position))
	notify_property_list_changed()
