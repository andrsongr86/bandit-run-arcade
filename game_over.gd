extends Control

@onready var final_score_label: Label = $ColorRect/CenterContainer/VBoxContainer/FinalScoreLabel
@onready var initials_label: Label = $ColorRect/CenterContainer/VBoxContainer/InitialsLabel
@onready var buttons_container: HBoxContainer = $ColorRect/CenterContainer/VBoxContainer/ButtonsContainer
@onready var restart_button: Button = $ColorRect/CenterContainer/VBoxContainer/ButtonsContainer/RestartButton
@onready var main_menu_button: Button = $ColorRect/CenterContainer/VBoxContainer/ButtonsContainer/MainMenuButton

var alphabet: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
var initials_idx: Array[int] = [0, 0, 0]
var current_slot: int = 0
var is_entering_name: bool = true

func _ready() -> void:
	final_score_label.text = "Puntuación Final: %d" % GameManager.score
	
	# Siempre activamos la ruleta de iniciales al terminar
	is_entering_name = true
	buttons_container.hide()
	initials_label.show()
	_update_initials_display()
	
	# Conectamos las señales de los botones
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _input(event: InputEvent) -> void:
	if not is_entering_name: return
	
	if event.is_action_pressed("ui_up"):
		initials_idx[current_slot] -= 1
		if initials_idx[current_slot] < 0: 
			initials_idx[current_slot] = alphabet.length() - 1
		_update_initials_display()
		
	elif event.is_action_pressed("ui_down"):
		initials_idx[current_slot] += 1
		if initials_idx[current_slot] >= alphabet.length(): 
			initials_idx[current_slot] = 0
		_update_initials_display()
		
	elif event.is_action_pressed("ui_left"):
		current_slot = max(0, current_slot - 1)
		_update_initials_display()
		
	elif event.is_action_pressed("ui_right"):
		current_slot = min(2, current_slot + 1)
		_update_initials_display()
		
	elif event.is_action_pressed("ui_accept"):
		if current_slot == 2:
			_save_new_high_score()
		else:
			current_slot += 1
			_update_initials_display()

func _update_initials_display() -> void:
	var display_text = ""
	for i in range(3):
		var char_string = alphabet[initials_idx[i]]
		if i == current_slot:
			display_text += "[ " + char_string + " ] "
		else:
			display_text += "  " + char_string + "   "
	
	initials_label.text = "INGRESA TUS INICIALES:\n\n" + display_text

func _save_new_high_score() -> void:
	is_entering_name = false
	var player_name = alphabet[initials_idx[0]] + alphabet[initials_idx[1]] + alphabet[initials_idx[2]]
	
	# Guardamos el puntaje (GameManager lo ordenará y mantendrá solo el Top 10)
	GameManager.add_high_score(player_name, GameManager.score)
	
	# Redirigimos a la tabla de puntuaciones
	get_tree().change_scene_to_file("res://high_scores.tscn")

func _on_restart_pressed() -> void:
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://arcade_game.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
