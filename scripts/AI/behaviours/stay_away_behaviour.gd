extends AIBehaviour
class_name StayAwayBehaviour

@export var radius:float = 2.0

func apply_behaviour(steering:SteeringComponent,target:Node3D,delta:float):
	var targ_to_agent := (steering.global_position - target.global_position)
	var dist := targ_to_agent.length()
	var dir := targ_to_agent.normalized()
	var f:float = 1-clampf(dist/radius,0.0,1.0)
	steering.add_movement(dir,weight*f)
