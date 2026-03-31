@tool
extends State

@export var player:Player3D
@export var animation_tree:AnimationTree

func state_enter() -> void:
	player.velocity.y += player.jump_force

func state_exit() -> void:
	pass # Replace with function body.

func state_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		player.buffer_jump()
	
	if event.is_action_pressed('lock_on'):
		if player.camera_controller.is_locked_on():
			player.camera_controller.lock_off()
		else:
			player.camera_controller.lock_on_nearest_enemy()

func state_physics_process(delta: float) -> void:
	var h_velocity = player.velocity
	h_velocity.y = 0.0
	
	var target_velocity: Vector3 = player.input_direction * player.air_speed
	var result_velocity: Vector3 = h_velocity.lerp(target_velocity,delta*player.air_acceleration)
	
	if h_velocity.length_squared() > target_velocity.length_squared():
		result_velocity = h_velocity.lerp(target_velocity,delta*player.air_deceleration)
	else:
		result_velocity = h_velocity.lerp(target_velocity,delta*player.air_acceleration)
	
	result_velocity.y = player.velocity.y - (player.jump_gravity * delta)

	player.velocity = result_velocity
	player.move_and_slide()
	
	if player.is_on_floor():
		state_machine.execute_event("walking")
	if player.velocity.y <= 0.0:
		state_machine.execute_event("falling")
	
