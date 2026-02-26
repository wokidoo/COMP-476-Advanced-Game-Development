extends CharacterBody3D
class_name AIAgent

@export var max_speed:float = 5.0
@export var turn_speed:float = 2.0
@export var floor_friction:float = 3.0
@export var gravity:float = 9.8

@export var avoidance_weight:float = 1.0

@export var target:Node3D
@export var behaviours:Array[AIBehaviour]

@onready var health_component: HealthComponent = %HealthComponent
@onready var steering_component: SteeringComponent = %SteeringComponent
@onready var shape_cast: ShapeCast3D = %ShapeCast3D

func _ready() -> void:
	self.floor_constant_speed = true

func _physics_process(delta: float) -> void:
	if Engine.get_physics_frames()%5==0:
		transform = transform.orthonormalized()
	_apply_behaviours(delta)
	_avoid_obstacles()
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
		if !desired_dir.is_zero_approx():
			_rotate_body(desired_dir.normalized(),delta)
		var desired_movement:Vector3 = steer.get_movement()
		velocity += desired_movement

func _apply_behaviours(delta:float):
	for b:AIBehaviour in behaviours:
		b.apply_behaviour(steering_component,target,delta)

func _rotate_body(dir:Vector3,delta:float) -> void:
	var new_basis := Basis(global_basis.looking_at(dir,up_direction))
	global_basis = global_basis.slerp(new_basis,turn_speed*delta)

func _apply_gravity(delta:float) -> void:
	velocity.y -= gravity*delta

func _avoid_obstacles():
	if shape_cast.is_colliding():
		for idx:int in range(shape_cast.get_collision_count()):
			var point:Vector3 = shape_cast.get_collision_point(idx)
			var normal:Vector3 = shape_cast.get_collision_normal(idx)
			normal = normal.slide(up_direction)
			var dir:Vector3 = -normal.reflect(-basis.z)
			var dist:float = shape_cast.position.distance_to(point)
			var f:float = clampf(shape_cast.shape.radius/dist,0.0,1.0)
			steering_component.add_direction(dir,avoidance_weight*f)
