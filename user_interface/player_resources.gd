extends Control

@export var health = 10.0
@export var stamina = 10.0
@onready var healthBar = $PlayerResources/BarsContainer/BarsSubContainer/HealthContainer/HealthBar
@onready var staminaBar = %StaminaBar
@onready var cherAmiIcon: TextureRect = %CherAmiIcon

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PlayerResources/Timer.connect("timeout", _reset)
	pass 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#stamina simulator
	if Input.is_action_pressed("sprint"):
		stamina -= 0.01
	elif stamina < 10.0:
		stamina += 0.01
	
	#update visual components
	healthBar.value = health
	staminaBar.value = stamina
	pass

func _reset() -> void:
	cherAmiIcon.texture = load("res://user_interface/finch.png")
	set_offset(0,0)
	set_offset(1,0)
	set_offset(2,0)
	set_offset(3,0)
	
func _vibrate() -> void:
	var hOffset = _get_offset()
	var vOffset = _get_offset()
	set_offset(0,hOffset)
	set_offset(1,vOffset)
	set_offset(2,hOffset)
	set_offset(3,vOffset)
	
func _get_offset() -> float:
	var offset = randf() * 10
	if (offset > 5):
		offset -= 5
		offset *= -1
	offset *= 5
	return offset
	
func _healthChanged(old_health: float, new_health: float) -> void:
	_vibrate()
	cherAmiIcon.texture = load("res://user_interface/distraction.png")
	health = new_health
	$PlayerResources/Timer.start(1)

func _maxHealthChanged(old_max: float, new_max: float) -> void:
	healthBar.max_value = new_max
	
	
