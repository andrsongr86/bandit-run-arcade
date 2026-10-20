class_name TrafficSpawner
extends Node2D

signal player_damaged(damage: int)

@export var vehicle_scenes: Array[PackedScene] = []
@export var min_spawn_time: float = 0.4
@export var max_spawn_time: float = 1.2
@export var spawn_y_offset: float = -120.0 
@export var despawn_y_offset: float = 800.0 
@export var random_lane_chance: float = 0.0001

@onready var spawn_timer: Timer = $SpawnTimer
@onready var vehicles_container: Node2D = $VehiclesContainer

# Carriles originales para Modo Un Jugador (Pantalla Completa)
const FULL_LANE_POSITIONS_X: Array[float] = [288.0, 352.0, 416.0, 480.0, 544.0, 608.0, 672.0, 736.0]

# Centros exactos de los 5 carriles en Modo 1v1 (espaciados cada 64 píxeles)
const SPLIT_LANE_POSITIONS_X: Array[float] = [224.0, 288.0, 352.0, 416.0, 480.0]

var _last_spawned_lanes: Array[int] = []

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_reset_timer()

func _process(delta: float) -> void:
	var current_game_speed: float = _get_current_game_speed()
	var vehicles = vehicles_container.get_children()
	
	for veh in vehicles:
		if veh is Vehicle:
			veh.update_movement(delta, current_game_speed)
			
			if veh.position.y > 500.0 and not veh.passed_player:
				veh.passed_player = true
				var local_mgr = owner.get_node_or_null("LocalGameManager") if owner else get_node_or_null("LocalGameManager")
				if local_mgr:
					local_mgr.add_score(veh.score_value)
				elif GameManager:
					GameManager.add_score(veh.score_value)
			
			if veh.position.y > despawn_y_offset:
				veh.queue_free()

	# IA de conducción y evasión adaptada al set de carriles activo
	var active_lanes = SPLIT_LANE_POSITIONS_X if (get_viewport() is SubViewport) else FULL_LANE_POSITIONS_X

	for i in range(vehicles.size()):
		var veh_back = vehicles[i] as Vehicle
		if not veh_back: continue
		
		veh_back.target_speed = veh_back.original_base_speed
		if veh_back.is_changing_lane: continue
			
		if randf() < random_lane_chance:
			var current = veh_back.current_lane_index
			var possible_lanes: Array[int] = []
			
			if current > 0 and _is_lane_free(current - 1, veh_back.position.y, vehicles, veh_back):
				possible_lanes.append(current - 1)
			if current < active_lanes.size() - 1 and _is_lane_free(current + 1, veh_back.position.y, vehicles, veh_back):
				possible_lanes.append(current + 1)
				
			if possible_lanes.size() > 0:
				var new_lane = possible_lanes.pick_random()
				veh_back.change_to_lane(new_lane, active_lanes[new_lane])
				continue
				
		# Lógica de evasión frontal
		var closest_front_veh: Vehicle = null
		var closest_distance = 9999.0 
		
		for j in range(vehicles.size()):
			if i == j: continue
			var veh_front = vehicles[j] as Vehicle
			if not veh_front: continue
			
			if veh_back.current_lane_index == veh_front.current_lane_index:
				var distance = veh_back.position.y - veh_front.position.y
				var dynamic_min_distance = (veh_back.vehicle_length / 2.0) + (veh_front.vehicle_length / 2.0) + 60.0
				
				if distance > 0 and distance < dynamic_min_distance:
					if distance < closest_distance:
						closest_distance = distance
						closest_front_veh = veh_front
		
		if closest_front_veh and veh_back.current_speed > closest_front_veh.current_speed:
			var current = veh_back.current_lane_index
			var possible_lanes: Array[int] = []
			
			if current > 0 and _is_lane_free(current - 1, veh_back.position.y, vehicles, veh_back):
				possible_lanes.append(current - 1)
			if current < active_lanes.size() - 1 and _is_lane_free(current + 1, veh_back.position.y, vehicles, veh_back):
				possible_lanes.append(current + 1)
				
			if possible_lanes.size() > 0:
				var new_lane = possible_lanes.pick_random()
				veh_back.change_to_lane(new_lane, active_lanes[new_lane])
			else:
				veh_back.target_speed = closest_front_veh.current_speed

func _is_lane_free(lane: int, y_pos: float, all_vehicles: Array, checking_veh: Vehicle) -> bool:
	var safety_margin: float = 40.0
	for v in all_vehicles:
		if v == checking_veh: continue
		if v.current_lane_index == lane or (v.is_changing_lane and v.target_lane_index == lane):
			var safe_dist = (checking_veh.vehicle_length / 2.0) + (v.vehicle_length / 2.0) + safety_margin
			if abs(v.position.y - y_pos) < safe_dist:
				return false
	return true

func _on_spawn_timer_timeout() -> void:
	spawn_vehicle()
	_reset_timer()

func spawn_vehicle() -> void:
	if vehicle_scenes.is_empty(): return

	# Seleccionamos las posiciones de carriles según el modo de juego actual
	var active_lanes = SPLIT_LANE_POSITIONS_X if (get_viewport() is SubViewport) else FULL_LANE_POSITIONS_X

	var available_lanes: Array[int] = []
	for i in range(active_lanes.size()):
		if not _last_spawned_lanes.has(i): available_lanes.append(i)

	if available_lanes.is_empty():
		available_lanes = [randi() % active_lanes.size()]

	var selected_lane: int = available_lanes.pick_random()
	
	_last_spawned_lanes.append(selected_lane)
	if _last_spawned_lanes.size() > 3: _last_spawned_lanes.pop_front()

	var scene_to_spawn: PackedScene = vehicle_scenes.pick_random()
	var spawned_node = scene_to_spawn.instantiate()

	if spawned_node is Vehicle:
		var new_vehicle: Vehicle = spawned_node
		new_vehicle.current_lane_index = selected_lane
		new_vehicle.target_x = active_lanes[selected_lane]
		new_vehicle.position = Vector2(new_vehicle.target_x, spawn_y_offset)
		new_vehicle.base_speed = randf_range(80.0, 160.0)
		
		if new_vehicle.has_signal("vehicle_hit_player"):
			new_vehicle.vehicle_hit_player.connect(_on_vehicle_hit_player)

		vehicles_container.add_child(new_vehicle)
	else:
		spawned_node.queue_free()

func _reset_timer() -> void:
	spawn_timer.wait_time = randf_range(min_spawn_time * 0.6, max_spawn_time * 0.8)
	spawn_timer.start()

func _get_current_game_speed() -> float:
	if owner and has_node("../Parallax2D"):
		var parallax = get_node("../Parallax2D") as Parallax2D
		if parallax:
			return parallax.autoscroll.y
	if owner and "game_speed" in owner: 
		return owner.game_speed
	return 300.0

func _on_vehicle_hit_player(damage: int) -> void: 
	player_damaged.emit(damage)
