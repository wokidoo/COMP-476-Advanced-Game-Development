@tool
extends Node3D
class_name CameraController3D

@export var camera:Camera3D
@export var pitch_anchor:Node3D
@export var camera_offset:Vector3 = Vector3.ZERO
@export var camera_follow_speed:float = 20.0
@export var camera_sensitivity:float = 0.1
@export var pitch_maximum:float = 75
@export var pitch_minimum:float = -75

var _parent:Node3D

func _ready() -> void:
	_parent = get_parent()
	top_level = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		_parent = get_parent()

func _physics_process(delta: float) -> void:
	global_position = global_position.lerp(_parent.global_position+camera_offset,delta*camera_follow_speed)

func _input(event: InputEvent) -> void:
	rotate_camera(event)

func camera_relative_directions(direction:Vector2)->Vector3:
	var cam_right := camera.global_transform.basis.x
	var cam_forward := camera.global_transform.basis.z.slide(Vector3.UP)
	var result := cam_forward * direction.y + cam_right * direction.x
	return result.slide(Vector3.UP).normalized()

func rotate_camera(event:InputEvent):
	if event is InputEventMouseMotion:
		## PIVOT LEFT AND RIGHT
		var current_pivot:Vector3 = self.rotation_degrees
		current_pivot.y -= event.relative.x * camera_sensitivity
		self.rotation_degrees = current_pivot
		## PITCH UP AND DOWN
		var current_pitch:Vector3 = pitch_anchor.rotation_degrees
		current_pitch.x = clamp(current_pitch.x-(event.relative.y * camera_sensitivity),pitch_minimum,pitch_maximum)
		pitch_anchor.rotation_degrees = current_pitch
	elif event is InputEventJoypadMotion:
		## PIVOT LEFT AND RIGHT
		var current_pivot:Vector3 = self.rotation_degrees
		current_pivot.y -= event.axis.x * event.axis_value * camera_sensitivity
		self.rotation_degrees = current_pivot
		## PITCH UP AND DOWN
		var current_pitch:Vector3 = pitch_anchor.rotation_degrees
		current_pitch.x = clamp(current_pitch.x-(event.axis.y * event.axis_value * camera_sensitivity),pitch_minimum,pitch_maximum)
		pitch_anchor.rotation_degrees = current_pitch
