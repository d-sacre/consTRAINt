extends Control

################################################################################
#### REQUIREMENTS ##############################################################
################################################################################
# This script expects the following AutoLoads:                                 
# - TransitionManager: res://managers/transition/TransitionManager.tscn
################################################################################
################################################################################
################################################################################

################################################################################
#### SIGNALS ###################################################################
################################################################################
signal menu_visibility_changed

enum MENU_STATES{HIDDEN, MAIN, SETTINGS}

var _state : MENU_STATES = MENU_STATES.HIDDEN

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _main : PanelContainer = $contexts/main
@onready var _settings : PanelContainer = $contexts/settings

################################################################################
#### PRIVATE MEMBER FUNCTIONS ##################################################
################################################################################
func _toggle_menu() -> void:
	match self._state:
		MENU_STATES.HIDDEN:
			self.visible = true
			self._main.visible = true
			self._settings.visible = false

			get_tree().paused = true
			self.menu_visibility_changed.emit(true)

			self._state = MENU_STATES.MAIN

		_:
			self.visible = false
			self._main.visible = false
			self._settings.visible = false

			get_tree().paused = true
			self.menu_visibility_changed.emit(false)

			self._state = MENU_STATES.HIDDEN

################################################################################
#### SIGNAL HANDLING ###########################################################
################################################################################
func _on_hide_menu() -> void:
	self._main.visible = false
	self._settings.visible = false
	self.visible = false

	get_tree().paused = false
	self._state = MENU_STATES.HIDDEN

	self.menu_visibility_changed.emit(false)

func _on_show_settings_context() -> void:
	self._settings.visible = true
	self._main.visible = false

	self._state = MENU_STATES.SETTINGS
	self.menu_visibility_changed.emit(true)

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
	self._main.hide_menu.connect(self._on_hide_menu)
	self._settings.hide_menu.connect(self._on_hide_menu)
	self._main.show_settings_context.connect(self._on_show_settings_context)

	self.visible = false
	self._main.visible = false
	self._settings.visible = false
		
################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_ingame_menu"):
		self._toggle_menu()
