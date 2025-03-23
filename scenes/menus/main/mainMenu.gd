extends Control

################################################################################
#### REQUIREMENTS ##############################################################
################################################################################
# This script expects the following AutoLoads:                                 
# - TransitionManager: res://managers/transition/TransitionManager.tscn
# - SettingsManager: res://managers/settings/SettingsManager.gd
#                                                                              
# This script expects the following Globals:                                   
# - CONS_TRAIN_T: res://settings/globals.gd
################################################################################
################################################################################
################################################################################

################################################################################
#### CONSTANT DEFINITIONS ######################################################
################################################################################
const _buttonPathRoot : String = "default/buttonCluster/VBoxContainer/"

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
@export var _playButtonScene : String = CONS_TRAIN_T.SCENES.GAME.PATH

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _buttonLUT : Dictionary = {
	"play": {
		"reference":self.get_node(self._buttonPathRoot + "play"),
		"callback": _on_play_button_pressed,
		"web": true
	},
	"settings": {
		"reference":self.get_node(self._buttonPathRoot + "settings"),
		"callback": _on_settings_button_pressed,
		"web": true
	},
	"credits": {
		"reference": self.get_node(self._buttonPathRoot + "credits"),
		"callback": _on_credits_button_pressed,
		"web": true
	},
	"exit": {
		"reference": self.get_node(self._buttonPathRoot + "exit"),
		"callback": _on_exit_button_pressed,
		"web": false
	}
}

@onready var _settings : Control = $contexts/settings
@onready var _credits : RichTextLabel = $contexts/credits

################################################################################
#### SIGNAL HANDLING ###########################################################
################################################################################

# DESCRIPTION: Force un update of the settings
# REMARK: Required so that e.g. debug elements are correctly displayed
func _on_transition_finished() -> void:
	SettingsManager.force_update()

func _on_play_button_pressed() -> void:
	TransitionManager.transition_to_scene(_playButtonScene)

func _on_settings_button_pressed() -> void:
	self._settings.visible = !self._settings.visible
	self._credits.visible = false
	
func _on_credits_button_pressed() -> void:
	self._credits.visible = !self._credits.visible
	self._settings.visible = false
	
func _on_exit_button_pressed() -> void:
	TransitionManager.exit_to_system()

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
	# DESCRIPTION: Connect all the required button signals to the respective
	# methods and determine visibilities
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
	
	self._settings.visible = false
	self._credits.visible = false

	TransitionManager.transition_finished.connect(self._on_transition_finished)
	SettingsManager.force_update()

	if not AudioManager.is_song_playing_by_key_chain(["themeLight"]):
		AudioManager.play_song_by_key_chain(["themeLight"])
