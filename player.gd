extends CharacterBody3D

# --- Parametry ruchu ---
@export var max_speed: float = 5.0      # Maksymalna prędkość biegu
@export var acceleration: float = 6.0   # Jak szybko postać przyspiesza
@export var friction: float = 8.0       # Jak szybko postać się zatrzymuje
@export var jump_strength: float = 8.0  # Siła skoku
@export var camera: Camera3D            # Referencja do kamery (opcjonalnie)
@export var rotation_speed: float = 12.0 # Szybkość obracania postaci

# Grawitacja pobrana z ustawień projektu Godota
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Referencje do węzłów ---
# @onready pobiera węzeł AnimationTree zaraz po uruchomieniu gry
@onready var animation_tree: AnimationTree = $AnimationTree

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if camera == null:
		camera = get_node_or_null("../Camera3D")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# 1. Obsługa grawitacji (spadanie na ziemię)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Skok
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_strength

	# 2. Odczytanie wejścia od gracza (WASD)
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# 3. Kierunek ruchu względem kamery (spłaszczony na płaszczyźnie XZ)
	var target_direction: Vector3 = Vector3.ZERO
	if camera:
		var cam_forward: Vector3 = -camera.global_transform.basis.z
		cam_forward.y = 0.0
		cam_forward = cam_forward.normalized()
		var cam_right: Vector3 = camera.global_transform.basis.x
		cam_right.y = 0.0
		cam_right = cam_right.normalized()
		target_direction = cam_forward * -input_dir.y + cam_right * input_dir.x
	else:
		target_direction = transform.basis.x * input_dir.x + transform.basis.z * -input_dir.y

	# 4. Obrót postaci w stronę ruchu i płynne przyspieszanie/hamowanie
	if target_direction.length() > 0.01:
		var target_angle: float = atan2(target_direction.x, target_direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
		velocity.x = move_toward(velocity.x, transform.basis.z.x * max_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, transform.basis.z.z * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	# 5. Wykonanie ruchu fizycznego
	move_and_slide()

	# 6. Aktualizacja AnimationTree (mieszanie animacji idle/running)
	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var blend_value: float = clamp(horizontal_velocity.length() / max_speed, 0.0, 1.0)
	animation_tree.set("parameters/blend_position", blend_value)
