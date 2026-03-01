extends AIBehaviour
class_name LookAtBehaviour

enum LOOK_AT_MODE {CONSTANT,SCALE_NEAR,SCALE_FAR}
@export var mode:LOOK_AT_MODE:
	set(value):
		mode= value
		match mode:
			LOOK_AT_MODE.CONSTANT:
				_look_strat = _look_at_constant
			LOOK_AT_MODE.SCALE_NEAR:
				_look_strat = _look_at_near
			LOOK_AT_MODE.SCALE_FAR:
				_look_strat = _look_at_far

@export var radius:float = 2.0

var _look_strat:Callable = _look_at_constant

func _init() -> void:
	match mode:
			LOOK_AT_MODE.CONSTANT:
				_look_strat = _look_at_constant
			LOOK_AT_MODE.SCALE_NEAR:
				_look_strat = _look_at_near
			LOOK_AT_MODE.SCALE_FAR:
				_look_strat = _look_at_far

func apply_behaviour(_steering:SteeringComponent,_target:Node3D,_delta:float):
	_look_strat.call(_steering,_target,_delta)

func _look_at_constant(_steering:SteeringComponent,_target:Node3D,_delta:float):
	if _target:
		var dir := (_target.global_position-_steering.global_position).normalized()
		_steering.add_direction(dir,weight)
		
func _look_at_far(_steering:SteeringComponent,_target:Node3D,_delta:float):
	if _target:
		var dir := (_target.global_position-_steering.global_position).normalized()
		var targ_to_agent:= (_steering.global_position - _target.global_position)
		var dist:= targ_to_agent.length()
		var f:float = 1-clampf(radius/dist,0.0,1.0)
		_steering.add_direction(dir,weight*f)

func _look_at_near(_steering:SteeringComponent,_target:Node3D,_delta:float):
	if _target:
		var dir := (_target.global_position-_steering.global_position).normalized()
		var targ_to_agent:= (_steering.global_position - _target.global_position)
		var dist:= targ_to_agent.length()
		var f:float = 1-clampf(dist/radius,0.0,1.0)
		_steering.add_direction(dir,weight*f)
