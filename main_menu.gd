extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var highscores_button: Button = $VBoxContainer/HighScoresButton
@onready var controls_button: Button = $VBoxContainer/ControlsButton
@onready var credits_button: Button = $VBoxContainer/CreditsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	play_button.grab_focus()
	
	play_button.pressed.connect(_on_play_pressed)
	highscores_button.pressed.connect(func(): get_tree().change_scene_to_file("res://high_scores.tscn"))
	controls_button.pressed.connect(func(): get_tree().change_scene_to_file("res://instructions.tscn"))
	credits_button.pressed.connect(func(): get_tree().change_scene_to_file("res://credits.tscn"))
	quit_button.pressed.connect(func(): get_tree().quit())
	
func _on_play_pressed() -> void:
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://arcade_game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
