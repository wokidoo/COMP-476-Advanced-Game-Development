extends Sprite3D

func _healthChanged(old_health: float, new_health: float) -> void:
	visible = true;
	%HealthContainer.value = new_health


func _maxHealthChanged(old_max: float, new_max: float) -> void:
	%HealthContainer.max_value = new_max
