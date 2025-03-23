extends Node2D

var _drawingAllowed : bool = true

@export var _pointsMaximum : int = 30

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _line : Line2D = $Sprite2D/Line2D
@onready var _brush : Node2D = $brush

func allow_drawing(status : bool) -> void:
	self._drawingAllowed = status

	self._line.visible = status
	self._brush.visible = status

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
func _process(_delta: float) -> void:
	if self._drawingAllowed:
		var _tmp_mousePosition : Vector2 = self.get_local_mouse_position()
		self._brush.position = _tmp_mousePosition
		# $CPUParticles2D.position = _tmp_mousePosition
		self._line.add_point(self.get_local_mouse_position())

		if self._line.points.size() > self._pointsMaximum:
			self._line.remove_point(0)
			
		#_tmp_mousePosition.x /= get_viewport_rect().size.x
		#_tmp_mousePosition.y /= get_viewport_rect().size.y
		#get_material().set_shader_parameter("target", _tmp_mousePosition)
