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

# 8 Carriles mapeados exactamente sobre los tiles 8 al 23 de la pista de 16 carriles
const LANE_POSITIONS_X: Array[float] = [288.0, 352.0, 416.0, 480.0, 544.0, 608.0, 672.0, 736.0]
var _last_spawned_lanes: Array[int] = []

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_reset_timer()

func _process(delta: float) -> void:
	var current_game_speed: float = _get_current_game_speed()
	var vehicles = vehicles_container.get_children()
	
	# 1. Movimiento y Limpieza
	for veh in vehicles:
		if veh is Vehicle:
			veh.update_movement(delta, current_game_speed)
			# Si el auto llega al fondo de la pantalla, el jugador lo rebasó con éxito
		# Suma puntos INMEDIATAMENTE al adelantar al jugador (Y > 500)
			if veh.position.y > 500.0 and not veh.passed_player:
				veh.passed_player = true
				GameManager.add_score(veh.score_value)
			
			# Elimina el auto cuando sale completamente de la pantalla
			if veh.position.y > despawn_y_offset:
				veh.queue_free()
				


# 2. IA DE CONDUCCIÓN (Flocking / Evasión / Imprevisibilidad)
	for i in range(vehicles.size()):
		var veh_back = vehicles[i] as Vehicle
		if not veh_back: continue
		
		veh_back.target_speed = veh_back.original_base_speed
		
		if veh_back.is_changing_lane: 
			continue
			
		# --- CONDUCTORES ALEATORIOS ---
		if randf() < random_lane_chance:
			var current = veh_back.current_lane_index
			var possible_lanes: Array[int] = []
			
			# NOTA: Ahora pasamos 'veh_back' como cuarto parámetro a _is_lane_free
			if current > 0 and _is_lane_free(current - 1, veh_back.position.y, vehicles, veh_back):
				possible_lanes.append(current - 1)
			if current < LANE_POSITIONS_X.size() - 1 and _is_lane_free(current + 1, veh_back.position.y, vehicles, veh_back):
				possible_lanes.append(current + 1)
				
			if possible_lanes.size() > 0:
				var new_lane = possible_lanes.pick_random()
				veh_back.change_to_lane(new_lane, LANE_POSITIONS_X[new_lane])
				continue
		# ---------------------------------------
			
		# Lógica de evasión original (frenar o rebasar)
		var closest_front_veh: Vehicle = null
		
		# --- NUEVO: Ya no usamos un min_distance fijo aquí ---
		var closest_distance = 9999.0 
		
		for j in range(vehicles.size()):
			if i == j: continue
			var veh_front = vehicles[j] as Vehicle
			if not veh_front: continue
			
			if veh_back.current_lane_index == veh_front.current_lane_index:
				var distance = veh_back.position.y - veh_front.position.y
				
				# Calculamos la distancia mínima NECESARIA para este par específico de vehículos
				var dynamic_min_distance = (veh_back.vehicle_length / 2.0) + (veh_front.vehicle_length / 2.0) + 60.0 # 60px de reacción
				
				# Si está enfrente y más cerca que la distancia de reacción de seguridad
				if distance > 0 and distance < dynamic_min_distance:
					if distance < closest_distance:
						closest_distance = distance
						closest_front_veh = veh_front
		
		# Si hay un vehículo muy cerca enfrente
		if closest_front_veh and veh_back.current_speed > closest_front_veh.current_speed:
			var current = veh_back.current_lane_index
			var possible_lanes: Array[int] = []
			
			# Intentar rebasar (pasamos veh_back para calcular el tamaño)
			if current > 0 and _is_lane_free(current - 1, veh_back.position.y, vehicles, veh_back):
				possible_lanes.append(current - 1)
			if current < LANE_POSITIONS_X.size() - 1 and _is_lane_free(current + 1, veh_back.position.y, vehicles, veh_back):
				possible_lanes.append(current + 1)
				
			if possible_lanes.size() > 0:
				var new_lane = possible_lanes.pick_random()
				veh_back.change_to_lane(new_lane, LANE_POSITIONS_X[new_lane])
			else:
				# Si no puede rebasar, iguala la velocidad del de enfrente
				veh_back.target_speed = closest_front_veh.current_speed

# Verifica si hay espacio considerando el TAMAÑO de los vehículos
func _is_lane_free(lane: int, y_pos: float, all_vehicles: Array, checking_veh: Vehicle) -> bool:
	var safety_margin: float = 40.0 # Espacio extra de cortesía entre defensas
	
	for v in all_vehicles:
		if v == checking_veh: 
			continue
			
		# Revisamos si el otro vehículo está en ese carril (o se está moviendo hacia él)
		if v.current_lane_index == lane or (v.is_changing_lane and v.target_lane_index == lane):
			# Distancia dinámica: mitad de mi auto + mitad del otro auto + margen
			var safe_dist = (checking_veh.vehicle_length / 2.0) + (v.vehicle_length / 2.0) + safety_margin
			var distance_between = abs(v.position.y - y_pos)
			
			if distance_between < safe_dist:
				return false # ¡Choque inminente o espacio ocupado!
				
	return true # El carril está libre

func _on_spawn_timer_timeout() -> void:
	spawn_vehicle()
	_reset_timer()

func spawn_vehicle() -> void:
	if vehicle_scenes.is_empty(): return

	var available_lanes: Array[int] = []
	for i in range(LANE_POSITIONS_X.size()):
		if not _last_spawned_lanes.has(i): available_lanes.append(i)

	if available_lanes.is_empty():
		available_lanes = [randi() % LANE_POSITIONS_X.size()]

	var selected_lane: int = available_lanes.pick_random()
	
	_last_spawned_lanes.append(selected_lane)
	if _last_spawned_lanes.size() > 3: _last_spawned_lanes.pop_front()

	var scene_to_spawn: PackedScene = vehicle_scenes.pick_random()
	var spawned_node = scene_to_spawn.instantiate()

	# Verificación estricta de la clase
	if spawned_node is Vehicle:
		var new_vehicle: Vehicle = spawned_node
		new_vehicle.current_lane_index = selected_lane
		new_vehicle.target_x = LANE_POSITIONS_X[selected_lane]
		new_vehicle.position = Vector2(new_vehicle.target_x, spawn_y_offset)
		new_vehicle.base_speed = randf_range(80.0, 160.0)
		
		# Conexión defensiva de señales
		if new_vehicle.has_signal("vehicle_hit_player"):
			new_vehicle.vehicle_hit_player.connect(_on_vehicle_hit_player)

		
		vehicles_container.add_child(new_vehicle)
	else:
		push_error("ERROR: La escena '", scene_to_spawn.resource_path, "' no hereda de la clase 'Vehicle'. Revisa su script en el editor.")
		spawned_node.queue_free()

func _reset_timer() -> void:
	spawn_timer.wait_time = randf_range(min_spawn_time * 0.6, max_spawn_time * 0.8)
	spawn_timer.start()

func _get_current_game_speed() -> float:
	# Si el nodo Parallax2D tiene velocidad automática, podemos sincronizarla opcionalmente desde el owner
	if owner and has_node("../Parallax2D"):
		var parallax = get_node("../Parallax2D") as Parallax2D
		if parallax:
			return parallax.autoscroll.y
	if owner and "game_speed" in owner: 
		return owner.game_speed
	return 300.0

func _on_vehicle_hit_player(damage: int) -> void: player_damaged.emit(damage)
# Cuando un auto sale de pantalla o es rebasado con éxito, puedes dar puntos:
