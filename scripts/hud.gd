class_name HUD
extends CanvasLayer

@onready var score_label: Label = $Control/MarginContainer/HBoxContainer/ScoreLabel
@onready var health_label: Label = $Control/MarginContainer/HBoxContainer/HealthLabel

func _ready() -> void:
	# Buscamos el LocalGameManager en la escena principal actual (arcade_game)
	# Usamos get_parent() o buscamos en el padre de la escena instanciada
	var local_mgr = null
	
	# Intentamos encontrarlo en el nodo padre o en la jerarquía superior de esta escena
	var current_node = get_parent()
	while current_node:
		local_mgr = current_node.get_node_or_null("LocalGameManager")
		if local_mgr:
			break
		# Si llegamos al Viewport o a la raíz de la pantalla dividida, paramos
		if current_node is Viewport or current_node.name == "Root":
			break
		current_node = current_node.get_parent()
	
	if local_mgr:
		# Conectamos con el gestor local del 1vs1 o de la escena
		local_mgr.score_changed.connect(_on_score_changed)
		local_mgr.health_changed.connect(_on_health_changed)
		
		_update_score(local_mgr.score)
		_update_health(local_mgr.current_health)
	elif GameManager:
		# Respaldo por si se ejecuta en modo solitario absoluto
		GameManager.score_changed.connect(_on_score_changed)
		GameManager.health_changed.connect(_on_health_changed)
		
		_update_score(GameManager.score)
		_update_health(GameManager.current_health)

func _on_score_changed(new_score: int) -> void:
	_update_score(new_score)

func _on_health_changed(new_health: int) -> void:
	_update_health(new_health)

func _update_score(points: int) -> void:
	score_label.text = "SCORE: %d" % points

func _update_health(hp: int) -> void:
	if hp <= 0:
		health_label.text = "VIDAS: 0"
	else:
		# Formato ultra compacto ideal para pantalla dividida
		health_label.text = "VIDAS: %d ❤️" % hp
