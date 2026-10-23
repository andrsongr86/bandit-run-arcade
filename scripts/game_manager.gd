class_name GameManagerClass
extends Node

var is_multiplayer: bool = false
var p1_car_texture_path: String = "res://carsprites/Sport/sport_red.png"
var p2_car_texture_path: String = "res://carsprites/Sport/sport_blue.png"
var current_selecting_player: int = 1
var winner_text: String = ""
var final_score: int = 0  

# --- SISTEMA DE HIGH SCORES GLOBAL ---
const SAVE_PATH = "user://highscores.save"
var high_scores: Array = []  

# --- SISTEMA DE MÚSICA DE MENÚ (BGM GLOBAL) ---
var bgm_player: AudioStreamPlayer = null
var menu_music: AudioStream = null
var last_scene_path: String = ""

# --- SISTEMA DE EFECTOS DE SONIDO (SFX) ---
var traffic_explosion_stream: AudioStream = null
var player_explosion_stream: AudioStream = null
var car_horn_stream: AudioStream = null
var truck_horn_stream: AudioStream = null

func _ready() -> void:
	load_high_scores()
	if high_scores.is_empty():
		for i in range(10):
			high_scores.append({"name": "CPU", "score": (10 - i) * 1000})
			
	_init_menu_music()
	_init_sfx_streams()

func _process(_delta: float) -> void:
	var current_scene = get_tree().current_scene
	if current_scene:
		var current_path = current_scene.scene_file_path
		if current_path != last_scene_path:
			last_scene_path = current_path
			_check_scene_music(current_path)

func _init_menu_music() -> void:
	if bgm_player != null:
		return
		
	bgm_player = AudioStreamPlayer.new()
	var music_path = "res://ost/GTI Club： Supermini Festa! Soundtrack - Online Menu.mp3"
	if ResourceLoader.exists(music_path):
		menu_music = load(music_path)
		bgm_player.stream = menu_music
	else:
		print("Advertencia: No se encontró el archivo de música en la ruta: ", music_path)
		
	add_child(bgm_player)

func _init_sfx_streams() -> void:
	_load_stream_safely("traffic_explosion_stream", "res://sound/crash-sound-effect.mp3")
	_load_stream_safely("player_explosion_stream", "res://sound/car-crash-and-siren.mp3")
	_load_stream_safely("car_horn_stream", "res://sound/car-horn-2.mp3")
	_load_stream_safely("truck_horn_stream", "res://sound/truck-horn.mp3")

func _load_stream_safely(variable_name: String, path: String) -> void:
	if ResourceLoader.exists(path):
		set(variable_name, load(path))
	else:
		print("Aviso SFX: No se encontró el archivo de audio en: ", path)

# Actualizado para aceptar un ajuste opcional de volumen en decibelios (volume_db)
func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream: return
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	get_tree().current_scene.add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

# --- NUEVA FUNCIÓN: FUNDIDO DE MÚSICA EN 1 SEGUNDO ---
func fade_out_scene_music(duration: float = 1.0) -> void:
	var current_scene = get_tree().current_scene
	if not current_scene: return
	
	# Buscamos el reproductor de música de la escena actual (ej. BGMPlayer)
	var music_player = current_scene.get_node_or_null("BGMPlayer")
	if not music_player:
		music_player = _find_audio_player_recursive(current_scene)
		
	if music_player and music_player is AudioStreamPlayer and music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, duration)
		tween.tween_callback(music_player.stop)

func _find_audio_player_recursive(node: Node) -> AudioStreamPlayer:
	for child in node.get_children():
		if child is AudioStreamPlayer and child != bgm_player:
			return child
		var found = _find_audio_player_recursive(child)
		if found:
			return found
	return null

func _check_scene_music(path: String) -> void:
	if not bgm_player or not menu_music:
		return
		
	var lower_path = path.to_lower()
	
	if "arcade_game" in lower_path or "split_screen" in lower_path or "game_over" in lower_path:
		if bgm_player.playing:
			bgm_player.stop()
	else:
		if not bgm_player.playing:
			bgm_player.play()

func reset_game() -> void:
	current_selecting_player = 1
	winner_text = ""
	final_score = 0

func is_high_score(new_score: int) -> bool:
	for entry in high_scores:
		if new_score > entry["score"]: return true
	return false

func add_high_score(player_name: String, new_score: int) -> void:
	high_scores.append({"name": player_name, "score": new_score})
	high_scores.sort_custom(func(a, b): return a["score"] > b["score"])
	if high_scores.size() > 10:
		high_scores.resize(10)
	save_high_scores()

func save_high_scores() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(high_scores)
		file.close()

func load_high_scores() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			if typeof(data) == TYPE_ARRAY:
				high_scores = data
			file.close()

# --- FUNCIÓN GLOBAL DE EXPLOSIÓN CON VOLÚMENES PERSONALIZADOS ---
func spawn_explosion(target_position: Vector2, is_player: bool = false) -> void:
	var target_stream = player_explosion_stream if is_player else traffic_explosion_stream
	if target_stream:
		# Explotación de jugador más alta (+5 dB), tráfico a volumen normal (0 dB)
		var exp_volume = 5.0 if is_player else 0.0
		play_sfx(target_stream, exp_volume)
		
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
		
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 35 if not is_player else 55
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 280.0 if not is_player else 350.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0 if not is_player else 10.0
	particles.color = Color(1.0, 0.45, 0.1) 
	
	particles.global_position = target_position
	current_scene.add_child(particles)
	particles.emitting = true
	
	var timer = create_timer(1.0)
	if timer:
		timer.timeout.connect(particles.queue_free)

func create_timer(time_sec: float) -> SceneTreeTimer:
	return get_tree().create_timer(time_sec)
