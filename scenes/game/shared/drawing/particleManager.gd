extends Node2D

################################################################################
#### CONSTANTS #################################################################
################################################################################
enum VFX_STATES{DEACTIVATED, REVEAL, BLOW_AWAY}

class GRAVITY:
    const REVEAL : Vector3 = Vector3(0,0,0)
    const BLOW_AWAY : Vector3 = Vector3(-120,0,0)

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
var _activateBlowAway : bool = false
var _state : VFX_STATES = VFX_STATES.DEACTIVATED

var _time : float = 0.0

var _activeContent : Array = ["text"]

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _content : Dictionary = {
    "text": {
        "texture": {
            "fp": "res://scenes/game/shared/drawing/sprites/drawables/text2.png"
        },
        "particle_system" : {
            "reference": $text1/GPUParticles2D
        }
    }
}

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func get_emission_texture_of_active_content() -> ImageTexture:
    var _tmp_content : Dictionary = DictionaryParsing.get_by_key_chain_safe(self._content, self._activeContent)
    return load(_tmp_content["texture"]["fp"])

func start_effect() -> void:
    self._content["text"]["particle_system"].reference.process_material.gravity = GRAVITY.REVEAL
    self._content["text"]["particle_system"].reference.emitting = true
    self._state = VFX_STATES.REVEAL

func stop_effect() -> void:
    self._content["text"]["particle_system"].reference.emitting = false
    self._activateBlowAway = true

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
    self._content["text"]["particle_system"].reference.emitting = false

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
func _physics_process(delta: float) -> void:
	# REMARK: Changing particle material properties has to be done inside
	# the physics process function. Outside, especially as an asynchronous
	# call, it will not work and result into an error being thrown
    if self._activateBlowAway:
        # self._content["text"]["particle_system"].reference.process_material.gravity = GRAVITY.BLOW_AWAY
        self._time = 0.0
        self._state = VFX_STATES.BLOW_AWAY
        self._activateBlowAway = false

    match self._state:
        VFX_STATES.BLOW_AWAY:
            if self._time <= self._content["text"]["particle_system"].reference.get_lifetime():
                self._time += delta/1000

            else:
                self._state = VFX_STATES.DEACTIVATED
