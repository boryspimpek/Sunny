extends CharacterBody3D

# --- Parametry ruchu ---
@export var max_speed: float = 5.0      # Maksymalna prędkość biegu
@export var acceleration: float = 6.0   # Jak szybko postać przyspiesza
@export var friction: float = 8.0       # Jak szybko postać się zatrzymuje

# Grawitacja pobrana z ustawień projektu Godota
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Referencje do węzłów ---
# @onready pobiera węzeł AnimationTree zaraz po uruchomieniu gry
@onready var animation_tree: AnimationTree = $AnimationTree

func _physics_process(delta: float) -> void:
	# 1. Obsługa grawitacji (spadanie na ziemię)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Odczytanie wejścia od gracza
	# Wykorzystamy domyślne akcje Godota:
	# - strzałka w górę / W  -> ruch do przodu  (+1)
	# - strzałka w dół / S    -> ruch do tyłu     (-1)
	var input_direction: float = 0.0
	if Input.is_action_pressed("ui_up"):
		input_direction += 1.0
	if Input.is_action_pressed("ui_down"):
		input_direction -= 1.0

	# Ten model jest wyeksportowany tak, że "przód" postaci wskazuje +Z (a nie domyślne -Z),
	# dlatego jako kierunek ruchu używamy +transform.basis.z.
	var target_direction: Vector3 = transform.basis.z * input_direction

	# 3. Płynne przyspieszanie i hamowanie w osiach X i Z (ruch poziomy)
	if input_direction != 0.0:
		# Przyspieszamy w stronę ruchu (do przodu lub do tyłu)
		velocity.x = move_toward(velocity.x, target_direction.x * max_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_direction.z * max_speed, acceleration * delta)
	else:
		# Zwalniamy do zera, gdy nic nie klikamy
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	# 4. Wykonanie ruchu fizycznego (uwzględnia ślizganie po ścianach i ziemi)
	move_and_slide()

	# 5. Aktualizacja AnimationTree (mieszanie animacji idle/running/running_backward)
	# Obliczamy aktualną prędkość poziomą (bez wpływu grawitacji na osi Y)
	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)

	# Skalowanie zakresu BlendSpace1D: -1 (tył), 0 (bez ruchu), +1 (przód)
	# Znak zależy od tego, czy postać porusza się zgodnie z +Z, czy przeciwnie
	var signed_speed: float = horizontal_velocity.dot(transform.basis.z)
	var blend_value: float = clamp(signed_speed / max_speed, -1.0, 1.0)

	# Wysyłamy wartość bezpośrednio do parametru pozycji mieszania w AnimationTree
	animation_tree.set("parameters/blend_position", blend_value)
