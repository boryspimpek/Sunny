class_name PlayerCamera
extends Node
## Sterowanie kamerą TPP: SpringArm, obrót gamepadem, ograniczenie pitch.

@export var gamepad_camera_sensitivity: float = 2.5
@export_range(-89.0, 0.0, 1.0, "degrees") var camera_pitch_min: float = -45.0
@export_range(-30.0, 89.0, 1.0, "degrees") var camera_pitch_max: float = 45.0

@onready var body: CharacterBody3D = get_parent()
@onready var spring_arm_pivot: Node3D = body.get_node("SpringArmPivot")
@onready var spring_arm: SpringArm3D = body.get_node("SpringArmPivot/SpringArm3D")
@onready var camera: Camera3D = body.get_node("SpringArmPivot/SpringArm3D/Camera3D")


func _ready() -> void:
	spring_arm.add_excluded_object(body.get_rid())


func update(delta: float) -> void:
	var camera_input := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	spring_arm_pivot.rotate_y(-camera_input.x * gamepad_camera_sensitivity * delta)
	spring_arm.rotate_x(-camera_input.y * gamepad_camera_sensitivity * delta)
	spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(camera_pitch_min), deg_to_rad(camera_pitch_max))


func get_yaw() -> float:
	return spring_arm_pivot.global_rotation.y


## Kierunek strzału spłaszczony do płaszczyzny XZ.
func get_aim_direction() -> Vector3:
	var direction := -camera.global_transform.basis.z
	direction.y = 0.0
	return direction.normalized()
