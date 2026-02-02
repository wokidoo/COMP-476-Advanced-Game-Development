extends CharacterBody3D
class_name AIAgent

@export var movement_behaviours: Dictionary[MovementStrategy,Node3D]
@export var max_speed:float = 5.0
@export var floor_friction:float = 3.0
@export var gravity:float = 9.8

func _ready() -> void:
	self.floor_constant_speed = true

func _physics_process(delta: float) -> void:
	_process_movement_strategies(delta)
	## Separate horizontal velocity from vertical velocity
	var horizontal_velocity := velocity.slide(Vector3.UP)
	var vertical_velocity := velocity.y
	## limit move speed and lerp towards 0 velocity without impacting vertical velocity
	horizontal_velocity = horizontal_velocity.lerp(Vector3.ZERO,delta*floor_friction).limit_length(max_speed)
	velocity = Vector3(horizontal_velocity.x,vertical_velocity,horizontal_velocity.z)
	_apply_gravity(delta)
	move_and_slide()

func _process_movement_strategies(_delta:float):
	for strat in movement_behaviours:
		var target:Node3D= movement_behaviours.get(strat)
		strat.apply_movement_strategy(self,target,_delta)

func _apply_gravity(delta:float) -> void:
	velocity.y -= gravity*delta
