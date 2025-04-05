extends Node2D

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _trackInFront : Sprite2D = $parallaxBackground/railroadTrack/railroadTrack/foreground

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
	# DESCRIPTION: Setting the z-indices to achieve correct layering with other
	# elements
	# REMARK: Usage of CanvasLayer not possible, because no scrolling would 
	# occur (if not each CanvasLayer would get a suitable camera attached)
	self._trackInFront.z_as_relative = false
	self._trackInFront.z_index = CONS_TRAIN_T.Z_INDEX.GLOBAL.TRACK_FRONT
