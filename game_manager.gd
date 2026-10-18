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
	load_high_scores()
	# Si no hay puntajes, creamos 10 puntajes de relleno ("CPU")
	if high_scores.is_empty():
		for i in range(10):
			high_scores.append({"name": "CPU", "score": (10 - i) * 1000})
	reset_game()

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
	is_game_over = true
	game_over_triggered.emit()
	# Pausamos el juego o cambiamos a la escena de Game Over
	get_tree().change_scene_to_file("res://game_over.tscn")

# --- SISTEMA DE HIGH SCORES ---
const SAVE_PATH = "user://highscores.save"
var high_scores: Array = [] # Guardará diccionarios: {"name": "AAA", "score": 1000}

func is_high_score(new_score: int) -> bool:
	for entry in high_scores:
		if new_score > entry["score"]: return true
	return false

func add_high_score(player_name: String, new_score: int) -> void:
	high_scores.append({"name": player_name, "score": new_score})
	# Ordenar de mayor a menor
	high_scores.sort_custom(func(a, b): return a["score"] > b["score"])
	# Mantener solo el Top 10
	if high_scores.size() > 10:
		high_scores.resize(10)
	save_high_scores()

func save_high_scores() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(high_scores)
		file.close()

func load_high_scores() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			if typeof(data) == TYPE_ARRAY:
				high_scores = data
			file.close()
