extends Node

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
var _musicDB : Dictionary = {}
var _musicKeyChainTable : Array[Array] = []

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func initialize() -> void:
	# DESCRIPTION: Create the song key chain table
	# REMARK: Parsing step required to remove unwanted keys, since 
	# DictionaryParsing.find_all_key_chains() steps through the complete hierachy
	# and would also return e.g. object references, which would kill the logic
	var _tmp_keyChainTable : Array[Array] = []
	DictionaryParsing.find_all_key_chains(self._musicDB, _tmp_keyChainTable)

	# DESCRIPTION: Remove all the unwanted keys
	var _tmp_keyChainTableFiltered : Array[Array] = []

	for _keyChain in _tmp_keyChainTable:
		for _key in AudioManager._metaPlayerValidKeys:
			_keyChain.erase(_key)
		
		_tmp_keyChainTableFiltered.append(_keyChain)

	# DESCRIPTION: Add all the filtered key chains to the final table and make 
	# sure that each song is only added once
	self._musicKeyChainTable = []

	for _keyChain in _tmp_keyChainTableFiltered:
		if not _keyChain in  self._musicKeyChainTable:
			self._musicKeyChainTable.append(_keyChain)

func is_song_playing_by_key_chain(keyChain : Array) -> bool:
	var _tmp_data : Dictionary = DictionaryParsing.get_by_key_chain_safe(self._musicDB, keyChain)

	return _tmp_data.reference.mplaying

func is_any_music_playing() -> bool:
	var _tmp_checkSum : int = 0

	for _keyChain in self._musicKeyChainTable:
		if self.is_song_playing_by_key_chain(_keyChain):
			_tmp_checkSum += 1

	if _tmp_checkSum != 0:
		return true

	return false

func request_song_by_key_chain(keyChain : Array) -> void:
	var _tmp_data : Dictionary = DictionaryParsing.get_by_key_chain_safe(self._musicDB, keyChain)
	_tmp_data.reference.mplay()

func stop_everything() -> void:
	for _keyChain in self._musicKeyChainTable:
		var _tmp_song : Dictionary = DictionaryParsing.get_by_key_chain_safe(self._musicDB, _keyChain)
		
		if _tmp_song.reference.mplaying:
			_tmp_song.reference.mstop()
