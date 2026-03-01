extends Node
class_name AIBehaviourAggregate

@export var enabled:bool = true:
	set(value):
		enabled = value
		set_physics_process(enabled)

@export var target:Node3D
@export var steering_component:SteeringComponent
@export var behaviours:Array[AIBehaviour]

func _physics_process(delta: float) -> void:
	for b in behaviours:
		b.apply_behaviour(steering_component,target,delta)

func set_target(targ:Node3D):
	target= targ
