extends AIBehaviour
class_name MoveForwardBehaviour

func apply_behaviour(steering:SteeringComponent,target:Node3D,delta:float):
	steering.add_movement(-steering.global_basis.z,weight)
