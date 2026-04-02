extends RefCounted
class_name AIUtils

class AIActions extends RefCounted:
	static func look_at_target(agent:AIAgent, target:Node3D,force:float):
		var direction:Vector3 = (target.global_position - agent.global_position)
		agent.steering_component.add_direction(direction,force)
	
	static func look_at_position(agent:AIAgent, position:Vector3, force:float):
		var direction:Vector3 = (position - agent.global_position)
		agent.steering_component.add_direction(direction,force)
	
	static func look_in_direction(agent:AIAgent, direction:Vector3, force:float):
		agent.steering_component.add_direction(direction,force)
	
	static func move_forward(agent:AIAgent,force:float):
		agent.steering_component.add_movement(-agent.global_basis.z,force)

	static func move_towards_target(agent:AIAgent,target:Node3D, force:float):
		var direction:Vector3 = (target.global_position - agent.global_position)
		agent.steering_component.add_movement(direction,force)
	
	static func move_towards_position(agent:AIAgent,position:Vector3,force:float):
		var direction:Vector3 = (position- agent.global_position)
		agent.steering_component.add_movement(direction,force)
	
	static func move_in_direction(agent:AIAgent,direction:Vector3,force:float):
		agent.steering_component.add_movement(direction,force)
