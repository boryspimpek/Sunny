extends Camera3D

@export var target: Node3D
@export var distance: float = 4.0
@export var height: float = 2.0
@export var sensitivity: float = 0.003
@export var pitch_min: float = -45.0
@export var pitch_max: float = 60.0
@export var smooth_speed: float = 10.0

var yaw: float = 0.0
var pitch: float = 0.0

func _ready() -> void:
	if target:
		yaw = rotation.y
		pitch = rotation.x
		_snap_to_target()

func _snap_to_target() -> void:
	var direction := Vector3.FORWARD.rotated(Vector3.UP, yaw).rotated(Vector3.RIGHT, pitch)
	global_position = target.global_position + direction * distance + Vector3.UP * height
	look_at(target.global_position + Vector3.UP * 1.5, Vector3.UP)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * sensitivity
		pitch += event.relative.y * sensitivity
		pitch = clamp(pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))

func _process(delta: float) -> void:
	if not target:
		return

	var direction := Vector3.FORWARD.rotated(Vector3.UP, yaw).rotated(Vector3.RIGHT, pitch)
	var target_position := target.global_position + direction * distance + Vector3.UP * height
	global_position = global_position.lerp(target_position, smooth_speed * delta)
	look_at(target.global_position + Vector3.UP * 1.5, Vector3.UP)
