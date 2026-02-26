extends AIBehaviour
class_name LookAwayBehaviour

func apply_behaviour(steering:SteeringComponent,target:Node3D,delta:float):
	var dir := (steering.global_position-target.global_position).normalized()
	steering.add_direction(dir,weight)
