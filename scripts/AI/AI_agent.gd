extends CharacterBody3D
class_name AIAgent
@export var debug_mode:bool = false
@export var max_speed:float = 5.0
@export var turn_speed:float = 2.0
@export var floor_friction:float = 3.0
@export var gravity:float = 9.8

@export var avoidance_weight:float = 1.0

@export var target:Node3D
@export var behaviours:Array[AIBehaviour]

@onready var health_component: HealthComponent = %HealthComponent
@onready var steering_component: SteeringComponent = %SteeringComponent
@onready var avoider_component: AvoiderComponent = %AvoiderComponent

func _ready() -> void:
	self.floor_constant_speed = true

func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames()%5==0:
		transform = transform.orthonormalized()
	_apply_behaviours(delta)
	_apply_steering(steering_component,delta)
	## Separate horizontal velocity from vertical velocity
	var horizontal_velocity := velocity.slide(up_direction)
	_apply_gravity(delta)
	var vertical_velocity := clampf(velocity.y,-100,100)
	## limit move speed and lerp towards 0 velocity without impacting vertical velocity
	horizontal_velocity = horizontal_velocity.lerp(Vector3.ZERO,delta*floor_friction).limit_length(max_speed)
	velocity = Vector3(horizontal_velocity.x,vertical_velocity,horizontal_velocity.z)
	move_and_slide()

func _apply_steering(steer:SteeringComponent,delta:float) -> void:
	if is_on_floor():
		var desired_dir:Vector3 = steer.get_direction()
		_rotate_body(desired_dir,delta)
		if debug_mode:
			DebugDraw3D.draw_arrow_ray(self.global_position,steering_component.get_direction().normalized(),3.0,Color.RED,0.1,true,delta)
		var desired_movement:Vector3 = steer.get_movement()
		velocity += desired_movement

func _apply_behaviours(delta:float):
	for b:AIBehaviour in behaviours:
		b.apply_behaviour(steering_component,target,delta)

func _rotate_body(dir: Vector3, delta: float) -> void:
	# Yaw-only: project onto plane perpendicular to up
	var flat := dir.slide(up_direction)
	if is_zero_approx(flat.length_squared()):
		return
	flat = flat.normalized()
	
	# Godot forward is -Z, so look_at makes -Z point toward flat
	var target_basis := Basis.looking_at(flat, up_direction)

	# Interp factor must be [0..1]
	var t := clampf(turn_speed * delta, 0.0, 1.0)

	# Keep bases orthonormal to avoid drift over time
	global_basis = global_basis.slerp(target_basis, t).orthonormalized()

func _apply_gravity(delta:float) -> void:
	velocity.y -= gravity*delta
