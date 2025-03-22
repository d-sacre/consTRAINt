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
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
################################################################################
func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func set_fullscreen() -> void:
	var _tmp_currentWindowStatus = DisplayServer.window_get_mode()

	var _tmp_maximized : bool = _tmp_currentWindowStatus == DisplayServer.WINDOW_MODE_MAXIMIZED
	var _tmp_windowed : bool = _tmp_currentWindowStatus == DisplayServer.WINDOW_MODE_WINDOWED

	if _tmp_maximized or _tmp_windowed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func set_windowed() -> void:
	var _tmp_currentWindowStatus = DisplayServer.window_get_mode()

	var _tmp_fullscreen = _tmp_currentWindowStatus == DisplayServer.WINDOW_MODE_FULLSCREEN
	var _tmp_maximized = _tmp_currentWindowStatus == DisplayServer.WINDOW_MODE_MAXIMIZED

	if _tmp_fullscreen or _tmp_maximized:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func toggle_fullscreen() -> void:
	var _tmp_currentWindowStatus = DisplayServer.window_get_mode()
	var _tmp_newWindowStatus = _tmp_currentWindowStatus

	match _tmp_currentWindowStatus:
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			_tmp_newWindowStatus = DisplayServer.WINDOW_MODE_WINDOWED

		DisplayServer.WINDOW_MODE_WINDOWED:
			_tmp_newWindowStatus = DisplayServer.WINDOW_MODE_FULLSCREEN

		DisplayServer.WINDOW_MODE_MAXIMIZED:
			_tmp_newWindowStatus = DisplayServer.WINDOW_MODE_FULLSCREEN
		
	DisplayServer.window_set_mode(_tmp_newWindowStatus) 

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
# # REMARK: Currently not used
# func _process(_delta: float) -> void:
# 	if Input.is_action_just_pressed("set_fullscreen"):
# 		self.set_fullscreen()

# 	elif Input.is_action_just_pressed("set_windowed"):
# 		self.set_windowed()