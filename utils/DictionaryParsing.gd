extends Node

################################################################################
#### AUTOLOAD REMARKS ##########################################################
################################################################################
# This script is autoloaded as "DictionaryParsing".

################################################################################
#### CONSTANT DEFINITIONS ######################################################
################################################################################
class ERROR_CODES:
	const NO_ERROR : int = 0
	const KEY_NOT_EXISTING : int = -1
	const ELEMENT_NOT_EXPANDABLE : int = -2
	const KEY_TYPE_NOT_SUPPORTED : int = -3

const ERROR_CODES_LUT : Dictionary = {
	self.ERROR_CODES.KEY_NOT_EXISTING : "key '{key}' does not exist.",
	self.ERROR_CODES.ELEMENT_NOT_EXPANDABLE : "Element with '{key}' is not a of type 'Dictionary' and therefor cannot be expanded further.",
	self.ERROR_CODES.KEY_TYPE_NOT_SUPPORTED : "key type not supported."
}

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
var _error : int = self.ERROR_CODES.NO_ERROR

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################

## verifies if the [code]keyChain[/code] is valid for the given 
## [code]Dictionary[/code] and returns [code]true[/code] if it is so.
func is_key_chain_valid(dict : Dictionary, keyChain : Array) -> bool:
	if len(keyChain) != 0:
		var _tmp_key = keyChain[0]

		if _tmp_key in dict:
			var _tmp_keyChain = keyChain.duplicate()
			_tmp_keyChain.remove_at(0)

			if len(_tmp_keyChain) != 0:
				var _tmp_data = dict[_tmp_key]

				if typeof(_tmp_data) == TYPE_DICTIONARY:
					return self.is_key_chain_valid(_tmp_data, _tmp_keyChain)

				else:
					return false
			else:
				return true

		else:
			return false

	else:
		return true

## iterates recursively over all keys found in the [code]dict[code] input [code]Dictionary[/code] 
## and appends all valid key chains to the [code]result[/code]
## key chain data base of type [code]Array[Array][/code].
func find_all_key_chains(dict : Dictionary, result : Array[Array], currentRoot : Array = []) -> void:
	for _key in dict:
		var _tmp_data = dict[_key]

		if typeof(_tmp_data) == TYPE_DICTIONARY:
			var _tmp_newRoot : Array = currentRoot.duplicate()
			_tmp_newRoot.append(_key)

			self.find_all_key_chains(_tmp_data, result, _tmp_newRoot)

		else:
			var _tmp_result : Array = currentRoot.duplicate()
			_tmp_result.append(_key)

			result.append(_tmp_result)

## gets an element of the [code]Dictionary[/code] by recursively
## iterating over the keys provided in the [code]keyChain[/code] and returns its
## value. If the [code]keyChain[/code] is invalid in any form, it will throw an
## error. Due to that and the lack of expression parsing, it is considered to be
## safer as [code]DictionaryParsing.get_by_key_chain_unsafe().[/code][br]
## **Remarks:**[br]
## - The return type can be of any data type[br]
## - If a key from the [code]keyChain[/code] is not valid or an entry cannot be
## expanded any further, the method will throw an error and return [code]null[/code]
func get_by_key_chain_safe(dict : Dictionary, keyChain : Array):
	var _tmp_dictElement = dict

	for key in keyChain:
		if _tmp_dictElement is Dictionary:
			if key in _tmp_dictElement.keys():
				_tmp_dictElement = _tmp_dictElement[key]

			else:
				self._error = self.ERROR_CODES.KEY_NOT_EXISTING
				push_error(self.ERROR_CODES_LUT[self._error].format({"key": key}))
				return

		else:
			self._error = self.ERROR_CODES.ELEMENT_NOT_EXPANDABLE
			push_error(self.ERROR_CODES_LUT[self._error].format({"key": key}))
			return
			
	return _tmp_dictElement

## gets an element of the [code]Dictionary[/code] by creating a command expression
## from the elements of the [code]keyChain[/code] and returns its
## value. If the [code]keyChain[/code] is invalid in any form, it will neither throw an
## error nor show well defined behavior. Due to that and the usage of expression parsing, 
## it is considered to be unsafe and should only be used if the recursive approach of
## [code]DictionaryParsing.get_by_key_chain_safe()[/code] has an intolerable 
## performance penalty.[br]
## **Remarks:**[br]
## - The return type can be of any data type[br]
## - Should be more performant, as not so much data has to be copied (**TODO:** Verify)[br]
func get_by_key_chain_unsafe(dict : Dictionary, keyChain : Array):
	var _tmp_cmdString : String = "dict"
	var _tmp_expression : Expression = Expression.new()

	for _key in keyChain:
		if _key is int:
			_tmp_cmdString += "[" + str(_key) + "]"

		elif _key is String:
			_tmp_cmdString += "[\"" + str(_key) + "\"]"

		else:
			self._error = self.ERROR_CODES.KEY_TYPE_NOT_SUPPORTED

	var _tmp_error = _tmp_expression.parse(_tmp_cmdString, ["dict"])

	if _tmp_error != OK:
		print(_tmp_expression.get_error_text())
		return

	var _tmp_result = _tmp_expression.execute([dict])
	if not _tmp_expression.has_execute_failed():
		return _tmp_result
	
	else:
		return

## sets an element of the [code]Dictionary[/code] by the keys provided in the
## [code]keyChain[/code][br]
## **Remarks:**[br]
## - The [code]value[/code] that is going to be set can be of any data type[br]
## - There is no checking performed whether the specified [code]keyChain[/code]
## is valid[br]
## - The maximum supported nesting depth is [code]5[/code][br]
func set_by_key_chain_safe(dict : Dictionary, keyChain : Array, value) -> void:
	var _tmp_lenKeyChain : int = len(keyChain)

	match _tmp_lenKeyChain:
		1:
			dict[keyChain[0]] = value
		2:
			dict[keyChain[0]][keyChain[1]] = value
		3:
			dict[keyChain[0]][keyChain[1]][keyChain[2]] = value
		4:
			dict[keyChain[0]][keyChain[1]][keyChain[2]][keyChain[3]] = value
		5:
			dict[keyChain[0]][keyChain[1]][keyChain[2]][keyChain[3]][keyChain[4]] = value

		6:
			dict[keyChain[0]][keyChain[1]][keyChain[2]][keyChain[3]][keyChain[4]][keyChain[5]] = value

		_:
			assert(false, "ERROR: Operation is not defined")
