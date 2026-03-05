extends VBoxContainer

@export var maxVolumeConstant = 20
@export var startingVolumePercentage = 50
@export var busIndex = 0

func _on_settings_button_pressed() -> void:
	get_child(1).visible = false
	get_child(2).visible = true

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_volume_h_slider_value_changed(value: float) -> void:
	#turn the value from a percentage to decibels
	var valueDecibals = log(value / startingVolumePercentage)
	valueDecibals /= log(10)
	valueDecibals *= maxVolumeConstant
	
	#if final value is zero db, then mute
	if value == 0:
		AudioServer.set_bus_mute(busIndex, true)
	#else, unmute it
	else:
		AudioServer.set_bus_mute(busIndex, false)
	# then set volume
	AudioServer.set_bus_volume_db(busIndex,value)

func _on_back_button_tree_entered() -> void:
	get_child(1).visible = true
	get_child(2).visible = false
