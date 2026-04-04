@tool
extends State

@export var player:Player3D
@export var lunge_speed:float = 5.0
var anim_playback:AnimationNodeStateMachinePlayback

func state_enter() -> void:
	anim_playback = player.animation_tree['parameters/playback']
	anim_playback.travel('light_attack')
	player.velocity += -player.global_basis.z * lunge_speed
func state_exit() -> void:
	pass

func state_input(_event: InputEvent) -> void:
	pass

func state_physics_process(_delta: float) -> void:
	var h_velocity:Vector3 = player.velocity
	h_velocity.y = 0.0
	var result_velocity = h_velocity.lerp(Vector3.ZERO,_delta*5.0)
	player.velocity = result_velocity
	player.velocity.y = player.velocity.y - (player.jump_gravity * _delta)
	player.move_and_slide()
	
	var anim_ratio:float = anim_playback.get_current_play_position()/anim_playback.get_current_length()
	
	if anim_ratio < 0.5 and anim_ratio > 0.25:
		player.sabre_hitbox.enabled = true
	elif anim_ratio >= 0.5:
		player.sabre_hitbox.enabled = false
		state_machine.execute_event('grounded')
		
	
