extends Control

@onready var list_container: VBoxContainer = $ColorRect/VBoxContainer
@onready var back_button: Button = $ColorRect/VBoxContainer/BackButton

func _ready() -> void:
	back_button.grab_focus()
	back_button.pressed.connect(_on_back_pressed)
	
	# Generar la lista leyendo del GameManager
	var rank = 1
	for entry in GameManager.high_scores:
		var label = Label.new()
		# Formato: "1. AAA - 5000"
		label.text = str(rank) + ". " + entry["name"] + " - " + str(entry["score"])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_container.add_child(label)
		rank += 1

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
