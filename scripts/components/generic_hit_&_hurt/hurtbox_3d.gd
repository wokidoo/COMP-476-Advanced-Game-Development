extends Area3D
class_name Hurtbox3D

signal hit(damage_instance:DamageInstnace,hurtbox:Hurtbox3D)

## Name of the method in parent Node that will resolve the consequences of the hit.
## The method is expected to accept two parameters. One [Hitbox3D] and one [Hurtbox3D] in that order.
@export var damage_callback:StringName

var _parent:Node

var hits:Array = []

func _init() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _ready() -> void:
	_parent = get_parent()

func trigger_hit(dmg_instance:DamageInstnace):
	if _parent.has_method(damage_callback):
		_parent.call(damage_callback,dmg_instance,self)
		self.hit.emit(dmg_instance,self)

# Call parent of Hurtbox3D when Hitbox3D enters.
# Let parent handle processing the hit.
# Hitbox3D will be passed to the parent damage_callback
func _on_area_entered(area:Area3D):
	if area is Hitbox3D and not hits.has(area):
		hits.append(area)
		area.tree_exiting.connect(_on_hitbox_freeing.bind(area))
		trigger_hit(area.damage_instance)
	
func _on_area_exited(area:Area3D):
	if area is Hitbox3D and hits.has(area):
		area.tree_exiting.disconnect(_on_hitbox_freeing)
		hits.erase(area)

func _on_hitbox_freeing(hitbox):
	if hits.has(hitbox):
		hitbox.tree_exiting.disconnect(_on_hitbox_freeing)
		hits.erase(hitbox)
