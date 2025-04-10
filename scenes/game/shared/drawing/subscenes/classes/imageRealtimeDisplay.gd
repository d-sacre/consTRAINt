class_name ImageRealtimeDisplay

extends MarginContainer

################################################################################
#### EXPORT MEMBER VARIABLES ###################################################
################################################################################
@export var _name : String = "Name"

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _viewportContent : TextureRect = $SubViewport/TextureRect
@onready var _nameLabel : Label = $VBoxContainer/name

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func update_display(texture : Texture2D) -> void:
    self._viewportContent.texture = texture

func get_viewport_texture() -> ViewportTexture:
    return $SubViewport.get_texture()

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
    self._nameLabel.text = _name