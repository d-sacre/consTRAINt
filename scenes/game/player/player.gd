extends Node2D

func _process(delta: float) -> void:
	if Input.is_action_pressed("left"):
		self.position.x += delta * 100
		
	elif Input.is_action_pressed("right"):
		self.position.x -= delta * 100
