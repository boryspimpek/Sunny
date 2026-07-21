class_name ChaseMovement
extends MovementBehavior
## Wróg goni cel, gdy ten jest w zasięgu wykrycia.

@export var speed: float = 3.0
@export var detection_range: float = 20.0
@export var stop_distance: float = 2.0


func get_movement(enemy: Enemy, target: Node3D, _delta: float) -> Vector3:
	if target == null:
		return Vector3.ZERO
	var to_target := target.global_position - enemy.global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance > detection_range or distance <= stop_distance:
		return Vector3.ZERO
	return to_target.normalized() * speed
