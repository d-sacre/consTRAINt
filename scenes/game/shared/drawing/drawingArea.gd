extends Node2D

var _drawingAllowed : bool = true

@export var _pointsMaximum : int = 30

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _lineVisual : Line2D = $playerFeedback/lineVisualizer/Line2D
@onready var _lineTexture : Line2D = $maskCreation/lineVisualizer/Line2D
@onready var _brush : Node2D = $playerFeedback/brush

################################################################################
#### PRIVATE MEMBER FUNCTIONS ##################################################
################################################################################
func _manage_line(line : Line2D, position : Vector2, remove : bool = true) -> void:
	line.add_point(position)

	if remove:
		if line.points.size() > self._pointsMaximum:
			line.remove_point(0)

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func allow_drawing(status : bool) -> void:
	self._drawingAllowed = status

	self._lineVisual.visible = status
	self._lineTexture.visible = status
	self._brush.visible = status

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
func _process(_delta: float) -> void:
	if self._drawingAllowed:
		var _tmp_mousePosition : Vector2 = self.get_local_mouse_position()
		self._brush.position = _tmp_mousePosition

		self._manage_line(self._lineVisual, _tmp_mousePosition)
		self._manage_line(self._lineTexture, _tmp_mousePosition, false)
			
