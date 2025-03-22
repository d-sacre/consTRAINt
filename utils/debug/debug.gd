extends Label

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
func _process(_delta: float) -> void:
	text = "fps: " + str(Engine.get_frames_per_second())
