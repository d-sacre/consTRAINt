extends Node

################################################################################
################################################################################
#### AUTOLOAD REMARKS ##########################################################
################################################################################
################################################################################
# This script is autoloaded as "WindowManager".                                #
################################################################################

################################################################################
################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
################################################################################
var _lastNonFullscreenWindowMode : DisplayServer.WindowMode

################################################################################
################################################################################
#### PRIVATE MEMBER FUNCTIONS ##################################################
################################################################################
################################################################################
func _get_current_window_mode_bool_lut() -> Dictionary:
	var _tmp_currentWindowMode = DisplayServer.window_get_mode()

	var _tmp_windowMode : Dictionary = {
		"minimized": false,
		"windowed": false,
		"maximized": false,
		"fullscreen": false
	}

	match _tmp_currentWindowMode:
		DisplayServer.WINDOW_MODE_MINIMIZED:
			_tmp_windowMode["minimized"] = true

		DisplayServer.WINDOW_MODE_WINDOWED:
			_tmp_windowMode["windowed"] = true

		DisplayServer.WINDOW_MODE_MAXIMIZED:
			_tmp_windowMode["maximized"] = true

		DisplayServer.WINDOW_MODE_FULLSCREEN:
			_tmp_windowMode["fullscreen"] = true

	return _tmp_windowMode

func _set_last_non_fullscreen_window_mode(mode : int) -> void:
	match mode:
		DisplayServer.WINDOW_MODE_MAXIMIZED:
			self._lastNonFullscreenWindowMode = DisplayServer.WINDOW_MODE_MAXIMIZED

		_:
			self._lastNonFullscreenWindowMode = DisplayServer.WINDOW_MODE_WINDOWED

################################################################################
################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
################################################################################
func get_last_non_fullscreen_window_mode():
	return self._lastNonFullscreenWindowMode

func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func set_fullscreen() -> void:
	var _tmp_currentWindowMode : int = DisplayServer.window_get_mode()
	var _tmp_windowModeLUT : Dictionary = self._get_current_window_mode_bool_lut()	

	if _tmp_windowModeLUT["windowed"] or _tmp_windowModeLUT["maximized"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		self._set_last_non_fullscreen_window_mode(_tmp_currentWindowMode)

func set_windowed() -> void:
	var _tmp_currentWindowMode = DisplayServer.window_get_mode()

	var _tmp_windowModeLUT : Dictionary = self._get_current_window_mode_bool_lut()

	if _tmp_windowModeLUT["fullscreen"]:
		DisplayServer.window_set_mode(self.get_last_non_fullscreen_window_mode())

func toggle_fullscreen() -> void:
	var _tmp_currentWindowMode : = DisplayServer.window_get_mode()
	var _tmp_newWindowMode : = _tmp_currentWindowMode

	var _tmp_windowModeLUT : Dictionary = self._get_current_window_mode_bool_lut()

	if _tmp_windowModeLUT["fullscreen"]:
		_tmp_newWindowMode = self.get_last_non_fullscreen_window_mode()

	elif _tmp_windowModeLUT["windowed"] or _tmp_windowModeLUT["maximized"]:
		_tmp_newWindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN
	
	# DESCRIPTION: Verify whether the new window mode is identical with the 
	# current one and only set new value if they are different. Not only reduces
	# the amount of DisplayServer calls, but also reduces the risk of accidentally
	# resetting the window size in windowed mode
	if _tmp_currentWindowMode != _tmp_newWindowMode:
		DisplayServer.window_set_mode(_tmp_newWindowMode) 
		self._set_last_non_fullscreen_window_mode(_tmp_newWindowMode)

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
# # REMARK: Currently not used
# func _process(_delta: float) -> void:
# 	if Input.is_action_just_pressed("set_fullscreen"):
# 		self.set_fullscreen()

# 	elif Input.is_action_just_pressed("set_windowed"):
# 		self.set_windowed()
