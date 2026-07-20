extends Area3D
class_name Projectile

@export var speed := 60.0
@export var lifetime := 2.0

var direction := Vector3.FORWARD

func setup(shot_direction: Vector3) -> void:
	direction = shot_direction.normalized()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		body.queue_free()
	queue_free()
