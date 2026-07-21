class_name PlayerAimAssist
extends Node
## Delikatne dociąganie kamery do najbliższego wroga w stożku celowania.

@export var aim_assist_strength: float = 4.0
@export_range(1.0, 45.0, 1.0, "degrees") var aim_assist_cone: float = 18.0
@export var aim_assist_range: float = 20.0

@onready var body: CharacterBody3D = get_parent()
@onready var spring_arm_pivot: Node3D = body.get_node("SpringArmPivot")
@onready var camera: Camera3D = body.get_node("SpringArmPivot/SpringArm3D/Camera3D")


func apply(delta: float) -> void:
	var camera_forward := -camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var target: Node3D
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
			target = enemy

	if target != null:
		var target_direction := target.global_position - camera.global_position
		target_direction.y = 0.0
		var angle_to_target := camera_forward.signed_angle_to(target_direction.normalized(), Vector3.UP)
		var max_rotation := aim_assist_strength * delta
		spring_arm_pivot.rotate_y(clampf(angle_to_target, -max_rotation, max_rotation))
