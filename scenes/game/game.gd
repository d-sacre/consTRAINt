extends Node2D

################################################################################
#### SIGNAL HANDLING ###########################################################
################################################################################

# DESCRIPTION: Force un update of the settings
# REMARK: Required so that e.g. debug elements are correctly displayed
func _on_transition_finished() -> void:
	SettingsManager.force_update()

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
	TransitionManager.transition_finished.connect(self._on_transition_finished)
	SettingsManager.force_update()
