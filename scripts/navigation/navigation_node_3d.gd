@tool
extends Area3D
class_name NavigationNode3D

@export var connections: Array[NavigationNode3D] = []
@export var gap:bool = false
@export var size:float = 1.0:
	set(value):
		size = max(value, 0.01)
		if Engine.is_editor_hint():
			_update_collision_box()
			_update_debug_collision_box()

@export_group("Debug")
@export var debug_draw_collision_box: bool = false:
	set(value):
		debug_draw_collision_box = value
		if Engine.is_editor_hint():
			_update_debug_collision_box()
@export var debug_collision_box_color: Color = Color(1.0, 0.35, 0.2, 0.35):
	set(value):
		debug_collision_box_color = value
		if Engine.is_editor_hint():
			_update_debug_collision_box()
@export var debug_collision_box_material: Material:
	set(value):
		debug_collision_box_material = value
		if Engine.is_editor_hint():
			_update_debug_collision_box()

var _cached_debug_mesh: MeshInstance3D
var _fallback_debug_material: StandardMaterial3D

func _ready() -> void:
	if not Engine.is_editor_hint():
		if debug_draw_collision_box:
			_update_collision_box()
			_update_debug_collision_box()

func get_world_position() -> Vector3:
	return global_position

func get_distance_to_position(pos: Vector3) -> float:
	return (pos - global_position).length()

func is_gap():
	return gap

func is_colliding_with_obstacle() -> bool:
	var world := get_world_3d()
	if world == null or not Engine.is_in_physics_frame():
		return false

	var space_state = world.direct_space_state
	var collision_shape := _find_collision_shape()
	if space_state == null or collision_shape == null or collision_shape.shape == null:
		return false

	var shape := collision_shape.shape
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.transform = collision_shape.global_transform
	query.exclude = [self, collision_shape]
	var result = space_state.intersect_shape(query, 20)
	if result.is_empty():
		return false
	else:
		return true

#region Collision Shape

func _find_collision_shape() -> CollisionShape3D:
	var named_collision_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if named_collision_shape != null:
		return named_collision_shape

	for child in get_children():
		var collision_shape := child as CollisionShape3D
		if collision_shape != null:
			return collision_shape
	return null


func _get_or_create_collision_shape() -> CollisionShape3D:
	var collision_shape := _find_collision_shape()
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)
	return collision_shape


func _update_collision_box() -> void:
	var collision_shape := _get_or_create_collision_shape()
	if collision_shape == null:
		return

	var box_shape := collision_shape.shape as BoxShape3D
	if box_shape == null:
		box_shape = BoxShape3D.new()

	var target_size: Vector3 = Vector3.ONE * max(size, 0.01)
	target_size.y = 0.5  # Set a default height for the box
	if box_shape.size != target_size:
		box_shape.size = target_size
	collision_shape.shape = box_shape

#endregion

#region Debug Visualization

func _get_or_create_debug_box() -> MeshInstance3D:
	if is_instance_valid(_cached_debug_mesh) and _cached_debug_mesh.get_parent() == self:
		return _cached_debug_mesh

	var debug_mesh := get_node_or_null("DebugCollisionBox") as MeshInstance3D
	if debug_mesh == null:
		debug_mesh = MeshInstance3D.new()
		debug_mesh.name = "DebugCollisionBox"
		add_child(debug_mesh)
	_cached_debug_mesh = debug_mesh
	return debug_mesh


func _get_fallback_debug_material() -> StandardMaterial3D:
	if _fallback_debug_material == null:
		_fallback_debug_material = StandardMaterial3D.new()
		_fallback_debug_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_fallback_debug_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_fallback_debug_material.no_depth_test = true
	_fallback_debug_material.albedo_color = debug_collision_box_color
	return _fallback_debug_material

'''Draw the navigation node's collision box for debugging purposes.'''
func _update_debug_collision_box() -> void:
	var debug_mesh := _get_or_create_debug_box()
	if not debug_draw_collision_box:
		debug_mesh.visible = false
		return

	var collision_shape := _find_collision_shape()
	if collision_shape == null or collision_shape.shape == null:
		debug_mesh.visible = false
		return

	debug_mesh.visible = true

	var box_shape := collision_shape.shape as BoxShape3D
	var box_mesh := debug_mesh.mesh as BoxMesh
	if box_mesh == null:
		box_mesh = BoxMesh.new()
	if box_shape != null:
		if box_mesh.size != box_shape.size:
			box_mesh.size = box_shape.size
	else:
		var debug_shape_mesh := collision_shape.shape.get_debug_mesh()
		if debug_shape_mesh != null:
			var debug_size := debug_shape_mesh.get_aabb().size
			if box_mesh.size != debug_size:
				box_mesh.size = debug_size
		else:
			if box_mesh.size != Vector3.ONE:
				box_mesh.size = Vector3.ONE

	var material: Material = debug_collision_box_material
	if material == null:
		material = _get_fallback_debug_material()

	if debug_mesh.mesh != box_mesh:
		debug_mesh.mesh = box_mesh
	if debug_mesh.material_override != material:
		debug_mesh.material_override = material
	_sync_debug_collision_box_transform()


func _sync_debug_collision_box_transform() -> void:
	if not debug_draw_collision_box:
		return
	var collision_shape := _find_collision_shape()
	if collision_shape == null:
		return
	var debug_mesh := _get_or_create_debug_box()
	debug_mesh.transform = collision_shape.transform

#endregion
