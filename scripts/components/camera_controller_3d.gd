extends SpringArm3D
class_name CameraController3D

## World-space offset applied on top of the followed node's position.
## Typically placed around shoulder/head height.
@export var follow_offset: Vector3 = Vector3(0.0, 1.6, 0.0)

## How quickly the controller interpolates toward the follow target.
@export_range(1.0, 50.0) var follow_speed: float = 20.0

## Mouse / right-stick sensitivity scalar.
@export_range(0.01, 1.0) var camera_sensitivity: float = 0.1

## Right-stick deadzone.
@export_range(0.0, 0.5) var stick_deadzone: float = 0.15

@export_range(0.0, 0.5) var lock_on_change_deadzone:float = 0.02

## How quickly the basis slerps toward the desired rotation.
@export_range(1.0, 10.0) var smoothing: float = 4.0

## Vertical pitch limits in degrees.
@export_range(-90.0, 0.0) var pitch_min: float = -75.0
@export_range(0.0,  90.0) var pitch_max: float =  75.0

## Node group that the camera can lock on to
@export var lock_on_group:String = 'enemy'

## Input action names — match these to your project's InputMap.
@export_group("Input Actions")
@export var action_look_right: String = "look_right"
@export var action_look_left:  String = "look_left"
@export var action_look_up:    String = "look_up"
@export var action_look_down:  String = "look_down"

signal locked_on(target: Node3D)
signal lock_released

var _follow_target:  Node3D
var _lock_on_target: Node3D

## The target rotation expressed as a Basis.
## All look functions write here; _apply_rotation() slerps toward it each frame.
var _desired_basis: Basis = Basis.IDENTITY

func _ready() -> void:
	top_level = true
	_follow_target = get_parent() as Node3D
	_desired_basis = global_basis
	if _follow_target:
		global_position = _follow_target.global_position + follow_offset

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		_follow_target = get_parent() as Node3D

func _physics_process(delta: float) -> void:
	_update_position(delta)
	_update_rotation(delta)
	_apply_rotation(delta)

func _input(event: InputEvent) -> void:
	if is_locked_on():
		if event is InputEventMouseMotion:
			var screen_normalized_motion = event.relative/get_viewport().get_visible_rect().size
			if screen_normalized_motion.length() > lock_on_change_deadzone:
				change_lock_on_target(event.screen_relative)
	else:
		if event is InputEventMouseMotion:
			_apply_mouse_look(event.screen_relative)

func _update_position(delta: float) -> void:
	if not _follow_target:
		return
	var desired := _follow_target.global_position + follow_offset
	global_position = global_position.lerp(desired, delta * follow_speed)

## Slerps global_basis toward _desired_basis each frame.
## SpringArm3D reads global_basis to determine arm direction.
func _apply_rotation(delta: float) -> void:
	var current_quat := Quaternion(global_basis)
	var desired_quat := Quaternion(_desired_basis)
	global_basis = Basis(current_quat.slerp(desired_quat, delta * smoothing))

func _update_rotation(delta: float) -> void:
	if is_locked_on():
		_update_lock_on_look()
	else:
		_apply_stick_look(delta)

func _update_desired_basis(yaw_deg: float, pitch_deg: float) -> void:
	var current_pitch_deg := rad_to_deg(_desired_basis.get_euler().x)
	var clamped_pitch_deg := clampf(current_pitch_deg + pitch_deg, pitch_min, pitch_max)
	# Rebuild from the clamped value so the pitch quaternion is always valid.
	var yaw_quat := Quaternion(Vector3.UP, deg_to_rad(yaw_deg))
	var pitch_quat := Quaternion(Vector3.RIGHT, deg_to_rad(clamped_pitch_deg - current_pitch_deg))
	_desired_basis = Basis(yaw_quat * Quaternion(_desired_basis) * pitch_quat).orthonormalized()

func _apply_mouse_look(relative: Vector2) -> void:
	_update_desired_basis(
		-relative.x * camera_sensitivity,
		-relative.y * camera_sensitivity
	)

func _apply_stick_look(delta: float) -> void:
	var stick := _get_look_stick()
	if stick.length() < stick_deadzone:
		return
	_update_desired_basis(
		-stick.x * camera_sensitivity * delta * 100.0,
		-stick.y * camera_sensitivity * delta * 100.0
	)

func _get_look_stick() -> Vector2:
	return Vector2(
		Input.get_action_strength(action_look_right) - Input.get_action_strength(action_look_left),
		Input.get_action_strength(action_look_down)  - Input.get_action_strength(action_look_up)
	)

## Rotates _desired_basis to face the lock-on target.
## Basis.looking_at() expects a direction vector, not a position,
## and requires the target to be in world space.
func _update_lock_on_look() -> void:
	if not _lock_on_target:
		lock_off()
		return
	var to_target := _lock_on_target.global_position - global_position
	if to_target.is_zero_approx():
		return
	_desired_basis = Basis.looking_at(to_target).orthonormalized()

func is_locked_on() -> bool:
	return _lock_on_target != null

func lock_on(target: Node3D) -> void:
	_lock_on_target = target
	locked_on.emit(target)

func lock_off() -> void:
	_lock_on_target = null
	lock_released.emit()

## Finds the nearest enemy (group "enemy") to the screen centre and locks on.
## Returns the acquired target, or null if none was found.
func lock_on_nearest_enemy() -> Node3D:
	var target := get_nearest_lock_on_target()
	if target:
		lock_on(target)
	return target

func get_lock_on_target() -> Node3D:
	return _lock_on_target

func change_lock_on_target(direction:Vector2) ->Node3D:
	if is_locked_on():
		var target := get_nearest_lock_on_target(direction)
		if target:
			lock_on(target)
		return target
	return null

## Converts a 2D input direction into a camera-relative world direction.
## Flat on the world XZ plane.
func get_camera_relative_direction(input_dir: Vector2) -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return Vector3.ZERO
	var right := cam.global_basis.x
	var forward := cam.global_basis.z
	var result := right * input_dir.x + forward * input_dir.y
	result.y = 0.0
	return result.normalized() if not result.is_zero_approx() else Vector3.ZERO

func get_nearest_lock_on_target(screen_direction: Vector2 = Vector2.ZERO) -> Node3D:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return null

	var screen_center := get_viewport().get_visible_rect().size / 2.0
	var filter_dir    := screen_direction.normalized()
	var use_filter    := screen_direction.length_squared() > 0.0

	var best: Node3D  = null
	var best_score    := -INF

	for node: Node3D in get_tree().get_nodes_in_group(lock_on_group):
		if cam.is_position_behind(node.global_position):
			continue

		# Always skip the target we are already locked onto so it can never
		# block a switch, even when it sits closest to the screen centre.
		if use_filter and node == _lock_on_target:
			continue

		var screen_offset := cam.unproject_position(node.global_position) - screen_center

		if use_filter and screen_offset.dot(filter_dir) <= 0.0:
			continue

		# Score by projection when switching (furthest along the stick wins),
		# score by proximity to centre for the initial lock-on (no direction).
		var score := screen_offset.dot(filter_dir) if use_filter \
					 else -screen_offset.length()

		if score > best_score:
			best_score = score
			best       = node

	return best
