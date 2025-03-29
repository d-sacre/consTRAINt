extends Node2D

################################################################################
#### CONSTANT DEFINITIONS ######################################################
################################################################################
const SPEED : int = 350
const DIRECTION : int = 1

################################################################################
#### PUBLIC MEMBER VARIABLES ###################################################
################################################################################
class horn:
	class interaction:
		static var short : bool = false
		static var long : bool = false

	class playing:
		static var short : bool = false
		static var long : bool = false

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _drawingArea : Node2D = $interior/drawingArea

################################################################################
#### PRIVATE MEMBER FUNCTIONS ##################################################
################################################################################
func _horn_fsm() -> void:
	if Input.is_action_pressed("jump"):
		self.horn.interaction.long = true

	if self.horn.interaction.long:
		if not self.horn.playing.long:
			AudioManager.play_sfx(["game", "train", "horn", "long"])
			self.horn.playing.long = true

	if Input.is_action_just_released("jump"):
		self.horn.interaction.long = false

		# REMARK: Only temporary solution until issue with not being able to 
		# receive information on whether the sound has finished playing can be
		# obtained
		self.horn.playing.long = false

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func allow_drawing(status : bool) -> void:
	self._drawingArea.allow_drawing(status)

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
func _process(delta: float) -> void:
	self.position.x += DIRECTION * SPEED * delta

	self._horn_fsm()