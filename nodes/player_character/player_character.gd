extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var camera: Camera3D
@export var state_machine:StateMachine

@export_group("Camera Settings")
@export var camera_follow_speed:float = 20.0
@export var camera_distance:float = 3.0:
	set(value):
		if camera_spring_arm == null:
			await self.ready
		camera_distance = value
		camera_spring_arm.spring_length = camera_distance
@export var camera_sensitivity:float = 0.1
@export var pitch_maximum:float = 75
@export var pitch_minimum:float = -75

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

@onready var camera_pivot: Marker3D = %CameraPivot
@onready var camera_spring_arm: SpringArm3D = %CameraSpringArm
@onready var player_collider: CollisionShape3D = %PlayerCollider
@onready var jump_buffer_timer: Timer = %JumpBufferTimer

## Normalized movement direction based on player input.
## Updated every physics frame.
var move_direction:Vector3 = Vector3.ZERO

func _ready():
	camera_spring_arm.spring_length = camera_distance

# Normal physics frame. Runs no matter which state the player is in.
func _physics_process(_delta: float) -> void:
	# Capture user input for movement direction every physics process frame to improve input responsiveness
	var input_vec:Vector2 =  Input.get_vector(
		"move_left", "move_right",
		"move_forward", "move_backward"
	)
	# Map input vector to player relative facing direction
	var relative_dir: Vector3 = get_camera_relative_input(input_vec)
	# convert player input direction to Vector3 in order to use with movement calculations 
	move_direction = relative_dir.normalized()
	# Makes sure the camera is always following the body
	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position,_delta*camera_follow_speed)
	
#region HELPER_FUNCTIONS
## Rotate the camera using the given input event. 
## Does nothing if the event isnt an [InputEventMouseMotion] or [InputEventJoypadMotion]
func rotate_camera(event:InputEvent):
	# Functional but needs reworkd to make sure camera behaves as expected near surfaces.
	# ---IMPLEMENT--- Make surfaces between player model and camera seethrough
	# ---IMPLEMENT--- Make camera push camera when colliding
	if event is InputEventMouseMotion:
		# Rotate camera_pivot for strafe
		var cam_pivot_rot:Vector3= camera_pivot.rotation_degrees
		cam_pivot_rot.y -= event.relative.x * camera_sensitivity
		camera_pivot.rotation_degrees = cam_pivot_rot
		
		# Rotate camera_spring_arm for pitch
		var cam_spring_arm_rot:Vector3 = camera_spring_arm.rotation_degrees
		# clamp pitch between bounds before setting
		cam_spring_arm_rot.x = clamp(cam_spring_arm_rot.x-(event.relative.y * camera_sensitivity),pitch_minimum,pitch_maximum)
		camera_spring_arm.rotation_degrees = cam_spring_arm_rot
	elif event is InputEventJoypadMotion:
		# ---IMPLEMENT--- Joypad rotation
		pass

## Move the player collider towards the movement direction.
## Speed of interpolation based on velocity,
func rotate_collider_towards_movement(direction:Vector3,delta:float,interpolation_factor:float= 0.5):
	# No-op if velocity is 0
	if velocity.is_zero_approx():
		return
	var mov_basis:= Basis(global_basis.looking_at(direction,Vector3.UP))
	self.global_basis = player_collider.global_basis.slerp(mov_basis,delta*velocity.length()*interpolation_factor)

## Pass normalized input vector for movement.
## Returns movement_direction relative to camera forward direction
func get_camera_relative_input(input:Vector2) ->Vector3:
	var cam_right := camera_spring_arm.global_transform.basis.x
	var cam_forward := camera_pivot.global_transform.basis.z
	var result := cam_forward * input.y + cam_right*input.x
	return result.slide(Vector3.UP).normalized()

func get_camera_forward_direction() -> Vector3:
	var cam_right := camera_spring_arm.global_transform.basis.x
	var cam_forward := camera_pivot.global_transform.basis.z
	var result := cam_forward + cam_right
	return result.slide(Vector3.UP).normalized()

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
	rotate_camera(event)
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
		rotate_collider_towards_movement(move_direction,delta)
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
	velocity.y = 0.0

func _on_sprint_state_exited() -> void:
	pass

func _on_sprint_state_input(event: InputEvent) -> void:
	rotate_camera(event)
	if event.is_action_released("sprint"):
		state_machine.execute_event("walking")
	if event.is_action_pressed("jump"):
		state_machine.execute_event("jump")

func _on_sprint_state_physics_process(delta: float) -> void:

	var target_horiz_velocity: Vector3 = sprint_speed * move_direction
	var final_horiz_velocity: Vector3 = Vector3.ZERO

	if not move_direction.is_zero_approx(): # If user inputs a walking direction
		final_horiz_velocity = velocity.lerp(target_horiz_velocity,sprint_acceleration * delta)
		rotate_collider_towards_movement(move_direction,delta)
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
	rotate_camera(event)
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
		rotate_collider_towards_movement(velocity.slide(Vector3.UP).normalized(),delta)
	elif move_direction:
		target_horiz_velocity = air_speed * move_direction
		final_horiz_velocity = current_horiz_velocity.lerp(target_horiz_velocity,air_acceleration * delta)
		rotate_collider_towards_movement(velocity.slide(Vector3.UP).normalized(),delta)
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
		rotate_collider_towards_movement(current_horiz_velocity.slide(Vector3.UP).normalized(),delta)
	elif move_direction:
		target_horiz_velocity = air_speed * move_direction
		final_horiz_velocity = current_horiz_velocity.lerp(target_horiz_velocity,air_acceleration * delta)
		rotate_collider_towards_movement(velocity.slide(Vector3.UP).normalized(),delta)
	else:
		target_horiz_velocity = current_horiz_velocity
		final_horiz_velocity = current_horiz_velocity.lerp(target_horiz_velocity,air_deceleration * delta)
	
	velocity.x = final_horiz_velocity.x
	velocity.z = final_horiz_velocity.z
	move_and_slide()

	if is_on_floor():
		state_machine.execute_event("walking")

#endregion

func _on_state_machine_state_transition(from: State, to: State) -> void:
	await get_tree().process_frame
	print(state_machine.current_state.name)
