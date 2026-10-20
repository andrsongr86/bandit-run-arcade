extends Camera2D

func _ready() -> void:
	if get_viewport() is SubViewport:
		# Modo 1v1: El centro de la carretera de 20 tiles (640px) es 320
		position.x = 384.0
	else:
		# Modo Un Jugador: El centro de la carretera de 32 tiles (1024px) es 512
		position.x = 512.0
