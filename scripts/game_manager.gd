extends Node

var winner_text: String = ""
var final_score: int = 0 # <-- Añadida para recordar el puntaje en la pantalla de Game Over

# --- SISTEMA DE HIGH SCORES GLOBAL ---
const SAVE_PATH = "user://highscores.save"
var high_scores: Array = [] 

func _ready() -> void:
	load_high_scores()
	if high_scores.is_empty():
		for i in range(10):
			high_scores.append({"name": "CPU", "score": (10 - i) * 1000})

func reset_game() -> void:
	winner_text = ""
	final_score = 0

func is_high_score(new_score: int) -> bool:
	for entry in high_scores:
		if new_score > entry["score"]: return true
	return false

func add_high_score(player_name: String, new_score: int) -> void:
	high_scores.append({"name": player_name, "score": new_score})
	high_scores.sort_custom(func(a, b): return a["score"] > b["score"])
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
