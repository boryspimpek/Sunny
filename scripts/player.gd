extends CharacterBody3D

# --- Parametry ruchu ---
@export var max_speed: float = 5.0      # Maksymalna prędkość biegu
@export var acceleration: float = 6.0   # Jak szybko postać przyspiesza
@export var friction: float = 8.0       # Jak szybko postać się zatrzymuje
@export var jump_strength: float = 8.0  # Siła skoku
@export var rotation_speed: float = 12.0 # Szybkość obracania postaci
@export var gamepad_camera_sensitivity: float = 2.5
@export var roll_distance: float = 5.0
@export_range(-89.0, 0.0, 1.0, "degrees") var camera_pitch_min: float = -45.0
@export_range(-30.0, 89.0, 1.0, "degrees") var camera_pitch_max: float = 45.0

# Grawitacja pobrana z ustawień projektu Godota
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- Referencje do węzłów ---
# @onready pobiera węzeł AnimationTree zaraz po uruchomieniu gry
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var model: Node3D = $Skeleton3D
@onready var spring_arm_pivot: Node3D = $SpringArmPivot
@onready var spring_arm: SpringArm3D = $SpringArmPivot/SpringArm3D

var action_animation_playing := false
var roll_hips_bone := -1
var roll_root_motion_start := Vector3.ZERO
var roll_direction := Vector3.ZERO
var roll_displacement_pending := Vector3.ZERO
var roll_pivot_initial_position := Vector3.ZERO

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	animation_tree.active = true
	spring_arm.add_excluded_object(get_rid())
	roll_hips_bone = model.find_bone("mixamorig_Hips")
	animation_player.animation_finished.connect(_on_animation_finished)

func _play_action_animation(animation_name: StringName) -> void:
	if action_animation_playing:
		return

	action_animation_playing = true
	animation_tree.active = false
	animation_player.play(animation_name)
	if animation_name == &"Moves/roll" and roll_hips_bone != -1:
		animation_player.advance(0.0)
		roll_direction = model.global_transform.basis.z.normalized()
		roll_pivot_initial_position = spring_arm_pivot.position
		roll_root_motion_start = model.get_bone_global_pose(roll_hips_bone).origin

func _update_roll_camera_position() -> void:
	if roll_hips_bone == -1:
		return

	var current_root_motion: Vector3 = model.get_bone_global_pose(roll_hips_bone).origin
	var root_motion_offset: Vector3 = current_root_motion - roll_root_motion_start
	root_motion_offset.y = 0.0
	spring_arm_pivot.position = roll_pivot_initial_position + model.transform.basis * root_motion_offset

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"Moves/jump" or animation_name == &"Moves/roll":
		if animation_name == &"Moves/roll":
			roll_displacement_pending = roll_direction * roll_distance
		action_animation_playing = false
		animation_tree.active = true

func _physics_process(delta: float) -> void:
	if action_animation_playing and animation_player.current_animation == &"Moves/roll":
		_update_roll_camera_position()
	if not roll_displacement_pending.is_zero_approx():
		move_and_collide(roll_displacement_pending)
		spring_arm_pivot.position = roll_pivot_initial_position
		roll_displacement_pending = Vector3.ZERO

	var camera_input := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	spring_arm_pivot.rotate_y(-camera_input.x * gamepad_camera_sensitivity * delta)
	spring_arm.rotate_x(-camera_input.y * gamepad_camera_sensitivity * delta)
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(camera_pitch_min), deg_to_rad(camera_pitch_max))

	# 1. Obsługa grawitacji (spadanie na ziemię)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Skok
	if Input.is_action_just_pressed("jump") and is_on_floor() and not action_animation_playing:
		velocity.y = jump_strength
		_play_action_animation(&"Moves/jump")
	if Input.is_action_just_pressed("roll") and is_on_floor():
		_play_action_animation(&"Moves/roll")

	# 2. Odczytanie wejścia od gracza (WASD)
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# 3. Kierunek ruchu względem kamery (spłaszczony na płaszczyźnie XZ)
	var target_direction := Vector3(input_dir.x, 0.0, input_dir.y)
	target_direction = target_direction.rotated(Vector3.UP, spring_arm_pivot.global_rotation.y)

	# 4. Obrót postaci w stronę ruchu i płynne przyspieszanie/hamowanie
	if target_direction.length() > 0.01:
		var target_angle: float = spring_arm_pivot.global_rotation.y + PI - global_rotation.y
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, rotation_speed * delta)
		velocity.x = move_toward(velocity.x, target_direction.x * max_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_direction.z * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	# 5. Wykonanie ruchu fizycznego
	move_and_slide()

	# 6. Aktualizacja AnimationTree (mieszanie animacji idle/running)
	if not action_animation_playing:
		var blend_value := Vector2(input_dir.x, -input_dir.y)
		animation_tree.set("parameters/blend_position", blend_value)
