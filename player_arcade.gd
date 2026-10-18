class_name PlayerArcade
extends CharacterBody2D

@export_group("Player Stats")
@export var health: int = 3
@export var max_handling_speed: float = 300.0
@export var acceleration: float = 1200.0
@export var friction: float = 1800.0
@export var vertical_maneuver_speed: float = 150.0 

@export_group("Boundaries")
# ¡NUEVOS LÍMITES X PARA LA PISTA ANCHA (Tiles 8 al 23)!
@export var min_x: float = 272.0 
@export var max_x: float = 752.0
@export var min_y_offset: float = -200.0 
@export var max_y_offset: float = 200.0 

@onready var sprite: Sprite2D = $Sprite2D
@onready var base_rotation: float = sprite.rotation # Guarda la rotación del editor

var starting_y: float = 0.0

func _ready() -> void:
	# Guarda el punto Y donde coloques al jugador en el editor
	starting_y = position.y

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_visual_rotation(delta)
	move_and_slide()
	_clamp_positions()

func _handle_movement(delta: float) -> void:
	var input_dir_x = Input.get_axis("move_left", "move_right")
	
	if input_dir_x != 0:
		velocity.x = move_toward(velocity.x, input_dir_x * max_handling_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		
	var input_dir_y = Input.get_axis("move_up", "move_down")
	
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
	position.x = clamp(position.x, min_x, max_x)
	position.y = clamp(position.y, starting_y + min_y_offset, starting_y + max_y_offset)

func take_damage(amount: int) -> void:
	GameManager.take_damage(amount)
