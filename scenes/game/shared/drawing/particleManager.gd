extends Node2D
################################################################################
#### SIGNALS ###################################################################
################################################################################
signal last_content

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

var _activeContentKeyChain : Array = ["1_this-is-a-tech-demo"] 
var _contentOrder : Array[Array] = [
    ["1_this-is-a-tech-demo"],
    ["2_to-show-that"],
    ["3_not-only-text"],
    ["4_but-also-images"],
    ["5_image-bw"],
    ["6_even-in-color"]
]
var _contentOrderIndex : int = 0
var _lastContent : bool = false
var _noMoreNewContent : bool = false

var _activeParticleSystem : GPUParticles2D = null

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _content : Dictionary = {
    "1_this-is-a-tech-demo": {
        "texture": {
            "fp": "res://scenes/game/open/assets/2d/drawables/1_this-is-a-tech-demo.png",
            "next_threshold": 0.28
        },
        "particle_system" : {
            "reference": $text1/GPUParticles2D
        }
    },
    "2_to-show-that": {
        "texture": {
            "fp": "res://scenes/game/open/assets/2d/drawables/2_to-show-that.png",
            "next_threshold": 0.25
        },
        "particle_system" : {
            "reference": $text2/GPUParticles2D
        }
    },
    "3_not-only-text": {
        "texture": {
            "fp": "res://scenes/game/open/assets/2d/drawables/3_not-only-text.png",
            "next_threshold": 0.3
        },
        "particle_system" : {
            "reference": $text3/GPUParticles2D
        }
    },
    "4_but-also-images": {
        "texture": {
            "fp": "res://scenes/game/open/assets/2d/drawables/4_but-also-images.png",
            "next_threshold": 0.3 #0.3
        },
        "particle_system" : {
            "reference": $text4/GPUParticles2D
        }
    },
    "5_image-bw": {
        "texture": {
            "fp": "res://scenes/game/open/assets/2d/drawables/5_image-bw.png",
            "next_threshold": 0.3 #0.3
        },
        "particle_system" : {
            "reference": $text5/GPUParticles2D
        }
    },
    "6_even-in-color": {
        "texture": {
            "fp": "res://scenes/game/open/assets/2d/drawables/6_even-in-color.png",
            "next_threshold": 0.3 #0.3
        },
        "particle_system" : {
            "reference": $text6/GPUParticles2D
        }
    }
}

################################################################################
#### PRIVATE MEMBER FUNCTIONS ##################################################
################################################################################
func _increment_content_order_index() -> void:
    # DESCRIPTION: Determine the next content index
    if self._contentOrderIndex + 1 < len(self._contentOrder) - 1:
        self._contentOrderIndex += 1

    else:
        self._contentOrderIndex = len(self._contentOrder) - 1
        self.last_content.emit()
        self._lastContent = true

func _update_active_content_key_chain() -> void:
    self._activeContentKeyChain = self._contentOrder[self._contentOrderIndex]

func _set_active_particle_system() -> void:
    var _tmp_keyChain : Array = self._activeContentKeyChain.duplicate()
    _tmp_keyChain.append_array(["particle_system", "reference"])
    self._activeParticleSystem = DictionaryParsing.get_by_key_chain_safe(self._content, _tmp_keyChain)

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func get_emission_texture_of_active_content() -> ImageTexture:
    var _tmp_content : Dictionary = DictionaryParsing.get_by_key_chain_safe(self._content, self._activeContentKeyChain)
    return load(_tmp_content["texture"]["fp"])

func get_active_content_drawing_finished_threshold() -> float:
    var _tmp_keyChain : Array = self._activeContentKeyChain.duplicate()
    _tmp_keyChain.append_array(["texture", "next_threshold"])

    return DictionaryParsing.get_by_key_chain_safe(self._content, _tmp_keyChain)

func start_effect() -> void:
    if not self._noMoreNewContent:
        self._activeParticleSystem.process_material.gravity = GRAVITY.REVEAL
        self._activeParticleSystem.visible = true
        self._activeParticleSystem.emitting = true
        self._state = VFX_STATES.REVEAL

func stop_effect() -> void:
    self._activeParticleSystem.emitting = false
    self._activateBlowAway = true

func is_last_content() -> bool:
    return true

func load_next_content() -> void:
    self._increment_content_order_index()
    self._update_active_content_key_chain()

    self._set_active_particle_system()

func end_of_content() -> void:
     if self._lastContent:
        self._activeParticleSystem.visible = false
        self._activeParticleSystem.emitting = false
        self._noMoreNewContent = true
        
################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
    # DESCRIPTION: Set all particle systems to not emitting and hidden
    # REMARKS: Only works as long as no nesting is allowed!
    for _contentKey in self._content:
        self._content[_contentKey]["particle_system"].reference.emitting = false
        self._content[_contentKey]["particle_system"].reference.visible = false

    # DESCRIPTION: Set the active particle system to its default
    self._set_active_particle_system()

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
func _physics_process(delta: float) -> void:
    # REMARK: Changing particle material properties has to be done inside
    # the physics process function. Outside, especially as an asynchronous
    # call, it will not work and result into an error being thrown
    if self._activateBlowAway:
        self._activeParticleSystem.process_material.gravity = GRAVITY.BLOW_AWAY
        self._time = 0.0
        self._state = VFX_STATES.BLOW_AWAY
        self._activateBlowAway = false

    match self._state:
        VFX_STATES.BLOW_AWAY:
            if self._time <= self._activeParticleSystem.get_lifetime():
                self._time += delta/1000

            else:
                self._state = VFX_STATES.DEACTIVATED