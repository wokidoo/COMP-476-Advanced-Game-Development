extends Node3D
class_name SteeringComponent

var _rotation_sum:Vector3 = Vector3.ZERO
var _movement_sum:Vector3 = Vector3.ZERO
var _parent_node_3d:Node3D

var _move_overriden:bool = false
var _direction_overriden:bool = false

func _ready() -> void:
	_parent_node_3d = get_parent_node_3d()
	
func _physics_process(_delta: float) -> void:
	reset()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		_parent_node_3d = get_parent_node_3d()

func reset()->void:
	_rotation_sum = Vector3.ZERO
	_movement_sum = Vector3.ZERO
	_move_overriden = false
	_direction_overriden = false

func add_direction(dir:Vector3,weight:float)->void:
	if not _direction_overriden:
		_rotation_sum += dir.normalized()*weight
		_rotation_sum.y = 0.0

func add_movement(dir:Vector3,weight:float)->void:
	if not _move_overriden:
		_movement_sum += dir.normalized()*weight

func override_direction(dir:Vector3)->void:
	_direction_overriden = true
	_rotation_sum = dir

func override_movement(dir:Vector3)->void:
	_move_overriden = true
	_movement_sum = dir

func get_direction()->Vector3:
	return _rotation_sum

func get_movement()->Vector3:
	return _movement_sum
