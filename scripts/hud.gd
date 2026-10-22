class_name HUD
extends CanvasLayer

@onready var score_label: Label = $Control/MarginContainer/HBoxContainer/ScoreLabel
@onready var health_label: Label = $Control/MarginContainer/HBoxContainer/HealthLabel

# Referencias a los elementos de combo que acabamos de añadir al HUD
@onready var combo_container: Control = $Control/ComboContainer # Ajusta esta ruta según dónde hayas colocado tu contenedor de combo
@onready var combo_progress_bar: ProgressBar = $Control/ComboContainer/ComboProgressBar
@onready var combo_label: Label = $Control/ComboContainer/ComboLabel

var player_target: PlayerArcade = null

func _ready() -> void:
	var local_mgr = null
	var current_node = get_parent()
	while current_node:
		local_mgr = current_node.get_node_or_null("LocalGameManager")
		if local_mgr:
			break
		if current_node is Viewport or current_node.name == "Root":
			break
		current_node = current_node.get_parent()
	
	if local_mgr:
		local_mgr.score_changed.connect(_on_score_changed)
		local_mgr.health_changed.connect(_on_health_changed)
		
		_update_score(local_mgr.score)
		_update_health(local_mgr.current_health)
	elif GameManager:
		GameManager.score_changed.connect(_on_score_changed)
		GameManager.health_changed.connect(_on_health_changed)
		
		_update_score(GameManager.score)
		_update_health(GameManager.current_health)
		
	# Buscamos al jugador en esta misma escena para rastrear su combo
	if get_parent():
		player_target = get_parent().get_node_or_null("PlayerArcade")
		
	if combo_container:
		combo_container.visible = false
	if combo_progress_bar:
		combo_progress_bar.max_value = 100.0

func _process(_delta: float) -> void:
	# Actualizamos el estado del combo visualmente desde el HUD
	if player_target and is_instance_valid(player_target):
		if "combo_active" in player_target and player_target.combo_active:
			if combo_container and not combo_container.visible:
				combo_container.visible = true
				
			if combo_progress_bar:
				combo_progress_bar.value = (player_target.combo_timer / player_target.combo_max_time) * 100.0
				
			if combo_label:
				combo_label.text = "X%d\n+%d" % [player_target.combo_multiplier, player_target.combo_points * player_target.combo_multiplier]
		else:
			if combo_container and combo_container.visible:
				combo_container.visible = false

func _on_score_changed(new_score: int) -> void:
	_update_score(new_score)

func _on_health_changed(new_health: int) -> void:
	_update_health(new_health)

func _update_score(points: int) -> void:
	score_label.text = "SCORE: %d" % points

func _update_health(hp: int) -> void:
	if hp <= 0:
		health_label.text = "VIDAS: 0"
	else:
		health_label.text = "VIDAS: %d ❤️" % hp
