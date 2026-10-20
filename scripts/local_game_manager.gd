class_name LocalGameManager
extends Node

# Señales para notificar al HUD cuando los datos cambien
signal score_changed(new_score: int)
signal health_changed(new_health: int)
signal game_over_triggered

@export var max_health: int = 3

var score: int = 0
var current_health: int = 3
var is_game_over: bool = false

func _ready() -> void:
	reset_game()
	call_deferred("_auto_connect_hud")

func _auto_connect_hud() -> void:
	var hud = get_parent().get_node_or_null("HUD")
	if not hud:
		hud = _find_hud_recursive(get_parent())
	
	if hud:
		if hud.has_method("_on_score_changed") and not score_changed.is_connected(hud._on_score_changed):
			score_changed.connect(hud._on_score_changed)
		if hud.has_method("_on_health_changed") and not health_changed.is_connected(hud._on_health_changed):
			health_changed.connect(hud._on_health_changed)
		
		if hud.has_method("_update_score"):
			hud._update_score(score)
		if hud.has_method("_update_health"):
			hud._update_health(current_health)

func _find_hud_recursive(node: Node) -> Node:
	for child in node.get_children():
		if child is HUD or child.name == "HUD":
			return child
		var found = _find_hud_recursive(child)
		if found:
			return found
	return null

func reset_game() -> void:
	score = 0
	current_health = max_health
	is_game_over = false
	score_changed.emit(score)
	health_changed.emit(current_health)

func add_score(points: int) -> void:
	if is_game_over: return
	score += points
	score_changed.emit(score)

func take_damage(amount: int) -> void:
	if is_game_over: return
	
	current_health -= amount
	current_health = max(0, current_health) # Evitar salud negativa
	health_changed.emit(current_health)
	
	if current_health <= 0:
		trigger_game_over()

func trigger_game_over() -> void:
	if is_game_over: return
	is_game_over = true
	
	# Guardamos el puntaje local en el global para que la pantalla de Game Over lo lea
	if GameManager:
		GameManager.final_score = score
		
	game_over_triggered.emit()
	call_deferred("_check_and_change_scene")

func _check_and_change_scene() -> void:
	var has_external_listener = false
	for connection in game_over_triggered.get_connections():
		var obj = connection["callable"].get_object()
		if obj and ("split" in obj.name.to_lower() or "screen" in obj.name.to_lower()):
			has_external_listener = true
			break
			
	# Si nadie externo (como el 1v1) atrapó el Game Over, cambiamos de escena nosotros mismos (Modo Solitario)
	if not has_external_listener:
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
