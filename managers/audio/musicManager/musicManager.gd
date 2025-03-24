extends Node

var _musicDB : Dictionary = {}

func _walk_db_and_stop_everything(data : Dictionary):
	if "reference" in data:
		data["reference"].mstop()

	else:
		for _key in data:
			self._walk_db_and_stop_everything(data[_key])

func is_song_playing_by_key_chain(keyChain : Array) -> bool:
	var _tmp_data : Dictionary = DictionaryParsing.get_by_key_chain_safe(self._musicDB, keyChain)

	return _tmp_data.reference.mplaying

func request_song_by_key_chain(keyChain : Array) -> void:
	var _tmp_data : Dictionary = DictionaryParsing.get_by_key_chain_safe(self._musicDB, keyChain)
	_tmp_data.reference.mplay()

func stop_everything() -> void:
	self._walk_db_and_stop_everything(self._musicDB)
