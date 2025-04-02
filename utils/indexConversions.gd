extends Node

class_name ConvertIndices

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
var _width : int = 0

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################

## convert 1d [code]index[/code] to 2d array index
## [codeblock]
## c -> x,y
## x = c % maxWidth
## y = c / maxWidth # normal integer division
## y = c / (maxWidth - c % maxWidth) 
## [/codeblock]
func from_1d_to_2d(index : int) -> Vector2:
    var x : int = index % self._width
    @warning_ignore("integer_division")
    var y : int = index / self._width 

    return Vector2(x,y)

## conversion of 2d [code]Array[/code] index to 1d index
## [codeblock]
## x, y -> c
## x + y * maxWidth = c
## [/codeblock]
func from_2d_to_1d(index2D : Vector2) -> int:
    return int(index2D.x) + int(index2D.y) * self._width # old (wrong, or only working for square grids!?)

################################################################################
#### GODOT LOADTIME FUNCTION OVERRIDES #########################################
################################################################################
func _init(width : int) -> void:
    self._width = width

################################################################################
#### GODOT RUNTIME FUNCTION OVERRIDES ##########################################
################################################################################
func _exit_tree() -> void:
    self.queue_free()