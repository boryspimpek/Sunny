class_name PlayerCamera
extends Node
## Sterowanie kamerą TPP: SpringArm, obrót gamepadem, ograniczenie pitch.

@export var gamepad_camera_sensitivity: float = 2.5
@export_range(-89.0, 0.0, 1.0, "degrees") var camera_pitch_min: float = -45.0
@export_range(-30.0, 89.0, 1.0, "degrees") var camera_pitch_max: float = 45.0

@export var combat_spring_offset: Vector3 = Vector3(0.6, 0.0, 1.0)
@export var combat_spring_length: float = 1.2
@export var camera_shift_speed: float = 5.0
@export var aim_ray_length: float = 100.0

@onready var body: CharacterBody3D = get_parent()
@onready var spring_arm_pivot: Node3D = body.get_node("SpringArmPivot")
@onready var spring_arm: SpringArm3D = body.get_node("SpringArmPivot/SpringArm3D")
@onready var camera: Camera3D = body.get_node("SpringArmPivot/SpringArm3D/Camera3D")

var normal_spring_offset: Vector3
var normal_spring_length: float


func _ready() -> void:
	spring_arm.add_excluded_object(body.get_rid())
	normal_spring_offset = spring_arm.position
	normal_spring_length = spring_arm.spring_length


func update(delta: float, combat_mode: bool = false) -> void:
	var camera_input := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	spring_arm_pivot.rotate_y(-camera_input.x * gamepad_camera_sensitivity * delta)
	spring_arm.rotate_x(-camera_input.y * gamepad_camera_sensitivity * delta)
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(camera_pitch_min), deg_to_rad(camera_pitch_max))

	var target_offset := combat_spring_offset if combat_mode else normal_spring_offset
	var target_length := combat_spring_length if combat_mode else normal_spring_length
	spring_arm.position = spring_arm.position.lerp(target_offset, camera_shift_speed * delta)
	spring_arm.spring_length = lerp(spring_arm.spring_length, target_length, camera_shift_speed * delta)


func get_yaw() -> float:
	return spring_arm_pivot.global_rotation.y


## Kierunek strzału spłaszczony do płaszczyzny XZ.
## Używa promienia z kamery, aby trafić w to, co widzi celownik.
func get_aim_direction() -> Vector3:
	var ray_origin := camera.global_position
	var ray_dir := -camera.global_transform.basis.z
	var ray_end := ray_origin + ray_dir * aim_ray_length
	var space_state := body.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1 | 4, [body.get_rid()])
	var result := space_state.intersect_ray(query)
	var target_pos := ray_end
	if not result.is_empty():
		target_pos = result["position"] as Vector3
	var spawn_pos := body.global_position + Vector3.UP
	var direction := target_pos - spawn_pos
	direction.y = 0.0
	return direction.normalized()
