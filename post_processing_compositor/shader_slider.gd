@tool
extends Resource
class_name ShaderSlider

@export var label: String = "Slider":
	set(value):
		resource_name = value
		label = value
@export var value: float = 0.0
