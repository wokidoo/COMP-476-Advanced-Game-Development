extends RefCounted
class_name  DamageInstnace

@export var damage:float

func _init(_damage:float = 0.0, _additional_data: Dictionary = {}):
	damage = _damage
	## Add any additional data as metadata for this damage instance
	for data in _additional_data:
		set_meta(data,_additional_data.get(data))
