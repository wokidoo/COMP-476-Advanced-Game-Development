@tool
extends Node3D
class_name AvoiderComponent

@export var ray_length:float = 3.0:
	set(value):
		ray_length = value
		_update_rays()

@export_range(0.0,90.0) var ray_angle:float = 0.5:
	set(value):
		ray_angle = value
		_update_rays()

@export var avoidance_weight:float = 1.0
@export var steering_component:SteeringComponent
@export_flags_3d_physics var avoidance_mask:int:
	set(value):
		avoidance_mask = value
		center_ray.collision_mask = avoidance_mask
		left_ray.collision_mask = avoidance_mask
		right_ray.collision_mask = avoidance_mask

var avoidance_direction:Vector3 = Vector3.ZERO

var center_ray:RayCast3D
var left_ray:RayCast3D
var right_ray:RayCast3D

var _is_avoiding:bool = false

func _init() -> void:
	center_ray = RayCast3D.new()
	left_ray = RayCast3D.new()
	right_ray = RayCast3D.new()
	center_ray.collision_mask = avoidance_mask
	left_ray.collision_mask = avoidance_mask
	right_ray.collision_mask = avoidance_mask
	_update_rays()

func _ready() -> void:
	add_child(center_ray)
	add_child(left_ray)
	add_child(right_ray)
	_update_rays()

func _physics_process(_delta: float) -> void:
	avoidance_direction = Vector3.ZERO
	_is_avoiding = false
	if center_ray.is_colliding():
		_is_avoiding = true
		process_collision(center_ray)
	elif left_ray.is_colliding():
		_is_avoiding = true
		process_collision(left_ray)
	elif right_ray.is_colliding():
		_is_avoiding = true
		process_collision(right_ray)

func _update_rays() -> void:
	if center_ray == null or left_ray == null or right_ray == null:
		return
	center_ray.target_position = Vector3(0.0, 0.0, -1.0).normalized() * ray_length
	left_ray.target_position = Vector3(-sin(deg_to_rad(ray_angle)), 0.0, -cos(deg_to_rad(ray_angle))).normalized() * ray_length
	right_ray.target_position = Vector3(sin(deg_to_rad(ray_angle)), 0.0, -cos(deg_to_rad(ray_angle))).normalized() * ray_length
	
func process_collision(ray:RayCast3D):
	var point:Vector3 = ray.get_collision_point()
	var normal:Vector3 = ray.get_collision_normal()
	normal = normal.slide(Vector3.UP).normalized()
	var dist:float = global_position.distance_to(point)
	var f:float = 1.0-clampf(dist/ray_length,0.0,1.0)
	avoidance_direction += normal
	steering_component.add_direction(normal,avoidance_weight*f)
	steering_component.add_movement(-steering_component.get_movement(),avoidance_weight*f)

func is_avoiding()->bool:
	return _is_avoiding
