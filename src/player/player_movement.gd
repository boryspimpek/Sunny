class_name PlayerMovement
extends Node
## Ruch gracza: input WASD, przyspieszanie/hamowanie, skok, przewrót, obrót modelu.

@export var max_speed: float = 5.0
@export var combat_max_speed: float = 6.0
@export var acceleration: float = 6.0
@export var friction: float = 8.0
@export var jump_strength: float = 8.0
@export var rotation_speed: float = 12.0
@export var walk_sound: AudioStream

@onready var body: CharacterBody3D = get_parent()
@onready var model: Skeleton3D = body.get_node("Skeleton3D")
@onready var walk_audio: AudioStreamPlayer3D = _create_walk_audio()

var last_input_dir := Vector2.ZERO


func _create_walk_audio() -> AudioStreamPlayer3D:
	var audio := AudioStreamPlayer3D.new()
	audio.name = "WalkAudio"
	audio.stream = walk_sound
	add_child(audio)
	return audio


func update(delta: float, combat_mode: bool, camera_yaw: float, animator: PlayerAnimator) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	last_input_dir = input_dir

	# Kierunek ruchu względem kamery (spłaszczony na płaszczyźnie XZ)
	var target_direction := Vector3(input_dir.x, 0.0, input_dir.y)
	target_direction = target_direction.rotated(Vector3.UP, camera_yaw)

	# W trybie walki model obraca się w stronę kamery
	if combat_mode and not animator.action_animation_playing:
		var target_angle: float = camera_yaw + PI - body.global_rotation.y
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, rotation_speed * delta)

	# Skok i przewrót
	if Input.is_action_just_pressed("jump") and body.is_on_floor() and not animator.action_animation_playing:
		body.velocity.y = jump_strength
		animator.play_action(&"Moves/jump")
	if Input.is_action_just_pressed("roll") and body.is_on_floor() and not animator.action_animation_playing:
		animator.play_action(&"Moves/roll", target_direction)

	# Prędkość pozioma
	if animator.is_rolling():
		body.velocity.x = 0.0
		body.velocity.z = 0.0
	elif target_direction.length() > 0.01:
		if not animator.action_animation_playing and not combat_mode:
			var movement_angle := atan2(target_direction.x, target_direction.z)
			model.global_rotation.y = lerp_angle(model.global_rotation.y, movement_angle, rotation_speed * delta)
		var current_max_speed := combat_max_speed if combat_mode else max_speed
		var current_direction := Vector2(body.velocity.x, body.velocity.z)
		var desired_direction := Vector2(target_direction.x, target_direction.z)
		if current_direction.dot(desired_direction) <= 0.0:
			body.velocity.x = target_direction.x * current_max_speed
			body.velocity.z = target_direction.z * current_max_speed
		else:
			body.velocity.x = move_toward(body.velocity.x, target_direction.x * current_max_speed, acceleration * delta)
			body.velocity.z = move_toward(body.velocity.z, target_direction.z * current_max_speed, acceleration * delta)
		if walk_sound and not walk_audio.playing:
			walk_audio.play()
	else:
		body.velocity.x = 0.0
		body.velocity.z = 0.0
		if walk_audio.playing:
			walk_audio.stop()
