extends Node

################################################################################
#### AUTOLOAD REMARKS ##########################################################
################################################################################
# The scene this script is attached to is autoloaded as "AudioManager".
################################################################################
################################################################################
################################################################################

################################################################################
#### REQUIREMENTS ##############################################################
################################################################################
# This script expects the following AutoLoads:                                 
# - DictionaryParsing: res//utils/DictionaryParsing.gd
#
# This script expects the following Addons:
# - MetaPlayer: res://addons/meta_player
################################################################################
################################################################################
################################################################################

################################################################################
#### PRIVATE MEMBER VARIABLES ##################################################
################################################################################
var _busAliasLUT : Dictionary = {
	"master":  "Master",
	"sfx": {
		"ui":  "UI",
		"ambience":  "Ambience",
		"game": "Game"
	},
	"music":  "Music"
}

var _busAliasKeyChainLUT : Dictionary = {}

var _metaPlayerValidKeys : Array = [
	"fp", "volume_db", "loop", "bus", "bpm", "beats_per_bar", "bars", "reference",
	"autoplay", "transitions", "playing", "children"
]

var _playingAllowed : bool = true

################################################################################
#### EXPORT MEMBER VARIABLES ###################################################
################################################################################
@export var _sfxDatabaseFilePath : String = CONS_TRAIN_T.CONFIGURATION_FILES.AUDIO.SFX.PATH
@export var _musicDatabaseFilePath : String = CONS_TRAIN_T.CONFIGURATION_FILES.AUDIO.MUSIC.PATH

################################################################################
#### ONREADY MEMBER VARIABLES ##################################################
################################################################################
@onready var _sfxManager := $sfxManager
@onready var _musicManager := $musicManager

################################################################################
#### PRIVATE MEMBER FUNCTIONS ##################################################
################################################################################
func _add_and_configure_meta_player(database : Dictionary, audioID : Array, parent : Node, keyChainParent : Array, data : Dictionary):
	# DESCRIPTION: If the data passed to the method is an sound and not a (sub)category
	# REMARK: Decision based upon whether the key "fp" exists
	if "fp" in data:
		# DESCRIPTION: Create a new Meta Player and setup the standard values
		var _tmp_metaPlayer = meta_player.new()

		_tmp_metaPlayer.stream = load(data["fp"])
		_tmp_metaPlayer.volume_db = data["volume_db"]
		_tmp_metaPlayer.loop = data["loop"]
		_tmp_metaPlayer.bus = data["bus"]

		# DESCRIPTION: Verify whether the Meta Player specific data is available
		# If so, set the data directly. If not, calculate the values based upon assumptions
		# REMARK: Setting this data is important, so that the Meta Player's looping functionality
		# can be used
		var _tmp_dataComplete : bool = ("bpm" in data) and ("beats_per_bar" in data) and ("bars" in data)

		if _tmp_dataComplete:
			_tmp_metaPlayer.tempo = data["bpm"]
			_tmp_metaPlayer.beats_per_bar = data["beats_per_bar"]
			_tmp_metaPlayer.bars = data["bars"]

		else:
			var _tmp_duration : float = _tmp_metaPlayer.stream.get_length() 

			_tmp_metaPlayer.beats_per_bar = 4
			_tmp_metaPlayer.bars = floor(_tmp_duration/_tmp_metaPlayer.beats_per_bar)
			_tmp_metaPlayer.tempo = (_tmp_metaPlayer.beats_per_bar * _tmp_metaPlayer.bars) / (_tmp_duration/60) 

		parent.add_child(_tmp_metaPlayer)

		var _tmp_data : Dictionary = {"reference": _tmp_metaPlayer}

		for _key in data:
			_tmp_data[_key] = data[_key]

		DictionaryParsing.set_by_key_chain_safe(database, audioID, _tmp_data)

		# if "children" in data:
		# 	if data["children"] != {}:
		# 		for childID in data["children"]:
		# 			var _tmp_childData : Dictionary = data["children"][childID]

		# 			self._add_and_configure_meta_player(_tmp_metaPlayer, _tmp_childData) 

	else:
		if not DictionaryParsing.is_key_chain_valid(database, keyChainParent):
			DictionaryParsing.set_by_key_chain_safe(database, keyChainParent, {})

			var _tmp_category : Node = Node.new()
			_tmp_category.name = keyChainParent[-1]
			
			parent.add_child(_tmp_category)

			var _tmp_parent = _tmp_category

			for _subKey in data:
				var _tmp_keyChain : Array = audioID.duplicate()
				_tmp_keyChain.append(_subKey)

				var _tmp_data : Dictionary = data[_subKey]

				self._add_and_configure_meta_player(
					database, 
					_tmp_keyChain,
					_tmp_parent,
					_tmp_keyChain,
					_tmp_data
				)

func _configure_meta_player_transitions(data : Dictionary, pruned : Dictionary = {}) -> void:
	if pruned == {}:
		pruned = data.duplicate()

	if "reference" in pruned:
		if "transitions" in pruned:
			if pruned["transitions"] != []:
				for _transition in pruned["transitions"]:
					var _tmp_transition : transition_rule = transition_rule.new()
					_tmp_transition.target_player = (DictionaryParsing.get_by_key_chain_safe(data, _transition["to"])).reference.get_path()
					_tmp_transition.transition_type = _transition["type"]
					_tmp_transition.signal_node = pruned.reference.get_path()
					# _tmp_transition.signal_name = "finished"

					pruned.reference.transition_rules.append(_tmp_transition)

	else:
		for _key in pruned:
			var _tmp_data : Dictionary = pruned[_key]
			self._configure_meta_player_transitions(data, _tmp_data)

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func set_bus_level(busName : String, value : float) -> void:
	var _tmp_decibel = linear_to_db(value/100)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(busName), _tmp_decibel)

func set_bus_level_by_key_chain(keyChain : Array, value : float) -> void:
	var _tmp_busName = DictionaryParsing.get_by_key_chain_safe(self._busAliasLUT, keyChain)
	self.set_bus_level(_tmp_busName, value)

func set_bus_levels(data : Dictionary) -> void:
	for _busName in self._busAliasKeyChainLUT:
		var _tmp_keyChain : Array = self._busAliasKeyChainLUT[_busName]

		if DictionaryParsing.is_key_chain_valid(data, _tmp_keyChain):
			var _tmp_value = DictionaryParsing.get_by_key_chain_safe(data, _tmp_keyChain)
			self.set_bus_level(_busName, _tmp_value)

func enable_request_processing() -> void:
	self._playingAllowed = true

func disable_request_processing() -> void:
	self._playingAllowed = false

func play_sfx(keyChain : Array) -> void:
	if self._playingAllowed:
		self._sfxManager.play_sound(keyChain)

func is_song_playing_by_key_chain(keyChain : Array) -> bool:
	return self._musicManager.is_song_playing_by_key_chain(keyChain)

func is_any_music_playing() -> bool:
	return self._musicManager.is_any_music_playing()

func play_song_by_key_chain(keyChain : Array) -> void:
	if self._playingAllowed:
		self._musicManager.request_song_by_key_chain(keyChain)

func fade_bus_from_current_level_to(busName : String, value: float, duration : float = 2) -> void:
	var _tmp_busIndex : int = AudioServer.get_bus_index(busName)
	var _tmp_volume : float = AudioServer.get_bus_volume_db(_tmp_busIndex)
	var _tmp_decibel = linear_to_db(value/100)
	var t = create_tween()

	t.tween_method(
		AudioServer.set_bus_volume_db.callv, 
		[_tmp_busIndex,_tmp_volume],
		[_tmp_busIndex, _tmp_decibel],
		duration
	)
	await t.finished
	t.kill()

func fade_out_master(duration : float = 2) -> void:
	await self.fade_bus_from_current_level_to("Master", 0.01, duration)

func fade_out_and_stop_all_playing() -> void:
	# REMARK: Issue why no audio would play after switching seems to be caused by
	# the await not blocking the setting of the new bus level, so that it would be
	# overwritten and therefor no audio would play
	# TODO: Transition sounds a bit harsh, therefor another attempt with fading 
	# should be started
	# await self.fade_out_master()
	self._musicManager.stop_everything()
	self._sfxManager.stop_everything()
	# self.set_bus_level_by_key_chain(["master"], SettingsManager.get_user_setting_by_key_chain_safe(["volume", "master"]))

func _ready() -> void:
	# DESCRIPTION: Create the bus alias key chain LUT
	var _tmp_keyChains : Array[Array] = []

	DictionaryParsing.find_all_key_chains(self._busAliasLUT, _tmp_keyChains)

	for _keyChain in _tmp_keyChains:
		var _tmp_newKey : String = DictionaryParsing.get_by_key_chain_safe(self._busAliasLUT, _keyChain)
		self._busAliasKeyChainLUT[_tmp_newKey] = _keyChain

	# DESCRIPTION: Load all the music 
	# REMARK: Not very efficient. Should be adapted to only load what is actually
	# needed
	var _tmp_musicDB : Dictionary = FileIO.json.load(_musicDatabaseFilePath)

	for _musicID in _tmp_musicDB:
		var _tmp_data : Dictionary = _tmp_musicDB[_musicID]

		self._add_and_configure_meta_player(self._musicManager._musicDB, [_musicID], self._musicManager, [_musicID], _tmp_data)

	# DESCRIPTION: Initialize music transitions
	self._configure_meta_player_transitions(self._musicManager._musicDB)
	self._musicManager.initialize()

	# DESCRIPTION: Load all the sound effects 
	# REMARK: Not very efficient. Should be adapted to only load what is actually
	# needed
	var _tmp_sfxDB : Dictionary = FileIO.json.load(_sfxDatabaseFilePath)

	for _sfxID in _tmp_sfxDB:
		var _tmp_keyChain : Array = [_sfxID]
		var _tmp_parent = self._sfxManager
		var _tmp_data : Dictionary = _tmp_sfxDB[_sfxID]

		self._add_and_configure_meta_player(self._sfxManager._sfxDB, _tmp_keyChain, _tmp_parent, _tmp_keyChain, _tmp_data)

	self._sfxManager.initialize()
