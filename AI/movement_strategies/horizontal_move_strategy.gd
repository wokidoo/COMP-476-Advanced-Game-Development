extends MovementStrategy
class_name  HorizontalMoveStrategy

@export var angle:float =0.0

func _movement_strategy(agent:CharacterBody3D,target:Node3D,delta:float)->void:
	var forward := -agent.basis.z.rotated(Vector3.UP,angle)
	var result_velocity:= forward*delta*weight
	agent.velocity += result_velocity
