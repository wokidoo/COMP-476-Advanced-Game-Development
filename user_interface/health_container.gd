extends Panel

func _healthChanged(old_health: float, new_health: float) -> void:
	visible = true;
	get_child(0).value = new_health


func _maxHealthChanged(old_max: float, new_max: float) -> void:
	get_child(0).max_value = new_max
