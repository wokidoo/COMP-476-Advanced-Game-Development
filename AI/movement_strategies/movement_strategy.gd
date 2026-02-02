@abstract
extends Resource
class_name MovementStrategy

@export_group("Movement Strategy")
@export var enabled:bool = true:
	set(value):
		enabled = value
		if enabled:
			_function_caller = _movement_strategy
		else:
			_function_caller = _noop_method

@export var weight:float = 1.0
@export_group("")

var _function_caller:Callable = Callable(_movement_strategy)

func apply_movement_strategy(agent:CharacterBody3D, target:Node3D,delta:float)->void:
	_function_caller.call(agent,target,delta)

func _movement_strategy(agent:CharacterBody3D, target:Node3D,delta:float)->void:
	pass

func _noop_method(agent:CharacterBody3D, target:Node3D,delta:float)->void:
	pass
