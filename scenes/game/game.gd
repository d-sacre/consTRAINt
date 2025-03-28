extends Node2D

################################################################################
#### ONREADY MEMBER VARIBALES ##################################################
################################################################################
@onready var _railcar : Node2D = $railcar
@onready var _inGameMenu : Control = $UI/inGameMenu

################################################################################
#### SIGNAL HANDLING ###########################################################
################################################################################

# DESCRIPTION: Force un update of the settings
# REMARK: Required so that e.g. debug elements are correctly displayed
func _on_transition_finished() -> void:
	SettingsManager.force_update()
	
func _on_menu_visibility_changed(status : bool) -> void:
	self._railcar.allow_drawing(!status)

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
	# DESCRIPTION: Connect all the relevant signals
	TransitionManager.transition_finished.connect(self._on_transition_finished)
	self._inGameMenu.menu_visibility_changed.connect(self._on_menu_visibility_changed)

	# DESCRIPTION: Force an update of the settings manager
	SettingsManager.force_update()

	# DESCRIPTION: Start playing the default sounds
	AudioManager.play_sfx(["ambience", "background", "open_fields"])
	AudioManager.play_sfx(["ambience", "train", "rolling"])
	AudioManager.play_sfx(["ambience", "train", "engine"])

	# DESCRIPTION: Start the music playback only if no other song is already playing
	if not AudioManager.is_any_music_playing():
		AudioManager.play_song_by_key_chain(["themeLight", "var1"])		