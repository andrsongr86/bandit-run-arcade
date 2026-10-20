extends CanvasLayer

@onready var resume_button: Button = $Control/CenterContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Control/CenterContainer/VBoxContainer/RestartButton
@onready var main_menu_button: Button = $Control/CenterContainer/VBoxContainer/MainMenuButton

var buttons: Array[Button] = []
var current_index: int = 0

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	buttons = [resume_button, restart_button, main_menu_button]
	
	if resume_button: resume_button.pressed.connect(_on_resume_pressed)
	if restart_button: restart_button.pressed.connect(_on_restart_pressed)
	if main_menu_button: main_menu_button.pressed.connect(_on_main_menu_pressed)

func _input(event: InputEvent) -> void:
	# Si el nodo ya no está en el árbol, ignoramos cualquier input residual
	if not is_inside_tree():
		return
		
	# 1. Si el menú está oculto, solo escuchamos la orden de pausar
	if not visible:
		if event.is_action_pressed("pause_game") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			toggle_pause()
			if get_viewport():
				get_viewport().set_input_as_handled()
		return
	
	# 2. Si el menú está visible, controlamos la navegación
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game"):
		toggle_pause()
		if get_viewport():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("ui_right"):
		current_index = (current_index + 1) % buttons.size()
		_update_focus()
		if get_viewport():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_left"):
		current_index = (current_index - 1 + buttons.size()) % buttons.size()
		_update_focus()
		if get_viewport():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if buttons.size() > 0 and buttons[current_index]:
			buttons[current_index].pressed.emit()
		if get_viewport():
			get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused
	 
	if is_paused:
		current_index = 0
		_update_focus()

func _update_focus() -> void:
	if buttons.size() > 0 and buttons[current_index]:
		buttons[current_index].grab_focus()

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_restart_pressed() -> void:
	get_tree().paused = false # Muy importante reanudar antes de cambiar de escena
	if GameManager.has_method("reset_game"):
		GameManager.reset_game()
		
	# CORRECCIÓN: Dependiendo del modo activo, recarga la escena correcta
	if GameManager.is_multiplayer:
		get_tree().change_scene_to_file("res://scenes/split_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/arcade_game.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	if GameManager.has_method("reset_game"):
		GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
