extends CharacterBody3D
class_name AIAgent
@export var walk_speed:float = 2.5
@export var walk_acceleration:float = 2.0
@export var turn_speed:float = 2.0
@export var gravity:float = 9.8

@export var target:Node3D

@export var navigation_root:NavigationNode3D

@onready var health_component: HealthComponent = %HealthComponent
@onready var steering_component: SteeringComponent = %SteeringComponent
@onready var avoider_component: AvoiderComponent = %AvoiderComponent
@onready var state_machine:StateMachine = %StateMachine

func _ready() -> void:
	velocity = Vector3.ZERO
	health_component.health_depleted.connect(_on_health_depeleted)

func _physics_process(delta: float) -> void:
	var h_velocity:Vector3 = velocity
	h_velocity.y = 0.0
	_rotate_body_physics_frame(steering_component.get_direction(),delta)
	var target_velocity = steering_component.get_movement().normalized() * walk_speed
	var result_velocity = h_velocity.lerp(target_velocity,delta*walk_acceleration)
	result_velocity.y = velocity.y - (gravity*delta)
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

func get_facing_target_factor(target_dir:Vector3) -> float:
	return -global_basis.z.dot(target_dir)

func receive_damage(dmg:DamageInstnace,_hurtbox:Hurtbox3D):
	print('NPC hit!\nDamage: %s \t Force: %s'%[dmg.damage,dmg.get_meta("force")])
	health_component.health -= dmg.damage
	if dmg.has_meta("force"):
		print(dmg.get_meta("force"))
		velocity += dmg.get_meta("force")

func _on_health_depeleted():
	self.queue_free()
