extends AIBehaviour
class_name MoveForwardBehaviour

func apply_behaviour(_steering:SteeringComponent,_target:Node3D,_delta:float):
	_steering.add_movement(-_steering.global_basis.z,weight)
