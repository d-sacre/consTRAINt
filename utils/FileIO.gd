extends Node

################################################################################
#### AUTOLOAD REMARKS ##########################################################
################################################################################
# This script is autoloaded as "FileIO".

################################################################################
#### PUBLIC MEMBERS ############################################################
################################################################################

# DESCRIPTION: Responsible for handling all the JSON related File I/O
class json:

	## Loads JSON File from file path specified by `fp` and returns the contents
	## of the file either as `Dictionary` or `Array` depending on the data type
	## of the input file
	static func load(fp : String):
		var _tmp_jsonAsText = FileAccess.get_file_as_string(fp)
		var _tmp_jsonAsDict = JSON.parse_string(_tmp_jsonAsText)
	
		return _tmp_jsonAsDict

	## Writes [code]data[/code] provided in JSON format to a JSON File 
	## at the location specified by `fp`[br]
	## **Remark:** JSON Data in both [code]Dictionary[/code] and 
	## [code]Array[/code] format is accepted
	static func save(fp : String, data) -> void:
		var _tmp_file = FileAccess.open(fp, FileAccess.WRITE)
		_tmp_file.store_line(JSON.stringify(data))
		_tmp_file.close()
