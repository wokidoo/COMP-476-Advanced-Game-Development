@tool
extends Node3D
class_name AvoiderComponent

@export var ray_length:float = 3.0:
	set(value):
		ray_length = value
		_update_length()
@export_range(0.0,90.0) var ray_angle:float = 0.5:
	set(value):
		ray_angle = value
		_update_length()
@export var avoidance_weight:float = 1.0
@export var steering_component:SteeringComponent
@export_flags_3d_physics var avoidance_mask:int:
	set(value):
		avoidance_mask = value
		center_ray.collision_mask = avoidance_mask
		left_ray.collision_mask = avoidance_mask
		right_ray.collision_mask = avoidance_mask

var center_ray:RayCast3D
var left_ray:RayCast3D
var right_ray:RayCast3D

func _init() -> void:
	center_ray = RayCast3D.new()
	left_ray = RayCast3D.new()
	right_ray = RayCast3D.new()
	add_child(center_ray)
	add_child(left_ray)
	add_child(right_ray)

func _ready() -> void:
	_update_length()

func _physics_process(_delta: float) -> void:
	if center_ray.is_colliding():
		process_collision(center_ray)
	elif left_ray.is_colliding():
		process_collision(left_ray)
	elif right_ray.is_colliding():
		process_collision(right_ray)

func _update_length()->void:
	center_ray.target_position = Vector3(0.0,0.0,-1.0).normalized() * ray_length
	left_ray.target_position = Vector3(-sin(deg_to_rad(ray_angle)),0.0,-cos(deg_to_rad(ray_angle))).normalized() * ray_length
	right_ray.target_position = Vector3(sin(deg_to_rad(ray_angle)),0.0,-cos(deg_to_rad(ray_angle))).normalized() * ray_length

func process_left_collision(ray:RayCast3D):
	var point:Vector3 = ray.get_collision_point()
	var normal:Vector3 = ray.get_collision_normal()
	normal = normal.slide(Vector3.UP).normalized()
	var dir:Vector3 = normal
	var dist:float = global_position.distance_to(point)
	var f:float = 1.0-clampf(dist/ray_length,0.0,1.0)
	steering_component.add_direction(dir,avoidance_weight*f)

func process_right_collision(ray:RayCast3D):
	var point:Vector3 = ray.get_collision_point()
	var normal:Vector3 = ray.get_collision_normal()
	normal = normal.slide(Vector3.UP).normalized()
	var dir:Vector3 = normal
	var dist:float = global_position.distance_to(point)
	var f:float = 1.0-clampf(dist/ray_length,0.0,1.0)
	steering_component.add_direction(dir,avoidance_weight*f)
	
func process_collision(ray:RayCast3D):
	var point:Vector3 = ray.get_collision_point()
	var normal:Vector3 = ray.get_collision_normal()
	normal = normal.slide(Vector3.UP).normalized()
	var dir:Vector3 = normal
	var dist:float = global_position.distance_to(point)
	var f:float = 1.0-clampf(dist/ray_length,0.0,1.0)
	steering_component.add_direction(dir,avoidance_weight*f)
