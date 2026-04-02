extends GPUParticles3D

func _on_health_component_health_changed(old_health: float, new_health: float) -> void:
	restart()
