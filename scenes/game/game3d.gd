extends Node3D

################################################################################
#### REQUIREMENTS ##############################################################
################################################################################
# This script expects the following AutoLoads:                                 
# - TransitionManager: res://managers/transition/TransitionManager.tscn
# - SettingsManager: res://managers/settings/SettingsManager.gd
################################################################################
################################################################################
################################################################################

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
    SettingsManager.force_update()
    TransitionManager.transition_finished.connect(self._on_transition_finished)
