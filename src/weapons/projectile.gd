class_name Projectile
extends Area3D
## Wspólny skrypt pocisku dla gracza i wrogów.
## Warstwy kolizji ustawiane per scena (player_projectile / enemy_projectile).

@export var lifetime: float = 2.0

var damage: float
var speed: float
var direction := Vector3.FORWARD
var hit_effect_scene: PackedScene


func setup(shot_direction: Vector3, shot_damage: float = -1.0, hit_effect: PackedScene = null, shot_speed: float = -1.0) -> void:
	direction = shot_direction.normalized()
	if shot_damage >= 0.0:
		damage = shot_damage
	if hit_effect != null:
		hit_effect_scene = hit_effect
	if shot_speed >= 0.0:
		speed = shot_speed


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	var health := body.get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		health.take_damage(damage)
	_spawn_hit_effect()
	queue_free()


func _spawn_hit_effect() -> void:
	if hit_effect_scene == null:
		return
	var effect := hit_effect_scene.instantiate() as Node3D
	get_parent().add_child(effect)
	effect.global_position = global_position
