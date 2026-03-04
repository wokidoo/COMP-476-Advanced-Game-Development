extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.connect("timeout", _reset)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# damage simulator
	if Input.is_action_just_pressed("ui_accept"):
		_vibrate()
		$CherAmiIconContainer/CherAmiIcon.texture = load("res://ui_test/distraction.png")
		$BarsContainer/BarsSubContainer/HealthContainer/HealthBar.value -= 5
		$Timer.start(1)
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
	
	
