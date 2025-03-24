extends Node

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
var _sfxDB: Dictionary = {}

func _walk_db_and_stop_everything(data : Dictionary):
	if "reference" in data:
		data["reference"].mstop()

	else:
		for _key in data:
			self._walk_db_and_stop_everything(data[_key])
	
################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################

func play_sound(keyChain: Array) -> void:
	var _tmp_data : Dictionary = DictionaryParsing.get_by_key_chain_safe(self._sfxDB, keyChain)
	_tmp_data.reference.mplay()

func stop_everything() -> void:
	self._walk_db_and_stop_everything(self._sfxDB)
