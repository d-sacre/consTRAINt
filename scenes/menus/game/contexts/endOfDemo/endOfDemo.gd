extends PanelContainer

################################################################################
#### REQUIREMENTS ##############################################################
################################################################################
# This script expects the following AutoLoads:                                 
# - TransitionManager: res://managers/transition/TransitionManager.tscn
################################################################################
################################################################################
################################################################################
signal hide_menu

################################################################################
#### CONSTANT DEFINITIONS ######################################################
################################################################################
const _buttonPathRoot : String = "MarginContainer/VBoxContainer/HBoxContainer/"

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _buttonLUT : Dictionary = {
	"continue": {
		"text": "Continue",
		"reference": self.get_node(self._buttonPathRoot + "continue"),
		"callback": _on_continue_pressed,
		"web": true
	},
	"exitToMainMenu": {
		"reference": self.get_node(self._buttonPathRoot + "exitToMainMenu"),
		"callback": _on_exit_to_main_menu_pressed,
		"web": true
	}
}

################################################################################
#### SIGNAL HANDLING ###########################################################
################################################################################
func _on_continue_pressed() -> void:
	visible = false
	get_tree().paused = false
	self.hide_menu.emit()

func _on_exit_to_main_menu_pressed() -> void:
	AudioManager.fade_out_and_stop_all_playing()
	TransitionManager.transition_to_scene(CONS_TRAIN_T.SCENES.MAIN_MENU.PATH)

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
	# DESCRIPTION: Connecting all the buttons to the respective callbacks,
	# set custom button texts if available and set the visibilty in exports 
	# correctly
	for buttonID in self._buttonLUT:
		var _tmp_button : Dictionary = self._buttonLUT[buttonID]

		if "text" in _tmp_button.keys():
			_tmp_button.reference.text = _tmp_button["text"]

		# DESCRIPTION: Setting visibility depending on export type
		if OS.has_feature("web"):
			if not _tmp_button.web:
				_tmp_button.reference.visible = false
			
			else:
				_tmp_button.reference.pressed.connect(_tmp_button.callback)
		
		else:
			# DESCRIPTION: Connection to the respective callback
			_tmp_button.reference.pressed.connect(_tmp_button.callback)

	# DESCRIPTION: Ensure that the menu is not visible
	self.visible = false
