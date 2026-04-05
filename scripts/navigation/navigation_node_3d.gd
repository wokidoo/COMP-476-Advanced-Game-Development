@tool
extends Area3D
class_name NavigationNode3D

@export var connections: Array[NavigationNode3D] = []
@export var gap:bool = false
@export var size:float = 1.0:
	set(value):
		size = max(value, 0.01)
		_update_collision_box()
		_update_debug_collision_box()
@export_group("Debug")
@export var debug_draw_collision_box: bool = false:
	set(value):
		debug_draw_collision_box = value
		_update_debug_collision_box()
@export var debug_collision_box_color: Color = Color(1.0, 0.35, 0.2, 0.35):
	set(value):
		debug_collision_box_color = value
		_update_debug_collision_box()
@export var debug_collision_box_material: Material:
	set(value):
		debug_collision_box_material = value
		_update_debug_collision_box()

var _cached_collision_shape: CollisionShape3D
var _cached_debug_mesh: MeshInstance3D
var _fallback_debug_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("nav_node")
	monitorable = false
	monitoring = true
	_update_collision_box()
	_update_debug_collision_box()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_sync_debug_collision_box_transform()
	elif what == NOTIFICATION_CHILD_ORDER_CHANGED:
		_cached_collision_shape = null
		_cached_debug_mesh = null
		_update_debug_collision_box()

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

func _find_collision_shape() -> CollisionShape3D:
	if is_instance_valid(_cached_collision_shape) and _cached_collision_shape.get_parent() == self:
		return _cached_collision_shape

	var named_collision_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if named_collision_shape != null:
		_cached_collision_shape = named_collision_shape
		return named_collision_shape

	for child in get_children():
		var collision_shape := child as CollisionShape3D
		if collision_shape != null:
			_cached_collision_shape = collision_shape
			return collision_shape
	return null


func _get_or_create_collision_shape() -> CollisionShape3D:
	var collision_shape := _find_collision_shape()
	if collision_shape == null:
		collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		add_child(collision_shape)
	_cached_collision_shape = collision_shape
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
