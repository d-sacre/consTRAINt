class_name CONS_TRAIN_T

class COLLISION_LAYERS:
    const CAMERA : int = 2

class Z_INDEX:
    class GLOBAL:
        const TRACK_FRONT : int = 2

class DEBUG:
    class DEFAULT_PROPERTIES:
        class GUI:
            const SCENE_PATH: String = "res://utils/debug/debug.tscn"

class SCENES:
    class MAIN_MENU:
        const  PATH : String = "res://scenes/menus/main/mainMenu.tscn"
    
    class GAME:
        const PATH : String = "res://scenes/game/game.tscn"

class CONFIGURATION_FILES:
    class USER: 
        class DEFAULT:
            const PATH : String = "res://settings/consTRAINt_settings_runtime_default.json"

        class RUNTIME:
            const PATH : String = "user://consTRAINt_userSettings.json"

    class AUDIO:
        class MUSIC:
            const PATH : String = "res://settings/consTRAINt_music.json"

        class SFX:
            const PATH : String = "res://settings/consTRAINt_sfx.json"
