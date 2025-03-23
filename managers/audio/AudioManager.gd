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

var _playingAllowed : bool = true

@export var _sfxDatabaseFilePath : String = CONS_TRAIN_T.CONFIGURATION_FILES.AUDIO.SFX.PATH
@export var _musicDatabaseFilePath : String = CONS_TRAIN_T.CONFIGURATION_FILES.AUDIO.MUSIC.PATH

@onready var _sfxManager := $sfxManager
@onready var _musicManager := $musicManager

func _add_and_configure_meta_player(database : Dictionary, audioID : Array, parent : Node, data : Dictionary):
	var _tmp_metaPlayer = meta_player.new()

	_tmp_metaPlayer.stream = load(data["fp"])
	_tmp_metaPlayer.tempo = data["bpm"]
	_tmp_metaPlayer.beats_per_bar = data["beats_per_bar"]
	_tmp_metaPlayer.bars = data["bars"]
	_tmp_metaPlayer.volume_db = data["volume_db"]
	_tmp_metaPlayer.bus = data["bus"]

	parent.add_child(_tmp_metaPlayer)

	var _tmp_data : Dictionary = {"reference": _tmp_metaPlayer}

	DictionaryParsing.set_by_key_chain_safe(database, audioID, _tmp_data)

	# if "children" in data:
	# 	if data["children"] != {}:
	# 		for childID in data["children"]:
	# 			var _tmp_childData : Dictionary = data["children"][childID]

	# 			self._add_and_configure_meta_player(_tmp_metaPlayer, _tmp_childData) 

################################################################################
#### PUBLIC MEMBER FUNCTIONS ###################################################
################################################################################
func set_bus_level(keyChain : Array, value : float) -> void:
	var _tmp_busName = DictionaryParsing.get_by_key_chain_safe(self._busAliasLUT, keyChain)
	var _tmp_decibel = linear_to_db(value/100)

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(_tmp_busName), _tmp_decibel)

func enable_request_processing() -> void:
	self._playingAllowed = true

func disable_request_processing() -> void:
	self._playingAllowed = false

func play_sfx(keyChain : Array) -> void:
	if self._playingAllowed:
		self._sfxManager.play_sound(keyChain)

func is_song_playing_by_key_chain(keyChain : Array) -> bool:
	return self._musicManager.is_song_playing_by_key_chain(keyChain)

func play_song_by_key_chain(keyChain : Array) -> void:
	if self._playingAllowed:
		self._musicManager.request_song_by_key_chain(keyChain)

func _ready() -> void:
	var _tmp_musicDB : Dictionary = FileIO.json.load(_musicDatabaseFilePath)

	for _musicID in _tmp_musicDB:
		print("Processing ", _musicID)
		var _tmp_data : Dictionary = _tmp_musicDB[_musicID]

		self._add_and_configure_meta_player(self._musicManager._musicDB, [_musicID], self._musicManager, _tmp_data)
