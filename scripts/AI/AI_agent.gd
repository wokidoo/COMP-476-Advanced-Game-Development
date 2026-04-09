extends CharacterBody3D
class_name AIAgent
@export var walk_speed:float = 2.5
@export var walk_acceleration:float = 2.0
@export var turn_speed:float = 2.0
@export var gravity:float = 9.8

@export var target:Node3D

@export var navigation_root:NavigationNode3D

@export_group("Distance activation")
@export var activate_on_distance: bool = false
@export_range(0.0, 1000.0, 0.1) var activation_distance: float = 10.0
@export var is_activated: bool = false

@onready var health_component: HealthComponent = %HealthComponent
@onready var steering_component: SteeringComponent = %SteeringComponent
@onready var avoider_component: AvoiderComponent = %AvoiderComponent
@onready var state_machine:StateMachine = %StateMachine
@onready var hit_ray_3d: HitRay3D = %HitRay3D

var jump_target:Vector3 = Vector3.ZERO
var _jumping:bool = false

func _ready() -> void:
	velocity = Vector3.ZERO
	health_component.health_depleted.connect(_on_health_depeleted)

func _physics_process(delta: float) -> void:
	if activate_on_distance and not is_activated:
		velocity.y -= gravity * delta
		move_and_slide()
		return
	
	if _jumping:
		return
	
	var h_velocity := velocity
	h_velocity.y = 0.0
	_rotate_body_physics_frame(steering_component.get_direction(), delta)
	var target_velocity := steering_component.get_movement().normalized() * walk_speed
	var result_velocity := h_velocity.lerp(target_velocity, delta * walk_acceleration)
	result_velocity.y = velocity.y - (gravity * delta)
	velocity = result_velocity
	move_and_slide()

func _rotate_body_physics_frame(dir: Vector3, delta: float) -> void:
	# Yaw-only: project onto plane perpendicular to up
	var flat := dir.slide(up_direction)
	if is_zero_approx(flat.length_squared()):
		return
	flat = flat.normalized()
	# Godot forward is -Z, so look_at makes -Z point toward flat
	var target_basis := Basis.looking_at(flat, up_direction)
	var target_quat := Quaternion(target_basis)
	var current_quat := Quaternion(global_basis)
	# Keep bases orthonormal to avoid drift over time
	global_basis = Basis(current_quat.slerp(target_quat, delta * turn_speed))

func jump_to(target_pos: Vector3) -> void:
	jump_target = target_pos
	state_machine.execute_event('jump')


func get_facing_target_factor(target_dir:Vector3) -> float:
	return -global_basis.z.dot(target_dir)

func receive_damage(dmg:DamageInstnace,_hurtbox:Hurtbox3D):
	print('NPC hit!\nDamage: %s'%[dmg.damage])
	health_component.health -= dmg.damage
	state_machine.execute_event('hurt')

func _on_health_depeleted():
	self.queue_free()

func _on_radius_activation_component_target_entered_radius(activating_target: Node3D) -> void:
	is_activated = true
