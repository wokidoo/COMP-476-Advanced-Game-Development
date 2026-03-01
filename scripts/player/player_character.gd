extends CharacterBody3D

@export var camera_controller:CameraController3D
@export var state_machine:StateMachine

@export_category("States")
@export_group("Grounded")
@export var walk_speed:float = 3.0
@export var walk_acceleration: float = 20.0
@export var walk_deceleration: float = 30.0
@export_group("Sprint")
@export var sprint_speed: float = 8.0 
@export var sprint_acceleration: float = 4.0 #Sprint accel
@export var sprint_deceleration: float = 3.0
@export_group("Airborn")
@export var jump_force:float = 10.0
@export var jump_buffer: float = 0.1
@export var air_speed: float = 5.0 # Base lateral speed in air
@export var air_acceleration: float = 10.0 # Air accel
@export var air_deceleration: float = 0.5 # Air decel
@export var jump_gravity: float = 18.0 # Gravity strength
@export var fall_gravity:float = 27.0

@onready var player_collider: CollisionShape3D = %PlayerCollider
@onready var jump_buffer_timer: Timer = %JumpBufferTimer

## Normalized movement direction based on player input.
## Updated every physics frame.
var move_direction:Vector3 = Vector3.ZERO

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
	move_direction = relative_dir.normalized()

#region HELPER_FUNCTIONS
## Move the player collider towards the movement direction.
## Speed of interpolation based on velocity,
func _rotate_body_towards_movement(direction:Vector3,delta:float,interpolation_factor:float= 0.5):
	# No-op if velocity is 0
	if velocity.is_zero_approx():
		return
	var mov_basis:= Basis.looking_at(direction,Vector3.UP)
	self.global_basis = player_collider.global_basis.slerp(mov_basis,delta*velocity.length()*interpolation_factor)

func get_local_body_forward_vector() -> Vector3:
	return player_collider.basis.z.slide(Vector3.UP).normalized()

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

#region GROUNDED_STATE
func _on_grounded_state_entered() -> void:
	# Guarentees buffer timer to be initialized before using it
	if not is_node_ready():
		await ready
	capture_mouse()
	velocity.y = 0.0
	# If jump is buffered, immediately start a new jump
	if is_jump_buffered():
		state_machine.execute_event("jump")
	elif Input.is_action_pressed("sprint"):
		state_machine.execute_event("sprinting")
	
func _on_grounded_state_exited() -> void:
	pass
	
func _on_grounded_state_input(event: InputEvent) -> void:
	#rotate_camera(event)
	if event.is_action_pressed("sprint"):
		state_machine.execute_event("sprinting")
	if event.is_action_pressed("jump"):
		state_machine.execute_event("jump")
	
func _on_grounded_state_physics_process(delta: float) -> void:
	var target_horiz_velocity: Vector3 = Vector3.ZERO
	var final_horiz_velocity: Vector3

	if  velocity.length() > walk_speed: # Slow down from sprinting speed
		final_horiz_velocity = velocity.lerp(target_horiz_velocity,sprint_deceleration * delta)
	elif not move_direction.is_zero_approx(): # Regular walking
		target_horiz_velocity = walk_speed * move_direction
		final_horiz_velocity = velocity.lerp(target_horiz_velocity,walk_acceleration * delta)
		_rotate_body_towards_movement(move_direction,delta)
	else: # Decelerate if no walking input
		final_horiz_velocity = velocity.lerp(target_horiz_velocity,walk_deceleration * delta)

	velocity.x = final_horiz_velocity.x
	velocity.z = final_horiz_velocity.z
	move_and_slide()
	if not is_on_floor():
		state_machine.execute_event("falling")

#endregion

#region SPRINT_STATE

func _on_sprint_state_entered() -> void:
	pass
	#velocity.y = 0.0

func _on_sprint_state_exited() -> void:
	pass

func _on_sprint_state_input(event: InputEvent) -> void:
	#rotate_camera(event)
	if event.is_action_released("sprint"):
		state_machine.execute_event("walking")
	if event.is_action_pressed("jump"):
		state_machine.execute_event("jump")

func _on_sprint_state_physics_process(delta: float) -> void:

	var target_horiz_velocity: Vector3 = sprint_speed * move_direction
	var final_horiz_velocity: Vector3 = Vector3.ZERO

	if not move_direction.is_zero_approx(): # If user inputs a walking direction
		final_horiz_velocity = velocity.lerp(target_horiz_velocity,sprint_acceleration * delta)
		_rotate_body_towards_movement(move_direction,delta)
	else: # Decelerate if no walking input detected
		target_horiz_velocity = Vector3.ZERO
		final_horiz_velocity = velocity.lerp(target_horiz_velocity,walk_deceleration * delta)
	
	velocity.x = final_horiz_velocity.x
	velocity.z = final_horiz_velocity.z
	move_and_slide()
	
	if not is_on_floor():
		state_machine.execute_event("falling")
	if Input.is_action_just_released("sprint"):
		state_machine.execute_event("walking")

#endregion

#region JUMP_STATE
func _on_jump_state_entered() -> void:
	velocity.y += jump_force

func _on_jump_state_exited() -> void:
	pass # Replace with function body.

func _on_jump_state_input(event: InputEvent) -> void:
	#rotate_camera(event)
	if event.is_action_released("sprint"):
		state_machine.execute_event("grounded")
	elif event.is_action_pressed("jump"):
		buffer_jump()

func _on_jump_state_physics_process(delta: float) -> void:
	var current_horiz_velocity: Vector3 = velocity
	current_horiz_velocity.y = 0.0

	var target_horiz_velocity: Vector3
	var final_horiz_velocity: Vector3 = Vector3.ZERO

	velocity.y -= (jump_gravity * delta)
	if move_direction and current_horiz_velocity.length() > air_speed:
		target_horiz_velocity = air_speed * move_direction
		final_horiz_velocity = current_horiz_velocity.lerp(target_horiz_velocity,air_deceleration * delta)
		_rotate_body_towards_movement(velocity.slide(Vector3.UP).normalized(),delta)
	elif move_direction:
		target_horiz_velocity = air_speed * move_direction
		final_horiz_velocity = current_horiz_velocity.lerp(target_horiz_velocity,air_acceleration * delta)
		_rotate_body_towards_movement(velocity.slide(Vector3.UP).normalized(),delta)
	else:
		target_horiz_velocity = current_horiz_velocity
		final_horiz_velocity = current_horiz_velocity.lerp(target_horiz_velocity,air_deceleration * delta)
	
	velocity.x = final_horiz_velocity.x
	velocity.z = final_horiz_velocity.z
	move_and_slide()
	
	if is_on_floor():
		state_machine.execute_event("walking")
	if velocity.y < 0.0 or is_zero_approx(velocity.y):
		state_machine.execute_event("falling")
	
#endregion

#region FALLING_STATE
func _on_falling_state_entered() -> void:
	pass # Replace with function body.

func _on_falling_state_exited() -> void:
	pass # Replace with function body.

func _on_falling_state_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		buffer_jump()

func _on_falling_state_physics_process(delta: float) -> void:
	var current_horiz_velocity: Vector3 = velocity
	current_horiz_velocity.y = 0.0

	var target_horiz_velocity: Vector3
	var final_horiz_velocity: Vector3 = Vector3.ZERO

	velocity.y -= (fall_gravity * delta)
	if move_direction and current_horiz_velocity.length() > air_speed:
		target_horiz_velocity = air_speed * move_direction
		final_horiz_velocity = current_horiz_velocity.lerp(target_horiz_velocity,air_deceleration * delta)
		_rotate_body_towards_movement(current_horiz_velocity.slide(Vector3.UP).normalized(),delta)
	elif move_direction:
		target_horiz_velocity = air_speed * move_direction
		final_horiz_velocity = current_horiz_velocity.lerp(target_horiz_velocity,air_acceleration * delta)
		_rotate_body_towards_movement(velocity.slide(Vector3.UP).normalized(),delta)
	else:
		target_horiz_velocity = current_horiz_velocity
		final_horiz_velocity = current_horiz_velocity.lerp(target_horiz_velocity,air_deceleration * delta)
	
	velocity.x = final_horiz_velocity.x
	velocity.z = final_horiz_velocity.z
	move_and_slide()

	if is_on_floor():
		state_machine.execute_event("walking")

#endregion

#region NOPLAY_STATE
func _on_noplay_state_entered() -> void:
	release_mouse()

func _on_noplay_state_exited() -> void:
	capture_mouse()

func _on_noplay_state_input(_event: InputEvent) -> void:
	pass
#endregion
