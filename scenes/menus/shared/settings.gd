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
	"resetAudio": {
		"type": "button",
		"reference": get_node(self._uiElementsRootPath + "audio/VBoxContainer/HBoxContainer/resetAudio"),
		"signal": "pressed",
		"callback": _on_reset_audio_to_default
	},
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
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func update_display() -> void:
	var _tmp_userSettings : Dictionary = SettingsManager.get_user_settings()

	for _uiElementID in self._uiElementLUT:
		var _tmp_uiElement : Dictionary = self._uiElementLUT[_uiElementID]

		if _tmp_uiElement.reference.has_method("initialize"):
			_tmp_uiElement.reference.initialize(
				_tmp_uiElement["keyChain"], 
				DictionaryParsing.get_by_key_chain_safe(_tmp_userSettings, _tmp_uiElement["keyChain"])
			)

################################################################################
#### SIGNAL HANDLING ###########################################################
################################################################################
func _on_reset_audio_to_default() -> void:
	SettingsManager.reset_audio_levels_to_default()

func _on_settings_value_changed(keyChain : Array, value) -> void:
	print_debug("Settings Context: User changed settings: ", keyChain, ", ", value)
	SettingsManager.set_user_setting_by_key_chain_safe(keyChain, value)

func _on_settings_manager_update() -> void:
	# DESCRIPTION: Update the display value of all the CheckButtons
	# REMARK: Check required, as otherwise manual interaction with button would be impossible

	for _uiElementID in _uiElementLUT:
		var _tmp_elementType : String = self._uiElementLUT[_uiElementID]["type"]

		# self._uiElementLUT[_uiElementID].reference.update_display(
		# 	SettingsManager.get_user_setting_by_key_chain_safe(self._uiElementLUT[_uiElementID]["keyChain"])
		# )

		match _tmp_elementType:
			"checkButton":
				self._uiElementLUT[_uiElementID].reference.update_display(
					SettingsManager.get_user_setting_by_key_chain_safe(self._uiElementLUT[_uiElementID]["keyChain"])
				)

			"slider":
				self._uiElementLUT[_uiElementID].reference.set_value_silent(
					SettingsManager.get_user_setting_by_key_chain_safe(self._uiElementLUT[_uiElementID]["keyChain"])
				)

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
	# DESCRIPTION: Connect to signals
	SettingsManager.update.connect(self._on_settings_manager_update)

	# DESCRIPTION: Initialize the UI elements
	var _tmp_userSettings : Dictionary = SettingsManager.get_user_settings()

	for _uiElementID in self._uiElementLUT:
		var _tmp_uiElement : Dictionary = self._uiElementLUT[_uiElementID]

		if "signal" in _tmp_uiElement:
			if not "callback" in _tmp_uiElement:
				_tmp_uiElement.reference.connect(_tmp_uiElement["signal"], _on_settings_value_changed)

			else:
				_tmp_uiElement.reference.connect(_tmp_uiElement["signal"], _tmp_uiElement["callback"])

			if _tmp_uiElement.reference.has_method("initialize"):
				_tmp_uiElement.reference.initialize(
					_tmp_uiElement["keyChain"], 
					DictionaryParsing.get_by_key_chain_safe(_tmp_userSettings, _tmp_uiElement["keyChain"])
				)
