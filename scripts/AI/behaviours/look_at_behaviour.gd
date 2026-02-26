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

func apply_behaviour(steering:SteeringComponent,target:Node3D,delta:float):
	_look_strat.call(steering,target,delta)

func _look_at_constant(steering:SteeringComponent,target:Node3D,delta:float):
	if target:
		var dir := (target.global_position-steering.global_position).normalized()
		steering.add_direction(dir,weight)
		
func _look_at_far(steering:SteeringComponent,target:Node3D,delta:float):
	if target:
		var dir := (target.global_position-steering.global_position).normalized()
		var targ_to_agent:= (steering.global_position - target.global_position)
		var dist:= targ_to_agent.length()
		var f:float = 1-clampf(radius/dist,0.0,1.0)
		steering.add_direction(dir,weight*f)

func _look_at_near(steering:SteeringComponent,target:Node3D,delta:float):
	if target:
		var dir := (target.global_position-steering.global_position).normalized()
		var targ_to_agent:= (steering.global_position - target.global_position)
		var dist:= targ_to_agent.length()
		var f:float = 1-clampf(dist/radius,0.0,1.0)
		steering.add_direction(dir,weight*f)
