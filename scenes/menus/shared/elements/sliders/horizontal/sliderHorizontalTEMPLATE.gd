@tool
extends HBoxContainer

################################################################################
#### CUSTOM SIGNAL DEFINITIONS #################################################
################################################################################
signal settings_value_changed

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
var _keyChain : Array = []

################################################################################
#### EXPORT MEMBER VARIABLES ###################################################
################################################################################
@export_category("General")
@export var _name : String = "Name"

@export_category("Slider")
@export var _minimum : float = 0.0
@export var _maximum : float = 100.0
@export var _step : float = 1.0

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _nameLabel : Label = $name
@onready var _slider : HSlider = $slider
@onready var _valueLabel : Label = $value

################################################################################
#### PRIVATE MEMBER FUNCTIONS ##################################################
################################################################################
func _update_display() -> void:
	self._valueLabel.text = str(int(self._slider.value)) + "/" + str(int(self._maximum))

func _initialize_properties() -> void:
	self._nameLabel.text = self._name
	self._slider.min_value = self._minimum
	self._slider.max_value = self._maximum
	self._slider.step = self._step
	self._update_display()

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func initialize(keyChain : Array, value : float) -> void:
	self._keyChain = keyChain
	self._slider.value = value

func set_value_silent(value : float) -> void:
# func update_display(value : float) -> void:
	self._slider.set_value_no_signal(value)
	self._update_display()

################################################################################
#### SIGNAL HANDLING ###########################################################
################################################################################
func _on_slider_value_changed(value : float) -> void:
	self._update_display()
	self.settings_value_changed.emit(self._keyChain, value)

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _ready() -> void:
	self._initialize_properties()

	self._slider.value_changed.connect(_on_slider_value_changed)

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
func _process(_delta : float) -> void:
	if Engine.is_editor_hint():
		self._initialize_properties()
