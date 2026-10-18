extends Parallax2D

@onready var ground_layer = $GroundLayer
@onready var deco_layer = $DecoLayer

# Configuraciones del tamaño (en cantidad de tiles de 32x32)
var chunk_height: int = 40 # Largo del bloque (1280 píxeles de alto)
var map_width: int = 32    # Ancho total para 16 carriles (1024 píxeles)

# Coordenadas de los tiles en el TileSet.
var t_grass = Vector2i(16, 1)
var t_grass_to_side_l = Vector2i(14, 1)
var t_side_to_asphalt_l = Vector2i(5, 1)

var t_road_left = Vector2i(8, 1)  
var t_road_right = Vector2i(9, 1) 

var t_asphalt_to_side_r = Vector2i(3, 1) 
var t_side_to_grass_r = Vector2i(12, 1)    

var t_bush = Vector2i(0, 5)
var t_tree_tl = Vector2i(0, 3) 
var t_tree_tr = Vector2i(1, 3) 
var t_tree_bl = Vector2i(0, 4) 
var t_tree_br = Vector2i(1, 4) 

func _ready():
	generate_highway_chunk()
	# El repeat_size y el autoscroll ahora se configuran directamente en el Inspector de Parallax2D,
	# pero puedes asignarlos por código si prefieres:
	repeat_size.y = chunk_height * 32
	autoscroll = Vector2(0, 300) # Velocidad automática de la carretera

func generate_highway_chunk():
	var source_id = 0 
	
	for y in range(chunk_height):
		for x in range(map_width):
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

	generate_decorations(source_id)

func generate_decorations(source_id: int):
	var occupied = [] 
	for y in range(1, chunk_height - 2): 
		var possible_x = [randi_range(0, 4), randi_range(27, 30)]
		for rx in possible_x:
			var pos = Vector2i(rx, y)
			if pos in occupied: continue
			var chance = randf()
			if chance > 0.90: 
				deco_layer.set_cell(pos, source_id, t_tree_tl)
				deco_layer.set_cell(pos + Vector2i(1, 0), source_id, t_tree_tr)
				deco_layer.set_cell(pos + Vector2i(0, 1), source_id, t_tree_bl)
				deco_layer.set_cell(pos + Vector2i(1, 1), source_id, t_tree_br)
				occupied.append(pos)
				occupied.append(pos + Vector2i(1, 0))
				occupied.append(pos + Vector2i(0, 1))
				occupied.append(pos + Vector2i(1, 1))
			elif chance > 0.75:
				deco_layer.set_cell(pos, source_id, t_bush)
				occupied.append(pos)
