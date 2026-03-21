extends Area3D
class_name Hitbox3D

signal hit(hitbox:Hitbox3D,hurtbox:Hurtbox3D)

var damage_instance:DamageInstnace

var hits: Array = []

func _init(_damage_instance:DamageInstnace = DamageInstnace.new()) -> void:
	damage_instance = _damage_instance
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area:Area3D):
	if area is Hitbox3D and not hits.has(area):
		hits.append(area)
		area.tree_exiting.connect(_on_hurtbox_freeing.bind(area))
		hit.emit(self,area)
	
func _on_area_exited(area:Area3D):
	if area is Hitbox3D and hits.has(area):
		area.tree_exiting.disconnect(_on_hurtbox_freeing)
		hits.erase(area)

func _on_hurtbox_freeing(hurtbox):
	if hits.has(hurtbox):
		hurtbox.tree_exiting.disconnect(_on_hurtbox_freeing)
		hits.erase(hurtbox)
