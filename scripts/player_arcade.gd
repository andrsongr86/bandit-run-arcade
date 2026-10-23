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
@export var min_x: float = 272.0 
@export var max_x: float = 752.0

@export var split_min_x: float = 210.0
@export var split_max_x: float = 494.0

@export var min_y_offset: float = -200.0 
@export var max_y_offset: float = 200.0 

@export_group("Combo System")
@export var base_near_miss_points: int = 100
@export var combo_max_time: float = 3.0 

@onready var sprite: Sprite2D = $Sprite2D
@onready var base_rotation: float = sprite.rotation 
@onready var near_miss_area: Area2D = $NearMissArea

var starting_y: float = 0.0

# Variables de Estado del Combo
var combo_active: bool = false
var combo_points: int = 0
var combo_multiplier: int = 2
var combo_timer: float = 0.0
var counted_vehicles: Array[int] = []
var cars_in_combo: int = 0 

# Reproductor para el sonido del motor
var engine_audio_player: AudioStreamPlayer

func _ready() -> void:
	# --- INICIALIZAR SONIDO DE MOTOR ---
	engine_audio_player = AudioStreamPlayer.new()
	var engine_path = "res://sound/car-engine-speeding.mp3"
	if ResourceLoader.exists(engine_path):
		engine_audio_player.stream = load(engine_path)
		add_child(engine_audio_player)
		engine_audio_player.play()

	if sprite and GameManager:
		var texture_path = GameManager.p1_car_texture_path
		if player_id == 2:
			texture_path = GameManager.p2_car_texture_path
			
		if ResourceLoader.exists(texture_path):
			sprite.texture = load(texture_path)
			
	starting_y = position.y
	if get_viewport() is SubViewport:
		position.x = 352.0 
		
	if near_miss_area:
		if not near_miss_area.area_entered.is_connected(_on_near_miss_detected):
			near_miss_area.area_entered.connect(_on_near_miss_detected)

func _process(delta: float) -> void:
	_handle_movement(delta)
	_handle_visual_rotation(delta)
	move_and_slide()
	_clamp_positions()
	_handle_combo_timer(delta)

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
		position.x = clamp(position.x, split_min_x, split_max_x)
	else:
		position.x = clamp(position.x, min_x, max_x)
		
	position.y = clamp(position.y, starting_y + min_y_offset, starting_y + max_y_offset)

# --- SISTEMA DE COMBOS Y PROXIMIDAD (NEAR-MISS) CON VOLÚMENES AJUSTADOS ---

func _on_near_miss_detected(area: Area2D) -> void:
	if area == self or area == near_miss_area:
		return
		
	if area.is_in_group("Traffic") or area is Vehicle or area.name.contains("Traffic") or area.name.contains("Car"):
		var car_id = area.get_instance_id()
		
		if counted_vehicles.has(car_id):
			return
			
		counted_vehicles.append(car_id)
		cars_in_combo += 1
		
		var is_truck_vehicle = false
		if area is Vehicle and "is_truck" in area:
			is_truck_vehicle = area.is_truck
		elif area.get_parent() is Vehicle and "is_truck" in area.get_parent():
			is_truck_vehicle = area.get_parent().is_truck
		else:
			is_truck_vehicle = area.is_in_group("Truck") or "truck" in area.name.to_lower() or "camion" in area.name.to_lower()
		
		# Bocina de camión un poco más alta (+4 dB) y bocina de coche un poco más baja (-5 dB)
		if is_truck_vehicle:
			if GameManager.truck_horn_stream:
				GameManager.play_sfx(GameManager.truck_horn_stream, 4.0)
		else:
			if GameManager.car_horn_stream:
				GameManager.play_sfx(GameManager.car_horn_stream, -5.0)
		
		var old_multiplier = combo_multiplier
		
		if not combo_active:
			combo_active = true
			cars_in_combo = 1
			combo_multiplier = 2
			combo_points = base_near_miss_points
		else:
			combo_points += base_near_miss_points
			combo_multiplier = min(2 + int(float(cars_in_combo - 1) / 5.0), 8)
			
		if combo_multiplier > old_multiplier:
			_trigger_camera_shake(4.0 * combo_multiplier)
			
		combo_timer = combo_max_time

func _handle_combo_timer(delta: float) -> void:
	if combo_active:
		combo_timer -= delta
		if combo_timer <= 0:
			_end_combo()

func _end_combo() -> void:
	combo_active = false
	var final_score = combo_points * combo_multiplier
	_add_score(final_score)
	
	if combo_multiplier >= 5:
		_trigger_camera_shake(4.0)
	
	combo_points = 0
	combo_multiplier = 2
	cars_in_combo = 0
	counted_vehicles.clear()

func _trigger_camera_shake(strength: float) -> void:
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("apply_shake"):
		cam.apply_shake(strength)

func _add_score(amount: int) -> void:
	var local_mgr = null
	var current_node = get_parent()
	while current_node:
		local_mgr = current_node.get_node_or_null("LocalGameManager")
		if local_mgr: break
		current_node = current_node.get_parent()
		
	if local_mgr and local_mgr.has_method("add_score"):
		local_mgr.add_score(amount)
	elif local_mgr and "score" in local_mgr:
		local_mgr.score += amount
	elif GameManager and GameManager.has_method("add_score"):
		GameManager.add_score(amount)

# --- SISTEMA DE DAÑO, EXPLOSIÓN Y FUNDIDO DE MÚSICA AL MORIR ---

func take_damage(_amount: int) -> void:
	var local_mgr = null
	var current_node = get_parent()
	while current_node:
		local_mgr = current_node.get_node_or_null("LocalGameManager")
		if local_mgr: break
		current_node = current_node.get_parent()
		
	if local_mgr:
		if local_mgr.current_health <= 1:
			# 1. Explosión de jugador (is_player = true, volumen más alto configurado en GameManager)
			GameManager.spawn_explosion(global_position, true)
			
			# 2. Silenciar la música de fondo de la escena de juego gradualmente en 1 segundo
			GameManager.fade_out_scene_music(1.0)
			
			if sprite:
				sprite.visible = false
				
			if engine_audio_player and engine_audio_player.playing:
				engine_audio_player.stop()
				
			set_process(false)
			set_physics_process(false)
			
		local_mgr.take_damage(1)
	elif GameManager:
		GameManager.take_damage(1)
