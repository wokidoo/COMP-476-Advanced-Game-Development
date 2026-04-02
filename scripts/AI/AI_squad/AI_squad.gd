@abstract
extends Node3D
class_name  AISquad

@export var enabled:bool:
	set(value):
		enabled = value
		set_physics_process(enabled)
@export var group: String

## Number of physics frames between updates.
## By default updates every frame (update_frame = 1)
@export_range(1,60) var update_frame:int = 1

var agents: Array = []

func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames() % update_frame == 0:
		agents = get_tree().get_nodes_in_group(group) as Array[AIAgent]
		process_squad_behaviour(delta)

func process_squad_behaviour(_delta:float) -> void:
	pass
