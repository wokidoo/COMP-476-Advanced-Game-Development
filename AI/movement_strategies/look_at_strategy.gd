extends MovementStrategy
class_name LookAtStrategy

@export var is_parallel_to_floor:bool = true:
	set(value):
		is_parallel_to_floor = value
		if is_parallel_to_floor:
			_result_method = Callable(_parallel_result_transform)
		else:
			_result_method = Callable(_true_result_transform)
			
@export var floor_normal:Vector3 = Vector3.UP

var _result_method:Callable = Callable(_parallel_result_transform)

func _init() -> void:
	resource_local_to_scene = true

func _movement_strategy(agent:CharacterBody3D, target:Node3D,delta:float)->void:
	var result_trans:Transform3D = _result_method.call(agent,target)
	agent.global_transform = agent.global_transform.interpolate_with(result_trans,weight*delta)

func _parallel_result_transform(agent:CharacterBody3D,target:Node3D)->Transform3D:
	var result_trans:Transform3D = agent.global_transform
	var forward := (target.global_position-agent.global_position).normalized()
	var right := floor_normal.cross(forward).normalized()
	var new_forward:= right.cross(floor_normal).normalized()
	result_trans.basis = Basis.looking_at(new_forward,floor_normal)
	return result_trans

func _true_result_transform(agent:CharacterBody3D,target:Node3D)->Transform3D:
	var result_trans:Transform3D = agent.global_transform
	result_trans = result_trans.looking_at(target.global_position)
	return result_trans
