extends Node

################################################################################
#### AUTOLOAD REMARKS ##########################################################
################################################################################
# The scene this script is attached to is autoloaded as "SettingsManager".
################################################################################
################################################################################
################################################################################

################################################################################
#### REQUIREMENTS ##############################################################
################################################################################
# This script expects the following AutoLoads:                                 
# - FileIO: res://utils/FileIO.gd
# - WindowManager: res://managers/window/WindowManager.gd
# - DictionaryParsing: res://utils/DictionaryParsing.gd
# - AudioManager: res://managers/audio/AudioManager.tscn
#                                                                              
# This script expects the following Globals:                                   
# - CONS_TRAIN_T: res://settings/globals.gd
################################################################################
################################################################################
################################################################################

################################################################################
#### CONSTANT DEFINITIONS ######################################################
################################################################################
# user settings
# user:// under Linux/MacOS: ~/.local/share/godot/app_userdata/Name, 
# Windows: %APPDATA%/Name
const USER_SETTINGS_FILEPATH : String = CONS_TRAIN_T.CONFIGURATION_FILES.USER.RUNTIME.PATH
const FALLBACK_USER_SETTINGS_FILEPATH : String = CONS_TRAIN_T.CONFIGURATION_FILES.USER.DEFAULT.PATH

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
var _userSettings : Dictionary = {}
var _userSettingsDefault : Dictionary = {}
var _newUpdate : bool = false

################################################################################
#### PRIVATE MEMBER FUNCTIONS ##################################################
################################################################################
func _update() -> void:
	self._newUpdate = true
	self.save_user_settings()

	# DESCRIPTION: Set the window mode to match the user setting
	# REMARK: Not the best idea to use Window Manager functions directly. 
	# At least from an architectural standpoint due to entanglement between 
	# AutoLoads. Sending a "signal" by using Input Event to change the window
	# mode does only work once. Afterwards, it is ignored for no obvious reason
	# Perhaps due to not having cleared the variable before reusing it.
	if self._userSettings["visual"]["fullscreen"]:
		WindowManager.set_fullscreen()

	else:
		WindowManager.set_windowed()

	# DESCRIPTION: Verify if a current scene exists and add/remove debug elements
	# according to user settings
	if get_tree().get_current_scene() != null:
		var _tmp_debugRootNode : CanvasLayer = get_tree().get_current_scene().get_node("debug")
		var _tmp_debugNumberOfChildren : int = _tmp_debugRootNode.get_child_count()

		if not self._userSettings["performance"]["debug"]:
			if _tmp_debugNumberOfChildren != 0:
				for child in _tmp_debugRootNode.get_children():
					child.queue_free()

		else:
			if _tmp_debugNumberOfChildren == 0:
				var _tmp_newDebugElement : = load(CONS_TRAIN_T.DEBUG.DEFAULT_PROPERTIES.GUI.SCENE_PATH)
				_tmp_debugRootNode.add_child(_tmp_newDebugElement.instantiate())

func _initialize() -> void:
	# DESCRIPTION: Load default settings
	self._userSettingsDefault = FileIO.json.load(self.FALLBACK_USER_SETTINGS_FILEPATH)

	# DESCRIPTION: Checking if user settings file in "user://" space already exists
	# If not: create a file with the default values
	if not FileAccess.file_exists(self.USER_SETTINGS_FILEPATH):
		FileIO.json.save(self.USER_SETTINGS_FILEPATH, self._userSettingsDefault)
	
	# DESCRIPTION: Loading user settings file from "user://" space
	self._userSettings = FileIO.json.load(self.USER_SETTINGS_FILEPATH)

	self._update()

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func is_new_update_queued() -> bool:
	return self._newUpdate

func reset_update_queue() -> void:
	self._newUpdate = false

func force_update() -> void:
	self._update()

func save_user_settings() -> void:
	FileIO.json.save(self.USER_SETTINGS_FILEPATH, self._userSettings)

func update_user_settings(keyChain : Array, value) -> void:
	var _audioLevelChange : Dictionary = {}

	DictionaryParsing.set_by_key_chain_safe(self._userSettings, keyChain, value)

	# DESCRIPTION: Determine if an audio (volume) setting was changed and
	# if so emit the audio_settings_changed signal with the correct arguments
	if keyChain[0] == "volume": 
		var _tmp_keyChain : Array = []

		for _i in range(1, len(keyChain)):
			_tmp_keyChain.append(keyChain[_i])

		AudioManager.set_bus_level(_tmp_keyChain, value)
		
	self._update()
	
func get_user_settings() -> Dictionary:
	return self._userSettings

func get_user_setting_by_key_chain_safe(keyChain : Array):
	return DictionaryParsing.get_by_key_chain_safe(self._userSettings, keyChain)

func get_user_settings_default() -> Dictionary:
	return self._userSettingsDefault

func get_user_setting_default_by_key_chain_safe(keyChain : Array):
	return DictionaryParsing.get_by_key_chain_safe(self._userSettingsDefault, keyChain)

################################################################################
#### SIGNAL HANDLING ###########################################################
################################################################################
func _on_user_settings_changed(keyChain : Array, value) -> void:
	self.update_user_settings(keyChain, value)

func _ready() -> void:
	self._initialize()

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
func _process(_delta: float) -> void:
	# DESCRIPTION: Manage the "toggle_fullscreen" Input Events
	# REMARK: Not the best idea to use Window Manager functions directly. 
	# At least from an architectural standpoint due to entanglement between 
	# AutoLoads.
	if Input.is_action_just_pressed("toggle_fullscreen"):
		WindowManager.toggle_fullscreen()

		self.update_user_settings(["visual", "fullscreen"], WindowManager.is_fullscreen())

	if Input.is_action_just_pressed("toggle_debug"):
		self.update_user_settings(
			["performance", "debug"], 
			!self.get_user_setting_by_key_chain_safe(["performance", "debug"])
		)
