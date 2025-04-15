extends PanelContainer

################################################################################
#### CONSTANTS #################################################################
################################################################################
const _progressLabelText : String = "Drawing Progress: {progress}"
const _thresholdLabelText : String = "Next Threshold: {threshold}"

const _labelRootPath : String = "VBoxContainer/MarginContainer/HBoxContainer/"

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
var _contentMaskResized : Image 
var _contentMaskResizedTexture : Texture2D

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _progressLabel : Label = get_node(self._labelRootPath + "drawingProgress")
@onready var _thresholdLabel : Label = get_node(self._labelRootPath + "nextThreshold")

@onready var _maskResizedDisplay : MarginContainer = $VBoxContainer/resized/mask
@onready var _matteResizedDisplay : MarginContainer = $VBoxContainer/resized/matte
@onready var _matteTimesMaskResizedDisplay : MarginContainer = $VBoxContainer/resized/maskTimesMatte

@onready var _maskOriginalDisplay : MarginContainer = $VBoxContainer/original/mask
@onready var _matteOriginalDisplay : MarginContainer = $VBoxContainer/original/matte
@onready var _matteTimesMaskOriginalDisplay : MarginContainer = $VBoxContainer/original/maskTimesMatte

@onready var _drawingArea : Node2D = get_parent().get_tree().root.get_node("game/railcar/interior/drawingArea")

################################################################################
#### PRIVATE MEMBER FUNCTIONS ##################################################
################################################################################
func _drawing_progress_from_resized_image(progress : float, threshold : float) -> void:
	self._progressLabel.text = self._progressLabelText.format({"progress": "%0.6f" % progress})
	self._thresholdLabel.text = self._thresholdLabelText.format({"threshold": "%0.6f" % threshold})

func _drawing_progress(progress : float, threshold : float) -> void:
	self._progressLabel.text = self._progressLabelText.format({"progress": "%0.6f" % progress})
	self._thresholdLabel.text = self._thresholdLabelText.format({"threshold": "%0.6f" % threshold})

	# DESCRIPTION: Load the new resized matte image
	self._matteResizedDisplay.update_display(ImageTexture.create_from_image(self._drawingArea._matteResizedImage)) 

func _update_texture_helper() -> void:
	self._matteResizedDisplay.update_display(ImageTexture.create_from_image(self._drawingArea._matteResizedImage)) 

func _update_texture_helper_from_resized_image() -> void:
	self._matteResizedDisplay.update_display(self._drawingArea.get_node("mattePaintingResized").get_texture())

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func update_texture() -> void:
	self._contentMaskResized = self._drawingArea.get_content_mask_resized()
	self._contentMaskResizedTexture = ImageTexture.create_from_image(self._contentMaskResized)

	self._maskResizedDisplay.update_display(self._contentMaskResizedTexture)
	self._update_texture_helper()
	self._matteTimesMaskResizedDisplay.update_display(self._contentMaskResizedTexture)

	# DESCRIPTION: Set the shader mask to the correct viewport texture
	var _tmp_material : ShaderMaterial = self._matteTimesMaskResizedDisplay.get_node("SubViewport/TextureRect").material
	_tmp_material.set_shader_parameter("mask", self._matteResizedDisplay.get_viewport_texture())

	self._maskOriginalDisplay.update_display(self._drawingArea.get_content_mask_texture())
	self._matteOriginalDisplay.update_display(self._drawingArea._mattePainting.get_texture())
	self._matteTimesMaskOriginalDisplay.update_display(self._drawingArea._contentReveal.get_texture())
	
################################################################################
#### SIGNAL HANDLING ###########################################################
################################################################################
func _on_drawing_progress(progress : float, threshold : float) -> void:
	self._drawing_progress(progress, threshold)

func _on_texture_update() -> void:
	print_debug("debug drawing progress received texture update signal")
	self.update_texture()

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
	# DESCRIPTION: Connect to the drawing progress signal
	# REMARK: Only temporary, as it is hard coded and the scene tree 
	# architecture will have to be changed to be able to implement 
	# all the new features
	self._drawingArea.drawing_progress.connect(self._on_drawing_progress)
	self._drawingArea.texture_update.connect(self._on_texture_update)
	self._drawingArea.tree_entered.connect(self._on_texture_update)
