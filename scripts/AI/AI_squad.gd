extends Node
class_name  AISquad

@export var enabled:bool:
	set(value):
		enabled = value
		set_physics_process(enabled)
@export var target:Node3D
@export var agents:Array[AIAgent]
@export var behaviours:Array[AIBehaviour]

@export var flock_behaviours: Array[AIBehaviour]
		
var centroid_marker:Marker3D

func _ready() -> void:
	centroid_marker = Marker3D.new()
	add_child(centroid_marker)
	set_physics_process(enabled)

func _physics_process(delta: float) -> void:
	var average_pos:Vector3 = Vector3.ZERO
	for a:AIAgent in agents:
		average_pos += a.global_position
	average_pos = average_pos/agents.size()
	centroid_marker.global_position = average_pos
	
	for a:AIAgent in agents:
		for b:AIBehaviour in behaviours:
			b.apply_behaviour(a.steering_component,target,delta)
		for b:AIBehaviour in flock_behaviours:
			b.apply_behaviour(a.steering_component,centroid_marker,delta)
