extends Node2D

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
var _drawingAllowed : bool = true
var _lastMousePosition : Vector2 = Vector2.ZERO

################################################################################
#### EXPORT MEMBER VARIABLES ###################################################
################################################################################
@export var _pointsMaximum : int = 30

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _lineVisual : Line2D = $playerFeedback/lineVisualizer/Line2D
@onready var _lineTexture : Line2D = $mattePainting/lineVisualizer/Line2D
@onready var _brush : Node2D = $playerFeedback/brush

@onready var _mattePainting : SubViewport = $mattePainting
@onready var _mattePersistence : Sprite2D = $mattePainting/mattePersistent

################################################################################
#### PRIVATE MEMBER FUNCTIONS ##################################################
################################################################################
func _manage_line(line : Line2D, newPoint : Vector2, lastPoint : Vector2, remove : bool = true) -> void:
	if remove:
		line.add_point(newPoint)

		if line.points.size() > self._pointsMaximum:
			line.remove_point(0)

	else:
		if newPoint != lastPoint:
			line.add_point(newPoint)

func _save_to_texture_and_prune() -> Texture2D:
	# DESCRIPTION: Acquire the current display of the viewport and store it into
	# a static image texture
	var _tmp_image : Image = self._mattePainting.get_texture().get_image()
	var _tmp_texture : ImageTexture = ImageTexture.create_from_image(_tmp_image)

	# DESCRIPTION: Clear all the points
	self._lineTexture.points = []

	return _tmp_texture

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

		# DESCRIPTION: Update 
		self._brush.position = _tmp_mousePosition

		self._manage_line(self._lineVisual, _tmp_mousePosition, _lastMousePosition)
		self._manage_line(self._lineTexture, _tmp_mousePosition, _lastMousePosition, false)

		self._lastMousePosition = _tmp_mousePosition

		# DESCRIPTION: Manage length of line used for texture creation. If exceeding
		# a certain length, save the current display of the viewport into a static 
		# texture and update the sprite's texture accordingly
		if self._lineTexture.points.size() > 500:
			self._mattePersistence.texture = self._save_to_texture_and_prune()
			
