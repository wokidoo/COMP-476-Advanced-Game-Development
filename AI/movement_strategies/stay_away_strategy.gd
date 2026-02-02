extends MovementStrategy
class_name StayAwayStrategy

@export var radius:float = 2.0

func _movement_strategy(agent:CharacterBody3D, target:Node3D,delta:float)->void:
	var direction := agent.global_position - target.global_position
	var distance := direction.length()
	direction = direction.slide(Vector3.UP).normalized()
	
	var horizontal_velocity := agent.velocity.slide(Vector3.UP)
	var result_velocity := Vector3.ZERO
	if distance < radius:
		result_velocity = direction*weight*delta*(radius/distance)
	agent.velocity += result_velocity
