extends Camera3D

# Przeciągniemy tu węzeł gracza w Inspektorze
@export var target: Node3D  

# Stały offset (odsunięcie) kamery od gracza
@export var offset: Vector3 = Vector3(15, 15, 15)  

# Szybkość, z jaką kamera goni gracza (im większa, tym szybsza reakcja)
@export var smooth_speed: float = 5.0  

func _physics_process(delta: float) -> void:
	if target:
		# Obliczamy idealną pozycję docelową kamery
		var target_position = target.global_position + offset
		
		# Płynnie przesuwamy pozycję kamery w stronę celu (interpolacja liniowa - lerp)
		global_position = global_position.lerp(target_position, smooth_speed * delta)
