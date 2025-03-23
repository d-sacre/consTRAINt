extends Node

var _musicDB : Dictionary = {}

func is_song_playing_by_key_chain(keyChain : Array) -> bool:
	var _tmp_data : Dictionary = DictionaryParsing.get_by_key_chain_safe(self._musicDB, keyChain)

	return _tmp_data.reference.mplaying

func request_song_by_key_chain(keyChain : Array) -> void:
	var _tmp_data : Dictionary = DictionaryParsing.get_by_key_chain_safe(self._musicDB, keyChain)
	_tmp_data.reference.mplay()
