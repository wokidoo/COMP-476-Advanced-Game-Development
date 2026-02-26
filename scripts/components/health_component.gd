@tool
extends Node
class_name HealthComponent

@export var health:float = 10.0:
	set = _set_health

@export var max_health:float = 10.0:
	set = _set_max_health

signal health_changed(old_health:float ,new_health:float)
signal max_health_changed(old_max:float, new_max:float)
signal health_depleted()

func _set_health(value:float):
	if is_equal_approx(value,health):
		return
	var old_health:float = health
	health = clampf(value,0.0,max_health)
	health_changed.emit(old_health,health)
	if is_zero_approx(health):
		health_depleted.emit()

func _set_max_health(value:float):
	if is_equal_approx(value,max_health):
		return
	var old_max:float=max_health
	max_health = maxf(value,0.0)
	health = clampf(health,0.0,max_health)
	max_health_changed.emit(old_max,max_health)
