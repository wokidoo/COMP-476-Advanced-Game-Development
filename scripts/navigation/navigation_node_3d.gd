extends Area3D
class_name NavigationNode3D

@export var connections: Array[NavigationNode3D] = []
@export var gap:bool = false

func _ready() -> void:
	add_to_group("nav_node")
	monitorable = false
	monitoring = true

func is_position_in_area(global_pos: Vector3) -> bool:
	if not is_inside_tree():
		return false
	var world := get_world_3d()
	if world == null:
		return false
	var space_state := world.direct_space_state
	if space_state == null:
		return false
	var query := PhysicsPointQueryParameters3D.new()
	query.position = global_pos
	query.collide_with_areas = true
	var results := space_state.intersect_point(query)
	for d in results:
		if d.collider == self:
			return true
	return false

func get_world_position() -> Vector3:
	return global_position

func get_distance_to_position(pos: Vector3) -> float:
	return (pos - global_position).length()

func is_gap():
	return gap
