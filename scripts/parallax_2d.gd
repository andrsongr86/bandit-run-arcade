extends Parallax2D

@onready var ground_layer = $GroundLayer
@onready var deco_layer = $DecoLayer

# Configuraciones del tamaño (en cantidad de tiles de 32x32)
var chunk_height: int = 40 

# Coordenadas de los tiles en el TileSet.
var t_grass = Vector2i(16, 1)
var t_grass_to_side_l = Vector2i(14, 1)
var t_side_to_asphalt_l = Vector2i(5, 1)

var t_road_left = Vector2i(8, 1)  
var t_road_right = Vector2i(9, 1) 

var t_asphalt_to_side_r = Vector2i(3, 1) 
var t_side_to_grass_r = Vector2i(12, 1)    

var t_bush = Vector2i(0, 5)

func _ready():
	generate_highway_chunk()
	repeat_size.y = chunk_height * 32
	autoscroll = Vector2(0, 300)

func generate_highway_chunk():
	var source_id = 0 
	var is_split = get_viewport() is SubViewport
	
	# Usamos 22 tiles de ancho para 1v1 (cubre perfecto el SubViewport) y 32 para un jugador
	var map_width = 22 if is_split else 32
	
	for y in range(chunk_height):
		for x in range(map_width):
			if is_split:
				# --- MODO 1V1: Simétrico (Pasto -> Banqueta izq -> Asfalto 10 tiles -> Banqueta der -> Pasto) ---
				if x < 4:
					ground_layer.set_cell(Vector2i(x, y), source_id, t_grass)
				elif x == 4:
					ground_layer.set_cell(Vector2i(x, y), source_id, t_grass_to_side_l)
				elif x == 5:
					ground_layer.set_cell(Vector2i(x, y), source_id, t_side_to_asphalt_l)
				elif x >= 6 and x <= 15: # 10 celdas de asfalto (5 carriles x 2 tiles)
					if x % 2 == 0:
						ground_layer.set_cell(Vector2i(x, y), source_id, t_road_left)
					else:
						ground_layer.set_cell(Vector2i(x, y), source_id, t_road_right)
				elif x == 16:
					ground_layer.set_cell(Vector2i(x, y), source_id, t_asphalt_to_side_r)
				elif x == 17:
					ground_layer.set_cell(Vector2i(x, y), source_id, t_side_to_grass_r)
				elif x >= 18:
					ground_layer.set_cell(Vector2i(x, y), source_id, t_grass)
			else:
				# --- MODO UN JUGADOR (Original intacto) ---
				if x < 6:
					ground_layer.set_cell(Vector2i(x, y), source_id, t_grass)
				elif x == 6:
					ground_layer.set_cell(Vector2i(x, y), source_id, t_grass_to_side_l)
				elif x == 7:
					ground_layer.set_cell(Vector2i(x, y), source_id, t_side_to_asphalt_l)
				elif x >= 8 and x <= 23:
					if x % 2 == 0:
						ground_layer.set_cell(Vector2i(x, y), source_id, t_road_left)
					else:
						ground_layer.set_cell(Vector2i(x, y), source_id, t_road_right)
				elif x == 24:
					ground_layer.set_cell(Vector2i(x, y), source_id, t_asphalt_to_side_r)
				elif x == 25:
					ground_layer.set_cell(Vector2i(x, y), source_id, t_side_to_grass_r)
				elif x > 25:
					ground_layer.set_cell(Vector2i(x, y), source_id, t_grass)

	generate_decorations(source_id, map_width)

func generate_decorations(source_id: int, map_width: int):
	var occupied = [] 
	var is_split = get_viewport() is SubViewport
	
	for y in range(1, chunk_height - 2): 
		var possible_x = [randi_range(0, 2), randi_range(map_width - 3, map_width - 1)] if is_split else [randi_range(0, 4), randi_range(27, 30)]
		for rx in possible_x:
			var pos = Vector2i(rx, y)
			if pos in occupied: continue
			var chance = randf()
			if chance > 0.85: 
				deco_layer.set_cell(pos, source_id, t_bush)
				occupied.append(pos)
