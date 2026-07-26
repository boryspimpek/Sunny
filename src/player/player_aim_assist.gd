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

@export var laser_length: float = 50.0
@export var laser_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var laser_emission: float = 3.0

var _laser_mesh: MeshInstance3D
var _laser_im: ImmediateMesh
var _laser_mat: StandardMaterial3D


func _ready() -> void:
	_laser_mesh = MeshInstance3D.new()
	_laser_im = ImmediateMesh.new()
	_laser_mat = StandardMaterial3D.new()
	_laser_mesh.mesh = _laser_im
	_laser_mesh.top_level = true
	_laser_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_laser_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_laser_mat.albedo_color = laser_color
	_laser_mat.emission_enabled = true
	_laser_mat.emission = laser_color
	_laser_mat.emission_energy = laser_emission
	_laser_mesh.material_override = _laser_mat
	body.get_parent().add_child.call_deferred(_laser_mesh)


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


func _process(_delta: float) -> void:
	if not Input.is_action_pressed("combat_mode"):
		_laser_mesh.visible = false
		return
	_laser_mesh.visible = true
	_update_laser()


func _update_laser() -> void:
	var spawn_pos := body.global_position + Vector3.UP
	var end_pos := spawn_pos + aim_direction * laser_length
	var space_state := body.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(spawn_pos, end_pos, 1 | 4, [body.get_rid()])
	var result := space_state.intersect_ray(query)
	if not result.is_empty():
		end_pos = result["position"] as Vector3

	_laser_im.clear_surfaces()
	_laser_im.surface_begin(Mesh.PRIMITIVE_LINES)
	_laser_im.surface_add_vertex(spawn_pos)
	_laser_im.surface_add_vertex(end_pos)
	_laser_im.surface_end()
