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
@onready var model: Node3D = $Skeleton3D
@onready var spring_arm_pivot: Node3D = $SpringArmPivot
@onready var spring_arm: SpringArm3D = $SpringArmPivot/SpringArm3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera = $SpringArmPivot/SpringArm3D/Camera3D

	
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		spring_arm_pivot.rotate_y(-event.relative.x * 0.005)
		spring_arm.rotate_x(-event.relative.y * 0.005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI / 4.0, PI / 4.0)

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
	var target_direction := Vector3(input_dir.x, 0.0, input_dir.y)
	target_direction = target_direction.rotated(Vector3.UP, spring_arm_pivot.global_rotation.y)

	# 4. Obrót postaci w stronę ruchu i płynne przyspieszanie/hamowanie
	if target_direction.length() > 0.01:
		var target_angle: float = atan2(target_direction.x, target_direction.z) - global_rotation.y
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, rotation_speed * delta)
		velocity.x = move_toward(velocity.x, target_direction.x * max_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_direction.z * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	# 5. Wykonanie ruchu fizycznego
	move_and_slide()

	# 6. Aktualizacja AnimationTree (mieszanie animacji idle/running)
	var horizontal_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var blend_value: float = clamp(horizontal_velocity.length() / max_speed, 0.0, 1.0)
	animation_tree.set("parameters/blend_position", blend_value)
