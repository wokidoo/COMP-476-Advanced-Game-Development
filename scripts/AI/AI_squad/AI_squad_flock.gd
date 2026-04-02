extends AISquad
class_name AISquadFlock

@export var flock_force:float = 1.0
@export var radius: float = 8.0

var squad_center:Vector3

func process_squad_behaviour(_delta:float) -> void:
	squad_center = Vector3.ZERO
	for a in agents:
		squad_center += a.global_position
	squad_center = squad_center/agents.size()
	for a:AIAgent in agents:
		var dist :float = a.global_position.distance_to(squad_center)
		if dist > radius:
			AIUtils.AIActions.look_at_position(a,squad_center,flock_force)
			AIUtils.AIActions.move_towards_position(a,squad_center,flock_force)
