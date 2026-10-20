extends Control

@onready var p1_viewport: SubViewport = $HBoxContainer/SubViewportContainerP1/SubViewportP1
@onready var p2_viewport: SubViewport = $HBoxContainer/SubViewportContainerP2/SubViewportP2
@onready var winner_label: Label = $WinnerLabel # Opcional si quieres mostrarlo un segundo antes de cambiar

var game_ended: bool = false
var mgr_p1: LocalGameManager = null
var mgr_p2: LocalGameManager = null

func _ready() -> void:
	GameManager.is_multiplayer = true
	var game_scene = preload("res://scenes/arcade_game.tscn")
	
	# --- INSTANCIAR JUGADOR 1 ---
	var world_p1 = game_scene.instantiate()
	p1_viewport.add_child(world_p1)
	
	var player_p1 = world_p1.get_node_or_null("PlayerArcade")
	if player_p1:
		player_p1.player_id = 1
	
	mgr_p1 = world_p1.get_node_or_null("LocalGameManager") as LocalGameManager
	if mgr_p1:
		mgr_p1.game_over_triggered.connect(_on_p1_lost)

	# --- INSTANCIAR JUGADOR 2 ---
	var world_p2 = game_scene.instantiate()
	
	# Buscamos y configuramos el ID ANTES de hacer el add_child
	var player_p2 = world_p2.get_node_or_null("PlayerArcade")
	if player_p2:
		player_p2.player_id = 2
		
	p2_viewport.add_child(world_p2) # <--- Ahora sí lo añadimos al árbol
	
	mgr_p2 = world_p2.get_node_or_null("LocalGameManager") as LocalGameManager
	if mgr_p2:
		mgr_p2.game_over_triggered.connect(_on_p2_lost)

func _on_p1_lost() -> void:
	if game_ended: return
	# Si pierde P1, gana P2 (pasamos el puntaje del ganador)
	var winning_score = mgr_p2.score if mgr_p2 else 0
	_declare_winner("¡JUGADOR 2 GANA!", winning_score)

func _on_p2_lost() -> void:
	if game_ended: return
	# Si pierde P2, gana P1 (pasamos el puntaje del ganador)
	var winning_score = mgr_p1.score if mgr_p1 else 0
	_declare_winner("¡JUGADOR 1 GANA!", winning_score)

func _declare_winner(message: String, final_score: int) -> void:
	game_ended = true
	
	if winner_label:
		winner_label.text = message
		winner_label.show()
	
	# Guardamos los datos en el GameManager global para que game_over.gd los lea
	if GameManager:
		GameManager.winner_text = message
		GameManager.final_score = final_score
	
	# Opcional: Pequeña pausa de 1 segundo para leer el texto en pantalla si tienes el Label
	await get_tree().create_timer(1.0).timeout
	
	# Cambiamos a la escena de Game Over estándar
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")
