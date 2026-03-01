extends AIBehaviour
class_name LookAwayBehaviour

func apply_behaviour(_steering:SteeringComponent,_target:Node3D,_delta:float):
	var dir := (_steering.global_position-_target.global_position).normalized()
	_steering.add_direction(dir,weight)
