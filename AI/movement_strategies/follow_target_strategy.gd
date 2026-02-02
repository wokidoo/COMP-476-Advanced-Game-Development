extends MovementStrategy
class_name FollowTargetStrategy

func _movement_strategy(agent:CharacterBody3D,target:Node3D,delta:float)->void:
	var direction:= (target.global_position as Vector3 - agent.global_position).slide(Vector3.UP).normalized()
	var result_velocity:= direction*delta*weight
	agent.velocity += result_velocity
