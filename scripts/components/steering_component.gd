extends Node3D
class_name SteeringComponent

var _rotation_sum:Vector3 = Vector3.ZERO
var _movement_sum:Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	reset()

func reset()->void:
	_rotation_sum = Vector3.ZERO
	_movement_sum = Vector3.ZERO

func add_direction(dir:Vector3,weight:float)->void:
	_rotation_sum += dir*weight
	_rotation_sum.y = 0.0

func add_movement(dir:Vector3,weight:float)->void:
	_movement_sum += dir*weight

func get_direction()->Vector3:
	return _rotation_sum

func get_movement()->Vector3:
	return _movement_sum
