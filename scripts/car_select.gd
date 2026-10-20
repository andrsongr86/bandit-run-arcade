extends Control

@onready var title_label: Label = $VBoxContainer/Label

@onready var car_buttons: Array[TextureButton] = [
	$VBoxContainer/HBoxContainer/TextureButton,
	$VBoxContainer/HBoxContainer/TextureButton2,
	$VBoxContainer/HBoxContainer/TextureButton3,
	$VBoxContainer/HBoxContainer/TextureButton4
]

const CAR_TEXTURES = [
	"res://carsprites/Sport/sport_red.png",
	"res://carsprites/Sport/sport_blue.png",
	"res://carsprites/Sport/sport_green.png",
	"res://carsprites/Sport/sport_yellow.png"
]

var current_index: int = 0

func _ready() -> void:
	_update_ui()
	
	for i in range(car_buttons.size()):
		if car_buttons[i]:
			if ResourceLoader.exists(CAR_TEXTURES[i]):
				car_buttons[i].texture_normal = load(CAR_TEXTURES[i])
			
			# Forzamos que el TextureButton acepte foco por teclado/gamepad
			car_buttons[i].focus_mode = Control.FOCUS_ALL
			
			# Conectamos las señales de foco para dar feedback visual
			car_buttons[i].focus_entered.connect(_on_button_focus_entered.bind(i))
			car_buttons[i].focus_exited.connect(_on_button_focus_exited.bind(i))
			
			# Conectamos el clic del mouse
			car_buttons[i].pressed.connect(_on_car_button_pressed.bind(i))
	
	_update_focus()

func _update_ui() -> void:
	if title_label:
		if GameManager.is_multiplayer:
			title_label.text = "Jugador " + str(GameManager.current_selecting_player) + ": Elige tu auto"
		else:
			title_label.text = "Elige tu auto"

func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
		
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		current_index = (current_index + 1) % car_buttons.size()
		_update_focus()
		if get_viewport():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		current_index = (current_index - 1 + car_buttons.size()) % car_buttons.size()
		_update_focus()
		if get_viewport():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if car_buttons.size() > 0 and car_buttons[current_index]:
			_on_car_button_pressed(current_index)
		if get_viewport():
			get_viewport().set_input_as_handled()

func _update_focus() -> void:
	if car_buttons.size() > 0 and car_buttons[current_index]:
		car_buttons[current_index].grab_focus()

# Feedback visual: Agranda el botón seleccionado
func _on_button_focus_entered(index: int) -> void:
	current_index = index
	car_buttons[index].scale = Vector2(1.2, 1.2)
	car_buttons[index].modulate = Color(1.3, 1.3, 1.3) # Un poco más brillante

# Restaura el tamaño cuando pierde el foco
func _on_button_focus_exited(index: int) -> void:
	car_buttons[index].scale = Vector2(1.0, 1.0)
	car_buttons[index].modulate = Color(1.0, 1.0, 1.0)

func _on_car_button_pressed(index: int) -> void:
	var selected_path = CAR_TEXTURES[index]
	
	if not GameManager.is_multiplayer:
		GameManager.p1_car_texture_path = selected_path
		get_tree().change_scene_to_file("res://scenes/arcade_game.tscn")
	else:
		if GameManager.current_selecting_player == 1:
			GameManager.p1_car_texture_path = selected_path
			GameManager.current_selecting_player = 2
			_update_ui()
			current_index = 0
			_update_focus()
		else:
			GameManager.p2_car_texture_path = selected_path
			get_tree().change_scene_to_file("res://scenes/split_screen.tscn")
