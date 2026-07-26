class_name ChaseMovement
extends MovementBehavior
## Wróg goni cel, gdy ten jest w zasięgu wykrycia.

@export var speed: float = 3.0
@export var detection_range: float = 20.0
@export var stop_distance: float = 2.0
@export var idle_animation: StringName = "ZombieMoves/idle"
@export var walk_animation: StringName = "ZombieMoves/walking"


func get_movement(enemy: Enemy, target: Node3D, _delta: float) -> Vector3:
	if target == null:
		_update_animation(enemy, false)
		return Vector3.ZERO

	var to_target := target.global_position - enemy.global_position
	to_target.y = 0.0
	var distance := to_target.length()
	var desired := Vector3.ZERO

	if distance > detection_range or distance <= stop_distance:
		desired = Vector3.ZERO
	else:
		desired = to_target.normalized() * speed

	_update_animation(enemy, desired.length() > 0.01)

	if desired.length() > 0.01:
		enemy.look_at(enemy.global_position - desired, Vector3.UP)

	return desired


func _update_animation(enemy: Enemy, is_walking: bool) -> void:
	var anim := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim == null:
		return

	var target_anim: StringName
	if is_walking:
		target_anim = walk_animation
	else:
		target_anim = idle_animation

	if anim.current_animation == target_anim and anim.is_playing():
		return

	if anim.is_playing() and anim.current_animation != idle_animation and anim.current_animation != walk_animation:
		return

	anim.play(target_anim)
