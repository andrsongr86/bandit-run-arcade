class_name HUD
extends CanvasLayer

@onready var score_label: Label = $Control/MarginContainer/HBoxContainer/ScoreLabel
@onready var health_label: Label = $Control/MarginContainer/HBoxContainer/HealthLabel

func _ready() -> void:
	# Nos suscribimos a las señales del GameManager para actualizar en tiempo real
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.health_changed.connect(_on_health_changed)
	
	# Inicializamos los valores actuales
	_update_score(GameManager.score)
	_update_health(GameManager.current_health)

func _on_score_changed(new_score: int) -> void:
	_update_score(new_score)

func _on_health_changed(new_health: int) -> void:
	_update_health(new_health)

func _update_score(points: int) -> void:
	# Cambiado de %06d a %d para quitar los ceros a la izquierda
	score_label.text = "SCORE: %d" % points

func _update_health(hp: int) -> void:
	# Puedes usar texto o iconos de texto como corazones
	var hearts = ""
	for i in range(hp):
		hearts += "❤️ "
	
	if hp <= 0:
		health_label.text = "VIDAS: AGOTADAS"
	else:
		health_label.text = "VIDAS: " + hearts
