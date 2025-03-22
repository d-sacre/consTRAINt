@tool

extends Control

################################################################################
#### REQUIREMENTS ##############################################################
################################################################################
# This script expects the following AutoLoads:                                 
# - SettingsManager: res://managers/settings/SettingsManager.gd
# - DictionaryParsing: res://utils/DictionaryParsing.gd
#                                                                              
# This script expects the following Globals:                                   
# - CONS_TRAIN_T: res://settings/globals.gd
################################################################################
################################################################################
################################################################################

################################################################################
#### CONSTANT DEFINITIONS ######################################################
################################################################################
const _uiElementsRootPath : String = "PanelContainer/MarginContainer/VBoxContainer/"

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _uiElementLUT : Dictionary = {
	"master": {
		"type": "slider",
		"reference": get_node(self._uiElementsRootPath + "audio/VBoxContainer/master"),
		"signal": "settings_value_changed",
		"keyChain": ["volume", "master"]
	},
	"ui": {
		"type": "slider",
		"reference": get_node(self._uiElementsRootPath + "audio/VBoxContainer/ui"),
		"signal": "settings_value_changed",
		"keyChain": ["volume", "sfx", "ui"]
	},
	"ambience": {
		"type": "slider",
		"reference": get_node(self._uiElementsRootPath + "audio/VBoxContainer/ambience"),
		"signal": "settings_value_changed",
		"keyChain": ["volume", "sfx", "ambience"]
	},
	"game": {
		"type": "slider",
		"reference": get_node(self._uiElementsRootPath + "audio/VBoxContainer/game"),
		"signal": "settings_value_changed",
		"keyChain": ["volume", "sfx", "game"]
	},
	"music": {
		"type": "slider",
		"reference": get_node(self._uiElementsRootPath + "audio/VBoxContainer/music"),
		"signal": "settings_value_changed",
		"keyChain": ["volume", "music"]
	},
	"fullscreen": {
		"type": "checkButton",
		"reference": get_node(self._uiElementsRootPath + "visuals/VBoxContainer/fullscreen"),
		"signal": "settings_value_changed",
		"keyChain": ["visual", "fullscreen"]
	},
	"debug": {
		"type": "checkButton",
		"reference": get_node(self._uiElementsRootPath + "performance/VBoxContainer/debug"),
		"signal": "settings_value_changed",
		"keyChain": ["performance", "debug"]
	}
}

################################################################################
#### SIGNAL HANDLING ###########################################################
################################################################################
func _on_settings_value_changed(keyChain : Array, value) -> void:
	SettingsManager.update_user_settings(keyChain, value)

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
	var _tmp_userSettings : Dictionary = SettingsManager.get_user_settings()

	for _uiElementID in self._uiElementLUT:
		var _tmp_uiElement : Dictionary = self._uiElementLUT[_uiElementID]

		if "signal" in _tmp_uiElement:
			_tmp_uiElement.reference.connect(_tmp_uiElement["signal"], _on_settings_value_changed)
			_tmp_uiElement.reference.initialize(
				_tmp_uiElement["keyChain"], 
				DictionaryParsing.get_by_key_chain_safe(_tmp_userSettings, _tmp_uiElement["keyChain"])
			)

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		var _tmp_userSettings : Dictionary = SettingsManager.get_user_settings()

		# DESCRIPTION: Update the display value of all the CheckButtons
		# REMARK: Check required, as otherwise manual interaction with button would be impossible
		if SettingsManager.is_new_update_queued():
			for _uiElementID in _uiElementLUT:
				if self._uiElementLUT[_uiElementID]["type"] == "checkButton":
					self._uiElementLUT[_uiElementID].reference.update_display(
						DictionaryParsing.get_by_key_chain_safe(
							_tmp_userSettings, self._uiElementLUT[_uiElementID]["keyChain"]
						)
					)

			SettingsManager.reset_update_queue()