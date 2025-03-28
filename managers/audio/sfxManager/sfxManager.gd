extends Node

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
var _sfxDB: Dictionary = {}
var _sfxKeyChainTable : Array[Array] = []
	
################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################

func initialize() -> void:
	# DESCRIPTION: Create the song key chain table
	# REMARK: Parsing step required to remove unwanted keys, since 
	# DictionaryParsing.find_all_key_chains() steps through the complete hierachy
	# and would also return e.g. object references, which would kill the logic
	var _tmp_keyChainTable : Array[Array] = []
	DictionaryParsing.find_all_key_chains(self._sfxDB, _tmp_keyChainTable)

	# DESCRIPTION: Remove all the unwanted keys
	var _tmp_keyChainTableFiltered : Array[Array] = []

	for _keyChain in _tmp_keyChainTable:
		for _key in AudioManager._metaPlayerValidKeys:
			_keyChain.erase(_key)
		
		_tmp_keyChainTableFiltered.append(_keyChain)

	# DESCRIPTION: Add all the filtered key chains to the final table and make 
	# sure that each song is only added once
	self._sfxKeyChainTable = []

	for _keyChain in _tmp_keyChainTableFiltered: 
		if not _keyChain in  self._sfxKeyChainTable:
			self._sfxKeyChainTable.append(_keyChain)

func play_sound(keyChain: Array) -> void:
	var _tmp_data : Dictionary = DictionaryParsing.get_by_key_chain_safe(self._sfxDB, keyChain)
	_tmp_data.reference.mplay()

func stop_everything() -> void:
	for _keyChain in self._sfxKeyChainTable:
		var _tmp_sfx : Dictionary = DictionaryParsing.get_by_key_chain_safe(self._sfxDB, _keyChain)
		
		if _tmp_sfx.reference.mplaying:
			_tmp_sfx.reference.mstop()