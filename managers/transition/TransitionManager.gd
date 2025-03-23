extends Node

################################################################################
################################################################################
#### AUTOLOAD REMARKS ##########################################################
################################################################################
################################################################################
# The scene this script is attached to is autoloaded as "TransitionManager".   #
################################################################################

################################################################################
#### IMPORTANT REMARKS #########################################################
################################################################################
# Scene change with loading screen adapted from 
# https://docs.godotengine.org/en/3.5/tutorials/io/background_loading.html

################################################################################
################################################################################
#### CUSTOM SIGNAL DEFINITIONS #################################################
################################################################################
################################################################################
signal transition_finished

################################################################################
################################################################################
#### CONSTANT DEFINITIONS ######################################################
################################################################################
################################################################################
const TRANSITION_MANAGER_STATES = {
	IDLE = 0, 
	SCENE_TRANSITION = 1, 
	SLIDING_TRANSITION = 2
}

################################################################################
################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
################################################################################
var _currentScene 

var _state : int = self.TRANSITION_MANAGER_STATES.IDLE
var _error : int = OK

# DESCRIPTION: Variables required for loading screen
var _loadingProgress : Array[float] = [0.0]
var _loadingStatus : int = ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE
var _loadPath : String = ""

@export_color_no_alpha var _solidBackground : Color = Color.BLACK

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _animationPlayer : AnimationPlayer = $AnimationPlayer

@onready var _loadingScreen : CanvasLayer = $loadingScreen
@onready var _progressBar : ProgressBar = $loadingScreen/CenterContainer/VBoxContainer/ProgressBar

@onready var _transitionEffects : CanvasLayer = $transitionEffects
@onready var _fadeBlack : Control = $transitionEffects/fadeBlack

################################################################################
################################################################################
#### PRIVATE MEMBER FUNCTIONS ##################################################
################################################################################
################################################################################
func _reset_progress() -> void:
	self._progressBar.value = self._progressBar.min_value

func _update_progress(progress : float) -> void:
	if self._progressBar.value != self._progressBar.max_value:
		self._progressBar.value = progress * self._progressBar.max_value

func _set_new_scene(sceneResource) -> void:
	self._currentScene = sceneResource.instantiate()

	# DESCRIPTION: Add the scene to transition to as a child and set it as current
	# REMARK: Setting the scene to current is very important, as otherwise no
	# current scene will be available for checks e.g. by the Settings Manager
	get_node("/root").add_child(self._currentScene)
	get_tree().set_current_scene(self._currentScene) 

	emit_signal("transition_finished")

func _fade_to_black(paused : bool = true) -> void:
	# DESCRIPTION: Make sure that transition effects arre visible
	self._transitionEffects.visible = true
	get_tree().paused = true

	# DESCRIPTION: Play animation and wait until it is finished before emitting signal
	# that transition is finished
	self._animationPlayer.play("fadeToBlack")
	await self._animationPlayer.animation_finished

	get_tree().paused = paused

	emit_signal("transition_finished")

func _fade_loading_screen(reverse : bool = false, paused : bool = true) -> void:
	var _method : String = "play_backwards" if reverse else "play"

	get_tree().paused = true

	self._loadingScreen.visible = true
	self._animationPlayer.call(_method, "fadeLoadingScreen")
	await self._animationPlayer.animation_finished

	get_tree().paused = paused

	emit_signal("transition_finished")

func _pre_transition_routine() -> void:
	self._state = TRANSITION_MANAGER_STATES.SCENE_TRANSITION
	get_tree().paused = true

func _post_transition_routine() -> void:
	self._state = TRANSITION_MANAGER_STATES.IDLE
	get_tree().paused = false

func _pre_loading_routine() -> void:
	self._reset_progress()
	await self._fade_loading_screen()

func _post_loading_routine() -> void:
	await self._fade_loading_screen(true)

################################################################################
################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
################################################################################

################################################################################
#### PUBLIC MEMBER FUNCTIONS: BOOLEANS #########################################
################################################################################
func is_state_scene_transition() -> bool:
	return self._state == self.TRANSITION_MANAGER_STATES.SCENE_TRANSITION

################################################################################
#### PUBLIC MEMBER FUNCTIONS: TRANSITIONS ######################################
################################################################################
func exit_to_system() -> void:
	AudioManager.fade_out_master()
	self._fade_to_black()
	await self.transition_finished

	get_tree().quit()

func goto_scene(path : String): 
	self._error = ResourceLoader.load_threaded_request(path)

	if self._error == OK:
		self._loadPath = path
		self.set_process(true)
		self._currentScene.queue_free()

	else:
		push_error("The resource loading request for the resource with path '", path, "' failed with error code ", self._error, ".")

func transition_to_scene(path : String) -> void:
	self._pre_transition_routine()
	await self._pre_loading_routine()

	self.goto_scene(path)

################################################################################
################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
################################################################################
func _ready() -> void:
	# DESCRIPTION: Set up loading scene transition
	var root = get_tree().get_root()
	self._currentScene = root.get_child(root.get_child_count() -1)

	# DESCRIPTION: Ensure that even when game is paused the transition will be 
	# processed. Make also sure that the mouse is passed through and the Canvas
	# Layer is by default hidden
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	self.set_process(false)
	self._fadeBlack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$loadingScreen/loadingBg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$loadingScreen/loadingBg.color = self._solidBackground
	self._transitionEffects.visible = false
	self._loadingScreen.visible = false

################################################################################
################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
################################################################################
func _process(_delta) -> void:
	if self._state == TRANSITION_MANAGER_STATES.SCENE_TRANSITION:
		if self._error == OK:
			self._loadingStatus = ResourceLoader.load_threaded_get_status(self._loadPath, self._loadingProgress)
			self._update_progress(self._loadingProgress[0])

			if self._loadingStatus == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
				var _tmp_res = ResourceLoader.load_threaded_get(self._loadPath)
				self._set_new_scene(_tmp_res)

				await self._post_loading_routine()
				self._post_transition_routine()
