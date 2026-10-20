class_name PlayerArcade
extends CharacterBody2D

@export var player_id: int = 1
@export_group("Player Stats")
@export var health: int = 3
@export var max_handling_speed: float = 300.0
@export var acceleration: float = 1200.0
@export var friction: float = 1800.0
@export var vertical_maneuver_speed: float = 150.0 

@export_group("Boundaries")
# Límites para un jugador (Pantalla Completa)
@export var min_x: float = 272.0 
@export var max_x: float = 752.0

# Límites estrictos para los 5 carriles en Modo 1v1 (Pantalla Dividida)
@export var split_min_x: float = 210.0
@export var split_max_x: float = 494.0 # Ajusta estos valores según la posición exacta de tus 5 carriles en el sub-viewport

@export var min_y_offset: float = -200.0 
@export var max_y_offset: float = 200.0 

@onready var sprite: Sprite2D = $Sprite2D
@onready var base_rotation: float = sprite.rotation 

var starting_y: float = 0.0

func _ready() -> void:
	if sprite and GameManager:
		var texture_path = GameManager.p1_car_texture_path
		if player_id == 2:
			texture_path = GameManager.p2_car_texture_path
			
		if ResourceLoader.exists(texture_path):
			sprite.texture = load(texture_path)
			
	starting_y = position.y
	if get_viewport() is SubViewport:
		position.x = 352.0 
		
func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_visual_rotation(delta)
	move_and_slide()
	_clamp_positions()

func _handle_movement(delta: float) -> void:
	var action_left = "move_left"
	var action_right = "move_right"
	var action_up = "move_up"
	var action_down = "move_down"
	
	if player_id == 2:
		action_left = "p2_move_left"
		action_right = "p2_move_right"
		action_up = "p2_move_up"
		action_down = "p2_move_down"
	
	var input_dir_x = Input.get_axis(action_left, action_right)
	
	if input_dir_x != 0:
		velocity.x = move_toward(velocity.x, input_dir_x * max_handling_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		
	var input_dir_y = Input.get_axis(action_up, action_down)
	
	if input_dir_y != 0:
		velocity.y = move_toward(velocity.y, input_dir_y * vertical_maneuver_speed, acceleration * delta)
	else:
		velocity.y = move_toward(velocity.y, 0.0, friction * delta)

func _handle_visual_rotation(delta: float) -> void:
	if abs(velocity.x) > 10.0:
		var steering_ratio = velocity.x / max_handling_speed
		var target_rotation = base_rotation + (deg_to_rad(15.0) * steering_ratio)
		sprite.rotation = lerp_angle(sprite.rotation, target_rotation, 10.0 * delta)
	else:
		sprite.rotation = lerp_angle(sprite.rotation, base_rotation, 10.0 * delta)

func _clamp_positions() -> void:
	if get_viewport() is SubViewport:
		# Modo 1v1: Restringe el movimiento únicamente a los 5 carriles centrales
		position.x = clamp(position.x, split_min_x, split_max_x)
	else:
		# Modo Un Jugador: Usa los límites de pantalla completa normales
		position.x = clamp(position.x, min_x, max_x)
		
	position.y = clamp(position.y, starting_y + min_y_offset, starting_y + max_y_offset)

func take_damage(_amount: int) -> void:
	var local_mgr = null
	var current_node = get_parent()
	while current_node:
		local_mgr = current_node.get_node_or_null("LocalGameManager")
		if local_mgr: break
		current_node = current_node.get_parent()
		
	if local_mgr:
		local_mgr.take_damage(1)
	elif GameManager:
		GameManager.take_damage(1)
