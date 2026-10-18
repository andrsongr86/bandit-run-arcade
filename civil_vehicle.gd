extends Vehicle
class_name CivilVehicle

@export var vehicle_sprites: Array[Texture2D] = []

func _ready() -> void:
	super._ready()
	_assign_random_sprite()

func _assign_random_sprite() -> void:
	# Ahora usamos la variable 'sprite' heredada de Vehicle
	if vehicle_sprites.size() > 0 and sprite:
		sprite.texture = vehicle_sprites.pick_random()
