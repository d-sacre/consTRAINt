extends Node

################################################################################
#### AUTOLOAD REMARKS ##########################################################
################################################################################
# The scene this script is attached to is autoloaded as "SettingsManager".
################################################################################
################################################################################
################################################################################

signal update

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

var _userSettingsKeyChainTable : Array[Array] = []

var _newUpdate : bool = false

var _lastFullscreenStatus : bool = false

var _audioSettingChanged : bool = false
var _audioSettingsChangeKeyChainTable : Array[Dictionary] = []

################################################################################
#### PRIVATE MEMBER FUNCTIONS ##################################################
################################################################################
func _convert_key_chain_to_audio_manager_format(keyChain : Array) -> Array:
	if keyChain[0] == "volume": 
		var _tmp_keyChain : Array = []

		for _i in range(1, len(keyChain)):
			_tmp_keyChain.append(keyChain[_i])

		return _tmp_keyChain
	
	else:
		return []

func _add_to_audio_settings_change_key_chain_table(settings : Array, audio : Array) -> void:
	if audio != []:
		self._audioSettingsChangeKeyChainTable.append(
				{
					"settings": settings,
					"audio": audio
				}
			)
		
		self._audioSettingChanged = true

	else:
		push_error("Audio key chain is empty")

func _update_audio_settings_change_key_chain_table(keyChain : Array) -> void:
	self._add_to_audio_settings_change_key_chain_table(
		keyChain,
		self._convert_key_chain_to_audio_manager_format(keyChain)
	)

func _update() -> void:
	self._newUpdate = true
	self.update.emit()
	self.save_user_settings()

	# DESCRIPTION: Adjust audio settings if they should have changed
	# REMARK: Setting only the settings that have actually changed is
	# necessary to prevent artifacts. E.g. accidentally setting the level
	# of a bus which level has not changed will result in a popping sound
	if self._audioSettingChanged:
		for _keyChainDictionary in self._audioSettingsChangeKeyChainTable:
			var _tmp_value : float = self.get_user_setting_by_key_chain_safe(_keyChainDictionary["settings"])
			AudioManager.set_bus_level_by_key_chain(_keyChainDictionary["audio"], _tmp_value)

			self._audioSettingsChangeKeyChainTable.erase(_keyChainDictionary)

		self._audioSettingChanged = false

	# DESCRIPTION: Set the window mode to match the user setting
	# REMARK: Querrying the last fullscreen status not only reduces the amount
	# of function calls, but is also a second safety layer to reduce the risk of 
	# accidentally resetting the window mode and creating visual glitches.
	# REMARK: Not the best idea to use Window Manager functions directly. 
	# At least from an architectural standpoint due to entanglement between 
	# AutoLoads. Sending a "signal" by using Input Event to change the window
	# mode does only work once. Afterwards, it is ignored for no obvious reason
	# Perhaps due to not having cleared the variable before reusing it.
	if self._lastFullscreenStatus != self._userSettings["visual"]["fullscreen"]:
		if self._userSettings["visual"]["fullscreen"]:
			WindowManager.set_fullscreen()

		else:
			WindowManager.set_windowed()

		self._lastFullscreenStatus = self._userSettings["visual"]["fullscreen"]

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
		FileIO.json.save(self.USER_SETTINGS_FILEPATH, self._userSettingsDefault.duplicate())
	
	# DESCRIPTION: Loading user settings file from "user://" space
	self._userSettings = FileIO.json.load(self.USER_SETTINGS_FILEPATH)

	# DESCRIPTION: Set audio bus levels
	# REMARK: Just a precaution, because initialization of the settings menu should 
	# already take care of that. However, it occured a bug that a slider set to 
	# zero would visually display that value, but the corresponding bus would be
	# on full volume
	AudioManager.set_bus_levels((self.get_user_settings())["volume"])

	# DESCRIPTION: Set the last fullscreen status
	# REMARK: Required to bypass the safety in self._update() that requires
	# both of the values have to be different. Bypassing this safety during the 
	# initialization ensures that the correct window mode will be set.
	self._lastFullscreenStatus = !self._userSettings["visual"]["fullscreen"]

	# DESCRIPTION: Find all settings key chains
	DictionaryParsing.find_all_key_chains(self._userSettings, self._userSettingsKeyChainTable)

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

func set_user_settings(data : Dictionary, root : Array = []) -> void:
	if root != []:
		DictionaryParsing.set_by_key_chain_safe(self._userSettings, root, data)

	else:
		self._userSettings = data

# REMARK: Seems to also set default values at the same time, which should not be possible!
func set_user_setting_by_key_chain_safe(keyChain : Array, value) -> void:
	var _audioLevelChange : Dictionary = {}

	print_debug("default before: ", self.get_user_setting_default_by_key_chain_safe(["volume"]))
	DictionaryParsing.set_by_key_chain_safe(self._userSettings, keyChain, value)
	print_debug("default after: ", self.get_user_setting_default_by_key_chain_safe(["volume"]))

	# DESCRIPTION: Determine if an audio (volume) setting was changed and
	# if so, prepare the key chain for the audio manager and set the audio
	# setting changed flag to true
	if keyChain[0] == "volume": 
		self._update_audio_settings_change_key_chain_table(keyChain)
		# var _tmp_keyChain : Array = []

		# for _i in range(1, len(keyChain)):
		# 	_tmp_keyChain.append(keyChain[_i])

		# self._audioSettingsChangeKeyChainTable.append(
		# 	{
		# 		"settings": keyChain,
		# 		"audio": _tmp_keyChain
		# 	}
		# )
		# self._audioSettingChanged = true
		
	self._update()

func reset_audio_levels_to_default() -> void:
	print_debug("reset audio levels to default")
	print_debug("default: before: ", self.get_user_setting_default_by_key_chain_safe(["volume"]))
	print("setting: before: ", self.get_user_setting_by_key_chain_safe(["volume"]))

	var _tmp_audioSettingsDefault : Dictionary = self.get_user_setting_default_by_key_chain_safe(["volume"])
	self.set_user_settings(_tmp_audioSettingsDefault.duplicate(), ["volume"])

	# DESCRIPTION: Find all the relevant key chains and add them to the audio
	# settings key chain table
	for _keyChain in self._userSettingsKeyChainTable:
		if "volume" in _keyChain:
			self._update_audio_settings_change_key_chain_table(_keyChain)

	self._update()
	print_debug("default: after: ", self.get_user_setting_default_by_key_chain_safe(["volume"]))
	print_debug("setting: after: ", self.get_user_setting_by_key_chain_safe(["volume"]))
	
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
# func _on_user_settings_changed(keyChain : Array, value) -> void:
# 	print_debug("Settings Manager: on settings changed")
# 	self.set_user_setting_by_key_chain_safe(keyChain, value)

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
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

		self.set_user_setting_by_key_chain_safe(["visual", "fullscreen"], WindowManager.is_fullscreen())

	if Input.is_action_just_pressed("toggle_debug"):
		self.set_user_setting_by_key_chain_safe(
			["performance", "debug"], 
			!self.get_user_setting_by_key_chain_safe(["performance", "debug"])
		)
