extends Node3D
class_name HitRay3D

@export var continuous:bool = false:
	set(value):
		continuous = value
		set_physics_process(continuous)

@export var trigger_delay:float = 1.0
@export var length:float = 1.0 

var damage_instance:DamageInstnace

var trigger_delay_timer:Timer

var previous_length:float = 0.0

func _init(_dmg_instance:DamageInstnace = DamageInstnace.new()) -> void:
	damage_instance = _dmg_instance
	trigger_delay_timer = Timer.new()
	add_child(trigger_delay_timer)
	trigger_delay_timer.one_shot = true

func _ready() -> void:
	set_physics_process(continuous)

func _physics_process(delta: float) -> void:
	if trigger_delay_timer.is_stopped():
		process_collision()
		trigger_delay_timer.start(trigger_delay)

func process_collision():
	var hits:Array[Hurtbox3D] = get_all_raycast_hits(global_position,global_position +(-global_basis.z*length))
	if not is_zero_approx(previous_length):
		length = previous_length
		previous_length = 0.0
	for hit in hits:
		hit.trigger_hit(damage_instance)
	set_physics_process(continuous)

func get_all_raycast_hits(from: Vector3, to: Vector3) -> Array[Hurtbox3D]:
	var space_state = get_world_3d().direct_space_state
	var hits:Array[Hurtbox3D] = []
	var exceptions = [] # Objects to ignore in the next c	
	while true:
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		query.exclude = exceptions
		
		var result = space_state.intersect_ray(query)
		
		if result and result.collider is Hurtbox3D:
			hits.append(result.collider)
			exceptions.append(result.rid) # Add the hit object's RID to exceptions
		else:
			break # No more objects in path
	return hits


func trigger_ray(_length:float = 0.0):
	previous_length = length
	if not is_zero_approx(_length):
		length = _length
	trigger_delay_timer.stop()
	set_physics_process(true)
