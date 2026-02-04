extends CharacterBody3D
class_name AIAgent

@export var movement_behaviours: Dictionary[MovementStrategy,Node3D]
@export var max_speed:float = 5.0
@export var floor_friction:float = 3.0
@export var gravity:float = 9.8
@export var base_player_stayaway_force:float = 100.0
@export var base_agent_stayaway_force:float = 100.0

func _ready() -> void:
	self.floor_constant_speed = true
	set_collision_layer_value(1,false)
	set_collision_layer_value(2,true)
	set_collision_mask_value(2,true)

func _physics_process(delta: float) -> void:
	_process_movement_strategies(delta)
	## Separate horizontal velocity from vertical velocity
	var horizontal_velocity := velocity.slide(Vector3.UP)
	var vertical_velocity := velocity.y
	## limit move speed and lerp towards 0 velocity without impacting vertical velocity
	horizontal_velocity = horizontal_velocity.lerp(Vector3.ZERO,delta*floor_friction).limit_length(max_speed)
	velocity = Vector3(horizontal_velocity.x,vertical_velocity,horizontal_velocity.z)
	_apply_gravity(delta)
	_process_collisions(delta)
	move_and_slide()

func _process_movement_strategies(_delta:float):
	for strat in movement_behaviours:
		var target:Node3D= movement_behaviours.get(strat)
		strat.apply_movement_strategy(self,target,_delta)

func _apply_gravity(delta:float) -> void:
	velocity.y -= gravity*delta

func _process_collisions(delta:float):
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		# Check if the object is a RigidBody3D
		if collider is AIAgent:
			# Calculate direction and apply impulse
			var direction:Vector3 = collision.get_normal()
			var force:= direction*base_agent_stayaway_force*delta
			force.y = velocity.y
			# Apply the force at the point of collision
			velocity = velocity.lerp(force,delta*base_agent_stayaway_force)
		elif collider is CharacterBody3D:
			# Calculate direction and apply impulse
			var direction:Vector3 = collision.get_normal()
			var force:= direction*base_player_stayaway_force*delta
			force.y = velocity.y
			# Apply the force at the point of collision
			velocity = velocity.lerp(force,delta*base_player_stayaway_force)
