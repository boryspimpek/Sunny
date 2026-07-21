class_name PatrolMovement
extends MovementBehavior
## Wróg patroluje między punktami (offsety względem pozycji startowej).

@export var patrol_offsets: Array[Vector3] = [Vector3(5, 0, 0), Vector3(-5, 0, 0)]
@export var speed: float = 2.0
@export var arrive_threshold: float = 0.5

var _origin := Vector3.ZERO
var _origin_set := false
var _index := 0


func get_movement(enemy: Enemy, _target: Node3D, _delta: float) -> Vector3:
	if patrol_offsets.is_empty():
		return Vector3.ZERO
	if not _origin_set:
		_origin = enemy.global_position
		_origin_set = true

	var destination := _origin + patrol_offsets[_index]
	var to_destination := destination - enemy.global_position
	to_destination.y = 0.0
	if to_destination.length() <= arrive_threshold:
		_index = (_index + 1) % patrol_offsets.size()
		return Vector3.ZERO
	return to_destination.normalized() * speed
