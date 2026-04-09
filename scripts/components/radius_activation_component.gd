extends Node3D

@export_range(0.0, 1000.0, 0.1) var activation_distance: float = 10.0

signal target_entered_radius(target: Node3D)
signal target_exited_radius(target: Node3D)

var _agent: AIAgent
@export var _tracked_target: Node3D
var _is_target_in_range: bool = false

func _ready() -> void:
	if _tracked_target == null:
		_agent = get_parent() as AIAgent
		if is_instance_valid(_agent):
			activation_distance = _agent.activation_distance
			_tracked_target = _agent.target

func _physics_process(_delta: float) -> void:
	var distance_squared := global_position.distance_squared_to(_tracked_target.global_position)
	var in_range := distance_squared <= activation_distance * activation_distance

	if in_range == _is_target_in_range:
		return

	_is_target_in_range = in_range
	if in_range:
		target_entered_radius.emit(_tracked_target)
	else:
		target_exited_radius.emit(_tracked_target)

func _reset_target_state() -> void:
	if _is_target_in_range and is_instance_valid(_tracked_target):
		target_exited_radius.emit(_tracked_target)
	_is_target_in_range = false
	_tracked_target = null
