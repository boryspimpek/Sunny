class_name PlayerAimAssist
extends Node
## Delikatne dociąganie kamery do najbliższego wroga w stożku celowania.

@export var aim_assist_strength: float = 4.0
@export_range(1.0, 45.0, 1.0, "degrees") var aim_assist_cone: float = 18.0
@export var aim_assist_range: float = 20.0

@onready var body: CharacterBody3D = get_parent()
@onready var spring_arm_pivot: Node3D = body.get_node("SpringArmPivot")
@onready var camera: Camera3D = body.get_node("SpringArmPivot/SpringArm3D/Camera3D")

var current_target: Node3D
var aim_direction: Vector3 = Vector3.FORWARD


func apply(delta: float) -> void:
	var camera_forward := -camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	current_target = null
	var best_alignment := cos(deg_to_rad(aim_assist_cone))

	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Node3D
		if enemy == null:
			continue
		var direction_to_enemy := enemy.global_position - camera.global_position
		direction_to_enemy.y = 0.0
		if direction_to_enemy.length() > aim_assist_range or direction_to_enemy.is_zero_approx():
			continue
		var alignment := camera_forward.dot(direction_to_enemy.normalized())
		if alignment > best_alignment:
			best_alignment = alignment
			current_target = enemy

	if current_target != null:
		var target_direction := current_target.global_position - camera.global_position
		target_direction.y = 0.0
		var angle_to_target := camera_forward.signed_angle_to(target_direction.normalized(), Vector3.UP)
		var max_rotation := aim_assist_strength * delta
		spring_arm_pivot.rotate_y(clampf(angle_to_target, -max_rotation, max_rotation))

	_update_aim_direction(camera_forward)


func get_aim_direction() -> Vector3:
	return aim_direction


func _update_aim_direction(fallback: Vector3) -> void:
	if current_target != null:
		var spawn_pos := body.global_position + Vector3.UP
		var to_target := current_target.global_position - spawn_pos
		to_target.y = 0.0
		if not to_target.is_zero_approx():
			aim_direction = to_target.normalized()
			return
	aim_direction = fallback.normalized()
