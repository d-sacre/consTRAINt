extends Sprite2D

func _process(_delta: float) -> void:
	if SettingsManager.is_new_update_queued():
		var _tmp_debugStatus : bool = SettingsManager.get_user_setting_by_key_chain_safe(
			["performance", "debug"]
		)
		
		if _tmp_debugStatus:
			self.texture = load("res://scenes/game/shared/railroad/track/sprites/railroad_track_debug.png")
			
		else:
			self.texture = load("res://scenes/game/shared/railroad/track/sprites/railroad_track.png")
