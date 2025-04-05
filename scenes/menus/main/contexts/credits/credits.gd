extends RichTextLabel

################################################################################
#### REQUIREMENTS ##############################################################
################################################################################
# This script expects the following AutoLoads:                                 
# - FileIO: res://utils/FileIO.gd
#                                                                              
# This script expects the following Globals:                                   
# - Json2BBCode: res://utils/json2BBCode.gd
# - CONS_TRAIN_T: res://settings/globals.gd
################################################################################
################################################################################
################################################################################

################################################################################
#### RESOURCE AND CLASS LOADING ################################################
################################################################################
var _bbcodeparser = Json2BBCode.new()

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
@export var _creditsTextFile : String = "res://scenes/menus/main/text/credits.json"

func _ready() -> void:
	# DESCRIPTION: Load the credits text from file, parse it to BBCode and make
	# sure that the credits context is hidden
	var _creditsTextAsDict = FileIO.json.load(self._creditsTextFile)
	self.text = self._bbcodeparser.parse(_creditsTextAsDict)

# REMARK: Required, as otherwise the BBCode Parser will not be garbage collected 
# when the scene is quit, leading to a "Leaked Instances" error
func _exit_tree() -> void:
	self._bbcodeparser.queue_free()
