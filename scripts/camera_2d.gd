class_name ArcadeCamera
extends Camera2D

@export_group("Screen Shake")
@export var decay: float = 15.0          # Qué tan rápido se detiene el temblor
var shake_strength: float = 0.0
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	
	# Mantenemos tu lógica original de posicionamiento según el modo de juego
	if get_viewport() is SubViewport:
		# Modo 1v1: El centro de la carretera en pantalla dividida
		position.x = 384.0
	else:
		# Modo Un Jugador: El centro de la carretera en pantalla completa
		position.x = 512.0

# Método global para aplicar sacudida desde el jugador, gestores o colisiones
func apply_shake(strength: float = 15.0) -> void:
	shake_strength = strength

func _process(delta: float) -> void:
	# Lógica del temblor de cámara
	if shake_strength > 0:
		shake_strength = max(shake_strength - decay * delta, 0.0)
		offset = Vector2(
			rng.randf_range(-shake_strength, shake_strength),
			rng.randf_range(-shake_strength, shake_strength)
		)
	else:
		offset = Vector2.ZERO
