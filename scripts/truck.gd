extends Vehicle
class_name TruckVehicle

@onready var trailer_node: Node2D = $TrailerNode

# Variable para almacenar dónde "debería" estar el furgón en el mundo real
var trailer_global_x: float = 0.0

func _ready() -> void:
	super._ready() # Llama al ready de Vehicle para asignar el color aleatorio al cabezal
	# Inicializamos la posición del furgón exactamente detrás de la cabina
	trailer_global_x = global_position.x

# Sobrescribimos el movimiento base para añadir la física del tráiler
func update_movement(delta: float, game_speed: float) -> void:
	# 1. Mueve la cabina usando la lógica normal de tu juego
	super.update_movement(delta, game_speed)
	
	# 2. INERCIA DEL FURGÓN (Eje X)
	# El furgón intenta alcanzar la posición X de la cabina, pero de forma suavizada (lerp)
	# Un valor de 3.5 da un efecto de arrastre pesado. Cámbialo si lo quieres más rígido o suelto.
	trailer_global_x = lerp(trailer_global_x, global_position.x, 3.5 * delta)
	
	# Anulamos la posición X estricta que le impone la cabina y le damos nuestra X con arrastre
	trailer_node.global_position.x = trailer_global_x
	
	# Hacemos que la colisión "persiga" exactamente al furgón en todo momento
	$TrailerCollision.global_position = $TrailerNode.global_position
	$TrailerCollision.global_rotation = $TrailerNode.global_rotation
	# 3. ROTACIÓN ARTICULADA
	# Calculamos la dirección desde el furgón hacia la cabina
	var direction_to_cab = trailer_node.global_position.direction_to(global_position)
	
	# Como tus autos están dibujados mirando hacia "arriba", usamos Vector2.UP como referencia
	# Esto hace que el furgón rote dinámicamente apuntando su frente hacia el cabezal
	trailer_node.rotation = Vector2.UP.angle_to(direction_to_cab)
	
