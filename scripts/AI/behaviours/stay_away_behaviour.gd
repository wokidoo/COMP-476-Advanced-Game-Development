extends AIBehaviour
class_name StayAwayBehaviour

@export var radius:float = 2.0

func apply_behaviour(_steering:SteeringComponent,_target:Node3D,_delta:float):
	var targ_to_agent := (_steering.global_position - _target.global_position)
	var dist := targ_to_agent.length()
	var dir := targ_to_agent.normalized()
	var f:float = 1-clampf(dist/radius,0.0,1.0)
	_steering.add_movement(dir,weight*f)
