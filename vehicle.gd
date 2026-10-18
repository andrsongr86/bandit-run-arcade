class_name Vehicle
extends Area2D

signal vehicle_destroyed(points: int)

@export_group("Stats")
@export var base_speed: float = 150.0
@export var health: int = 1
@export var collision_damage: int = 1
@export var score_value: int = 100
@export var vehicle_length: float = 80.0

@export_group("Visuals")
@export var skin_textures: Array[Texture2D] = []

# --- NUEVAS VARIABLES DE FÍSICA E IA ---
var original_base_speed: float = 0.0
var current_speed: float = 0.0
var target_speed: float = 0.0
var acceleration_rate: float = 120.0 # Qué tan rápido frena o acelera

var target_x: float = 0.0
var current_lane_index: int = 0
var is_changing_lane: bool = false
var lane_change_speed: float = 50.0 
var relative_speed: float = 0.0
var passed_player: bool = false

# Centralizamos el acceso al Sprite para rotarlo aquí y que las subclases lo hereden
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Elige un color al azar si le cargamos texturas en el inspector
	if skin_textures.size() > 0:
		sprite.texture = skin_textures.pick_random()
		
	original_base_speed = base_speed
	current_speed = base_speed
	target_speed = base_speed

func update_movement(delta: float, game_speed: float) -> void:
	# 1. Acelerar o frenar suavemente hacia la velocidad objetivo (IA)
	current_speed = move_toward(current_speed, target_speed, acceleration_rate * delta)
	
	# 2. Movimiento Vertical Relativo
	relative_speed = game_speed - current_speed
	position.y += relative_speed * delta

	# 3. Movimiento Horizontal y Rotación Visual
	if is_changing_lane:
		position.x = move_toward(position.x, target_x, lane_change_speed * delta)
		
		# Calcular dirección: -1 (Izquierda) o 1 (Derecha)
		var direction = sign(target_x - position.x)
		if direction != 0:
			# Rotar 15 grados (en radianes) hacia donde gira
			var target_rotation = deg_to_rad(15.0) * direction
			sprite.rotation = lerp_angle(sprite.rotation, target_rotation, 8.0 * delta)
		
		# Si ya llegó al destino, termina la maniobra
		if position.x == target_x:
			is_changing_lane = false
	else:
		# Enderezar el auto suavemente si no está cambiando de carril
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, 8.0 * delta)

func change_to_lane(new_lane_index: int, new_target_x: float) -> void:
	if not is_changing_lane:
		current_lane_index = new_lane_index
		target_x = new_target_x
		is_changing_lane = true

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		_destroy()

func _destroy() -> void:
	vehicle_destroyed.emit(score_value)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerArcade:
		GameManager.take_damage(collision_damage)
		_on_impact_with_player(body)

func _on_impact_with_player(_player: Node2D) -> void:
	# Se destruye por el impacto SIN emitir la señal de puntos (_destroy)
	queue_free()
