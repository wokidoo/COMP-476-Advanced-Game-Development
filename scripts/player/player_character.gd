extends CharacterBody3D
class_name Player3D

@export_category("States")
@export_group("Grounded")
@export var walk_speed:float = 3.0
@export var walk_acceleration: float = 20.0
@export var walk_deceleration: float = 30.0
@export_group("Sprint")
@export var sprint_speed: float = 8.0 
@export var sprint_acceleration: float = 4.0
@export var sprint_deceleration: float = 3.0
@export_group("Airborn")
@export var jump_force:float = 10.0
@export var jump_buffer: float = 0.1
@export var air_speed: float = 5.0 # Base lateral speed in air
@export var air_acceleration: float = 10.0 # Air accel
@export var air_deceleration: float = 0.5 # Air decel
@export var jump_gravity: float = 18.0 # Gravity strength
@export var fall_gravity:float = 27.0

@onready var camera_controller:CameraController3D = %CameraController3D
@onready var state_machine:StateMachine = %StateMachine
@onready var player_collider: CollisionShape3D = %PlayerCollider
@onready var jump_buffer_timer: Timer = %JumpBufferTimer

## Normalized movement direction based on player input.
## Updated every physics frame.
var input_direction:Vector3 = Vector3.ZERO

# Normal physics frame. Runs no matter which state the player is in.
func _physics_process(_delta: float) -> void:
	# Capture user input for movement direction every physics process frame to improve input responsiveness
	var input_vec:Vector2 =  Input.get_vector(
		"move_left", "move_right",
		"move_forward", "move_backward"
	)
	# Map input vector to player relative facing direction
	var relative_dir: Vector3 = camera_controller.camera_relative_directions(input_vec)
	# convert player input direction to Vector3 in order to use with movement calculations 
	input_direction = relative_dir.normalized()
	_rotate_body_towards(velocity,_delta)

## Move the player collider towards the movement direction.
## Speed of interpolation based on velocity,
func _rotate_body_towards(direction:Vector3,delta:float,interpolation_factor:float= 0.5):
	direction = direction.slide(up_direction)
	if is_zero_approx(velocity.length_squared()) or is_zero_approx(direction.length_squared()):
		return
	var mov_basis:= Basis.looking_at(direction,Vector3.UP)
	self.global_basis = player_collider.global_basis.slerp(mov_basis,delta*velocity.length()*interpolation_factor)

#region HELPER_FUNCTIONS
## Capture the mouse at the screen center and make it invisible
func capture_mouse():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## Free the mouse and make it visible
func release_mouse():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## Buffers a jump.
func buffer_jump():
	jump_buffer_timer.start(jump_buffer)

## Returns if a jump is currently buffered
func is_jump_buffered() -> bool:
	return not jump_buffer_timer.is_stopped()

#endregion
