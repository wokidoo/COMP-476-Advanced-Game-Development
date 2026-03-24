@tool
extends Area3D
class_name NavigationNode3D

@export var exclude_in_path:bool = false
@export_tool_button("Update Connections") 
var _update_connctions: Callable = func():
	propagate_call('update_connections',[],true)

@export var child_nodes: Array[NavigationNode3D] = []
@export var connections:Dictionary[NavigationNode3D,Vector3] = {}


func _ready() -> void:
	monitorable = false
	monitoring = true
	update_connections()

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
