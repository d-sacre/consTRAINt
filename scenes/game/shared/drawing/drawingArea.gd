extends Node2D

################################################################################
#### SIGNALS ###################################################################
################################################################################
signal drawing_progress(progress : float, threshold : float)
signal texture_update
signal end_of_demo

################################################################################
#### CONSTANTS #################################################################
################################################################################
class DRAWING:
	enum STATES{DRAWING, NEXT}

	class PROGRESS:
		const RESIZE_FACTOR : float = 1.0/16.0
		const ALPHA_THRESHOLD : int = 128

################################################################################
#### INSTANCES AND OBJECTS #####################################################
################################################################################
var drawing : Dictionary = {
	"origin" : Vector2(0,0),
	"size" : Vector2i(1920, 512),
	"mouse_limits": {
		"x_min" : 0.0,
		"x_max" : 0.0,
		"y_min" : 0.0,
		"y_max" : 0.0
	},
	"brush": {
		"width": self._lineWidth,
		"offsets_from_center": []
	}
}

var _convertIndices : ConvertIndices = ConvertIndices.new(1920)

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
var _drawingAllowed : bool = true
var _lastMousePosition : Vector2 = Vector2.ZERO

var _drawingState : DRAWING.STATES = DRAWING.STATES.DRAWING
var _drawingProgress : float = 0.0
var _drawingProgressEvaluationTimer = 0
var _drawingFinishedThreshold : float = 1.0

var _contentTexture : CompressedTexture2D
var _contentMaskResized : Image = Image.new()
var _contentNonEmptyCoarseLUT : Array[int] = []
var _contentNonEmptyCoarseLength : int = 0
var _contentRevealLUT : Array[int] = []
var _lastContent : bool = false
var _lastContentFinished : bool = false

var _resizedSize1D : int = 0
var _resizedSize2D : Vector2i = Vector2i.ZERO

var _matteResizedImage : Image

var _requestShowNextButton : bool = false
var _nextButtonHiddenLocked : bool = false

################################################################################
#### EXPORT MEMBER VARIABLES ###################################################
################################################################################
@export var _lineWidth : float = 75.0 
@export var _pointsMaximum : int = 30

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _lineVisual : Line2D = $playerFeedback/lineVisualizer/Line2D
@onready var _lineMattePainting : Line2D = $mattePainting/lineVisualizer/Line2D
@onready var _brush : Node2D = $playerFeedback/brush

@onready var _mattePainting : SubViewport = $mattePainting
@onready var _mattePaintingPersistence : Sprite2D = $mattePainting/mattePersistent

@onready var _contentReveal : SubViewport = $contentReveal
@onready var _contentRevealSprite : Sprite2D = $contentReveal/mask

@onready var _drawingResult : Sprite2D = $drawingResult

@onready var _particleManager : Node2D = $drawingShape/particleManager

@onready var _nextButton : Button = $ui/next

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

func _save_to_texture(viewport : SubViewport = self._mattePainting) -> Texture2D:
	# REMARK: Not working in this use case; stops the complete drawing logic.
	# await RenderingServer.frame_post_draw 
	var _tmp_image : Image = viewport.get_texture().get_image()
	var _tmp_texture : ImageTexture = ImageTexture.create_from_image(_tmp_image)

	return _tmp_texture

func _save_drawing_to_texture_and_prune_line(viewport : SubViewport = self._mattePainting, line : Line2D = self._lineMattePainting) -> Texture2D:
	# DESCRIPTION: Acquire the current display of the viewport and store it into
	# a static image texture
	var _tmp_texture : ImageTexture = self._save_to_texture(viewport)

	# DESCRIPTION: Clear all the points
	line.points = []

	return _tmp_texture

func _clear_matte_painting() -> void:
	self._lineMattePainting.points = []
	self._mattePaintingPersistence.texture = null

func _resize(image : Image, factor : float = DRAWING.PROGRESS.RESIZE_FACTOR) -> Image:
	var _tmp_image : Image = Image.new()
	var _tmp_size : Vector2i = image.get_size()

	_tmp_image.copy_from(image)
	_tmp_size = Vector2i(
		int(float(_tmp_size.x) * factor),
		int(float(_tmp_size.y) * factor)
	)

	_tmp_image.resize(_tmp_size.x, _tmp_size.y, Image.Interpolation.INTERPOLATE_NEAREST)

	return _tmp_image 

func _convert_image_to_bw_mask_based_on_alpha(image : Image, alpha : int = DRAWING.PROGRESS.ALPHA_THRESHOLD) -> Image:
	var _tmp_image : Image = Image.new()
	var _tmp_size : Vector2i = image.get_size()

	_tmp_image.copy_from(image)

	for _x in range(0, _tmp_size.x - 1):
		for _y in range(0, _tmp_size.y - 1):
			var _tmp_pixel = _tmp_image.get_pixel(_x, _y)

			if _tmp_pixel.a8 >= alpha:
				_tmp_image.set_pixel(_x, _y, Color.WHITE)
			
			else:
				_tmp_image.set_pixel(_x, _y, Color.BLACK)

	return _tmp_image

func _create_white_pixel_lut(image : Image) -> Array[int]:
	var _tmp_lut : Array[int] = []
	var _tmp_size : Vector2i = image.get_size()

	for _x in range(0, _tmp_size.x - 1):
		for _y in range(0, _tmp_size.y - 1):
			var _tmp_pixel = image.get_pixel(_x, _y)

			if _tmp_pixel == Color.WHITE:
				_tmp_lut.append(self._convertIndices.from_2d_to_1d(Vector2(_x, _y)))

	_tmp_lut.sort()

	return _tmp_lut

func _convert_content_texture_to_non_empty_coarse_lut() -> int:
	# DESCRIPTION: Load the image
	var _tmp_image : Image = self._contentTexture.get_image()

	# DESCRIPTION: Convert image to a black and white mask and calculate
	# its properties
	var _tmp_bwMask : Image = self._convert_image_to_bw_mask_based_on_alpha(_tmp_image)
	var _tmp_bwMaskResized : Image = self._resize(_tmp_bwMask)
	self._resizedSize2D = _tmp_bwMaskResized.get_size()
	var _tmp_maskSize1d : int = self._resizedSize2D.x * self._resizedSize2D.y

	# DESCRIPTION: Copying data which is important for debugging
	# REMARKS: 
	# - Not a good position from an architectural point of view
	# - Should be removed when no longer needed to save on resources
	self._contentMaskResized.copy_from(_tmp_bwMaskResized)

	# DESCRIPTION: Create the LUT from the mask
	self._contentNonEmptyCoarseLUT = self._create_white_pixel_lut(_tmp_bwMaskResized)
	self._contentNonEmptyCoarseLength = len(self._contentNonEmptyCoarseLUT)

	return _tmp_maskSize1d

func _create_circular_area_offsets(diameter : float) -> Array[Vector2]:
	var _tmp_radius = diameter/2
	var _tmp_areaOutline : Array[Vector2] = []
	var _tmp_areaFilled : Array[Vector2] = []

	# DESCRIPTION: Calculate the circle outline with the Method of Jesko
	# DERIVED FROM: https://de.wikipedia.org/wiki/Rasterung_von_Kreisen
	var t1 = _tmp_radius / 16;
	var t2 = 0;
	var x  = _tmp_radius;
	var y  = 0;

	while (x >= y):
		# DESCRIPTION: Set the octants
		_tmp_areaOutline.append(Vector2(x, y))
		_tmp_areaOutline.append(Vector2(x, -y))
		_tmp_areaOutline.append(Vector2(-x, y))
		_tmp_areaOutline.append(Vector2(-x, -y))
		_tmp_areaOutline.append(Vector2(y, x))
		_tmp_areaOutline.append(Vector2(y, -x))
		_tmp_areaOutline.append(Vector2(-y, x))
		_tmp_areaOutline.append(Vector2(-y, -x))

		# DESCRIPTION: Do iteration step
		y  = y + 1;
		t1 = t1 + y;
		t2 = t1 - x;

		if (t2 >= 0):
			t1 = t2;
			x  = x - 1;

	# DESCRIPTION: Fill inside of circle
	# DESCRIPTION: Find all the row coordinates that are existing
	var _tmp_rows : Array = []
	var _tmp_outlineSortedByRow : Dictionary = {}
	var _tmp_outlineSortedByRowMinMax : Dictionary = {}

	for _offset in _tmp_areaOutline:
		if not _offset.y in _tmp_rows:
			_tmp_rows.append(_offset.y)
			_tmp_outlineSortedByRow[_offset.y] = []
			_tmp_outlineSortedByRowMinMax[_offset.y] = {"min": 0.0, "max": 0.0}

	_tmp_rows.sort()
	
	# DESCRIPTION: Sort the column position by the rows
	for _offset in _tmp_areaOutline:
		_tmp_outlineSortedByRow[_offset.y].append(_offset.x)

	# DESCRIPTION: Determine colum minimum/maximum for each row
	for _row in _tmp_outlineSortedByRow:
		var _tmp_rowData : Array = _tmp_outlineSortedByRow[_row]

		_tmp_outlineSortedByRowMinMax[_row]["min"] = _tmp_rowData.min()
		_tmp_outlineSortedByRowMinMax[_row]["max"] = _tmp_rowData.max()

	# DESCRIPTION: Create all the Vectors corresponding to a filled circle
	for _row in _tmp_outlineSortedByRow:
		var _tmp_min : float = _tmp_outlineSortedByRowMinMax[_row]["min"]
		var _tmp_max : float = _tmp_outlineSortedByRowMinMax[_row]["max"]

		for _i in range(_tmp_min, _tmp_max, 1):
			_tmp_areaFilled.append(Vector2(_i, _row))

	return _tmp_areaFilled

func _update_drawing_properties(drawingOrigin : Vector2, drawingSize : Vector2i, brushWidth : float = self._lineWidth) -> void:
	print_debug("Update drawing properties")
	self.drawing.origin = drawingOrigin
	self.drawing.size = drawingSize 
	self.drawing.brush.width = brushWidth

	self.drawing.mouse_limits.x_min = self.drawing.origin.x
	self.drawing.mouse_limits.x_max = self.drawing.origin.x + self.drawing.size.x

	self.drawing.mouse_limits.y_min = self.drawing.origin.y
	self.drawing.mouse_limits.y_max = self.drawing.origin.y + self.drawing.size.y

	# REMARK: Factor 3 hard coded, as otherwise it does not lead to the correct results
	# TODO: Has to be removed when the bug in the tracking logic is found
	self.drawing.brush.offsets_from_center = self._create_circular_area_offsets(3*self.drawing.brush.width * DRAWING.PROGRESS.RESIZE_FACTOR)
	
func _set_content_texture(texture : CompressedTexture2D) -> void:
	print_debug("Set content texture")
	self._contentTexture = texture
	self._contentRevealSprite.texture = self._contentTexture

	# DESCRIPTION: Remove old index conversion and add new one
	self._convertIndices.queue_free()
	self._convertIndices = ConvertIndices.new(int(self._mattePainting.size.x * DRAWING.PROGRESS.RESIZE_FACTOR))

	# DESCRIPTION: Create LUT from content texture
	self._resizedSize1D = self._convert_content_texture_to_non_empty_coarse_lut()

	# DESCRIPTION: Setting up debugging data
	# REMARK: Should be removed when no longer needed to save on resources
	self._matteResizedImage = Image.create_empty(self._resizedSize2D.x, self._resizedSize2D.y, false, Image.FORMAT_RGBAF)

	for _x in range(0, self._resizedSize2D.x - 1):
		for _y in range(0, self._resizedSize2D.y - 1):
			self._matteResizedImage.set_pixel(_x, _y, Color.BLACK)

	# DESCRIPTION: Update data required for mouse/progress tracking
	self._update_drawing_properties(self._drawingResult.position, self._mattePainting.size)

	# DESCRIPTION: Reset all the progress and tracking data to default
	self._drawingProgress = 0.0
	self._contentRevealLUT = []
	self._contentRevealLUT.resize(self._resizedSize1D)
	self._drawingFinishedThreshold = self._particleManager.get_active_content_drawing_finished_threshold()

	self.texture_update.emit()

## tracks the drawing progress based upon the mouse position[br]
## ### Remark[br] 
## Logic does not behave as intended (the recorded progress values 
## are way too low). Even with the temporary magic number increasing the brush
## size, the result is not as expected[br]
## ### TODO[br]
## Fix logic so that when everything is uncovered, the progress is 1.0
func _track_drawing_progress(mousePosition : Vector2) -> void:
	var _tmp_indicesToUpdate : Array = []

	var _tmp_mousePositionValidX : bool = (mousePosition.x >= self.drawing.mouse_limits.x_min) and (mousePosition.x <= self.drawing.mouse_limits.x_max)
	var _tmp_mousePositionValidY : bool = (mousePosition.y >= self.drawing.mouse_limits.y_min) and (mousePosition.y <= self.drawing.mouse_limits.y_max)

	# DESCRIPTION: Verify whether the mouse position is inside the drawing area
	if _tmp_mousePositionValidX and _tmp_mousePositionValidY:
		# DESCRIPTION: Rescale the position to match the scaled progress mask
		var _tmp_positionScaled : Vector2 = Vector2(0,0)
		_tmp_positionScaled.x = mousePosition.x * DRAWING.PROGRESS.RESIZE_FACTOR
		_tmp_positionScaled.y = mousePosition.y * DRAWING.PROGRESS.RESIZE_FACTOR

		# DESCRIPTION: Calculate all the points inside a circle with the brush radius 
		# around the mouse position 
		for _offset in self.drawing.brush.offsets_from_center:
			var _tmp_positionScaledOffset : Vector2 = _tmp_positionScaled + _offset

			# DESCRIPTION: Verify if the points are still within the drawing area boundary
			var _tmp_positionOffsetValidX : bool = (_tmp_positionScaledOffset.x >= self.drawing.mouse_limits.x_min * DRAWING.PROGRESS.RESIZE_FACTOR) and (_tmp_positionScaledOffset.x <= self.drawing.mouse_limits.x_max * DRAWING.PROGRESS.RESIZE_FACTOR)
			var _tmp_positionOffsetValidY : bool = (_tmp_positionScaledOffset.x >= self.drawing.mouse_limits.y_min * DRAWING.PROGRESS.RESIZE_FACTOR) and (_tmp_positionScaledOffset.y <= self.drawing.mouse_limits.y_max * DRAWING.PROGRESS.RESIZE_FACTOR)

			if _tmp_positionOffsetValidX and _tmp_positionOffsetValidY:
				_tmp_indicesToUpdate.append(self._convertIndices.from_2d_to_1d(_tmp_positionScaled))

				# DESCRIPTION: Set values in 2d Array for debug purposes
				if OS.is_debug_build():
					var _tmp_columnHelper : int = int(floor(_tmp_positionScaled.x))
					var _tmp_rowHelper : int = int(floor(_tmp_positionScaled.y))

					var _tmp_column : int = max(0, min(_tmp_columnHelper, self._resizedSize2D.x - 1))
					var _tmp_row : int = max(0, min(_tmp_rowHelper, self._resizedSize2D.y - 1))

					self._matteResizedImage.set_pixel(_tmp_column, _tmp_row, Color.WHITE)

		if _tmp_indicesToUpdate != []:
			for _index in _tmp_indicesToUpdate:
				self._contentRevealLUT[_index] = 1

func _calculate_drawing_progress() -> void:
	var _tmp_progress : float = 0.0

	for _index in self._contentNonEmptyCoarseLUT:
		_tmp_progress += float(self._contentRevealLUT[_index])
	
	self._drawingProgress = _tmp_progress/self._contentNonEmptyCoarseLength

	self.drawing_progress.emit(self._drawingProgress, self._drawingFinishedThreshold)

func _evaluate_drawing_progress() -> void:
	var _tmp_status : bool = false

	# REMARK: Currently hardcoded. Has to be changed after the progress
	# tracking logic has been updated to function properly!
	if self._drawingProgress >= self._drawingFinishedThreshold:
		if not self._drawingState == DRAWING.STATES.NEXT:
			if not self._lastContent:
				_tmp_status = true

			else:
				self._lastContentFinished = true
				_tmp_status = true

	self._requestShowNextButton = _tmp_status

func _determine_next_button_visibility() -> void:
	var _tmp_status : bool = false

	if self._requestShowNextButton:
		if not self._nextButtonHiddenLocked:
			_tmp_status = true

	self._nextButton.visible = _tmp_status

func _show_drawing_visualization(status : bool) -> void:
	self._lineVisual.visible = status
	self._brush.visible = status

func _initialize_new_drawing() -> void:
	var _tmp_timeAfter = Time.get_unix_time_from_system()
	self._drawingProgress = 0.0
	self._clear_matte_painting()
	self._set_content_texture(self._particleManager.get_emission_texture_of_active_content())
	self._calculate_drawing_progress()
	self._nextButtonHiddenLocked = false
	self._drawingState = DRAWING.STATES.DRAWING
	self._particleManager.start_effect()

	# # DESCRIPTION: Set brush/mouse to center of drawing area and remove any tail
	# Input.warp_mouse(
	# 	Vector2(
	# 		(self.drawing.mouse_limits.x_min + self.drawing.mouse_limits.x_max)/2,
	# 		(self.drawing.mouse_limits.y_min + self.drawing.mouse_limits.y_max)/2
	# 	)
	# )
	# self._clear_matte_painting()
	self._show_drawing_visualization(true)

func _clear_old_drawing() -> void:
	self._show_drawing_visualization(false)
	self._drawingState = DRAWING.STATES.NEXT
	self._particleManager.stop_effect()
	self._requestShowNextButton = false
	self._nextButtonHiddenLocked = true
	self._determine_next_button_visibility()
	await get_tree().create_timer(2).timeout

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func allow_drawing(status : bool) -> void:
	self._drawingAllowed = status

	self._lineVisual.visible = status
	self._lineMattePainting.visible = status
	self._brush.visible = status

func get_content_mask_texture() -> Texture2D:
	return self._contentTexture

func get_content_mask_resized() -> Image:
	return self._contentMaskResized

################################################################################
#### SIGNAL HANDLING ###########################################################
################################################################################
func _on_next_button_pressed() -> void:
	await self._clear_old_drawing()
	self._particleManager.load_next_content()

	if not self._lastContentFinished:
		self._initialize_new_drawing()

	else:
		print_debug("Emit end of demo signal")
		self.end_of_demo.emit()
		
func _on_last_content() -> void:
	print_debug("last content signal received")
	self._lastContent  = true

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
	# DESCRIPTION: Connect signals
	self._nextButton.pressed.connect(self._on_next_button_pressed)
	self._particleManager.last_content.connect(self._on_last_content)

	self._particleManager.start_effect()
	self._set_content_texture(self._particleManager.get_emission_texture_of_active_content())

	self.drawing.brush.width = self._lineWidth

	# DESCRIPTION: Setting up the Line2d
	self._lineVisual.width = self.drawing.brush.width
	self._lineMattePainting.width = self.drawing.brush.width

	# DESCRIPTION: Setting up visibility of elements
	self._nextButton.visible = false

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
func _process(_delta: float) -> void:
	if self._drawingAllowed:
		var _tmp_mousePosition : Vector2 = self.get_local_mouse_position()

		# DESCRIPTION: Update 
		self._brush.position = _tmp_mousePosition

		self._manage_line(self._lineVisual, _tmp_mousePosition, self._lastMousePosition)
		self._manage_line(self._lineMattePainting, _tmp_mousePosition, self._lastMousePosition, false)

		self._track_drawing_progress(_tmp_mousePosition)

		self._lastMousePosition = _tmp_mousePosition

		# DESCRIPTION: Manage length of line used for texture creation. If exceeding
		# a certain length, save the current display of the viewport into a static 
		# texture and update the sprite's texture accordingly
		if self._lineMattePainting.points.size() > 500:
			self._mattePaintingPersistence.texture = self._save_drawing_to_texture_and_prune_line()

		# DESCRIPTION: Determine and evaluate the drawing process
		if self._drawingProgressEvaluationTimer != 100:
			self._drawingProgressEvaluationTimer += 1
		
		else:
			self._drawingProgressEvaluationTimer = 0
			self._calculate_drawing_progress()
			self._evaluate_drawing_progress()

		self._determine_next_button_visibility()