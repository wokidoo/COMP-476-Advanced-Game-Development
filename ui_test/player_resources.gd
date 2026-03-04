extends Control

var health
var stamina 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.connect("timeout", _reset)
	health = $BarsContainer/BarsSubContainer/HealthContainer/HealthBar.value
	stamina = $BarsContainer/BarsSubContainer/StaminaContainer/StaminaSubcontainer/StaminaBar.value
	pass 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# damage simulator
	if Input.is_action_just_pressed("damage_player_debug"):
		_vibrate()
		$CherAmiIconContainer/CherAmiIcon.texture = load("res://ui_test/distraction.png")
		health -= 5
		$Timer.start(1)
	
	#stamina simulator
	if Input.is_action_pressed("sprint"):
		stamina -= 0.05
	else:
		stamina += 0.05
	
	#update visual components
	$BarsContainer/BarsSubContainer/HealthContainer/HealthBar.value = health
	$BarsContainer/BarsSubContainer/StaminaContainer/StaminaSubcontainer/StaminaBar.value = stamina
	pass

func _reset() -> void:
	$CherAmiIconContainer/CherAmiIcon.texture = load("res://ui_test/finch.png")
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
	
	
