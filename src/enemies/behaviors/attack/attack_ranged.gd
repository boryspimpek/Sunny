class_name RangedAttack
extends AttackBehavior
## Wróg strzela pociskami do celu w zasięgu.

@export var projectile_scene: PackedScene
@export var damage: float = 5.0
@export var projectile_speed: float = 20.0
@export var hit_effect_scene: PackedScene
@export var fire_interval: float = 1.5
@export var attack_range: float = 15.0
@export var fire_sound: AudioStream

var _cooldown := 0.0


func try_attack(enemy: Enemy, target: Node3D, delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if projectile_scene == null or target == null or _cooldown > 0.0:
		return

	var to_target := target.global_position - enemy.global_position
	if to_target.length() > attack_range:
		return

	var direction := to_target.normalized()
	var projectile: Projectile = projectile_scene.instantiate()
	enemy.get_parent().add_child(projectile)
	projectile.global_position = enemy.global_position + direction + Vector3.UP
	projectile.setup(direction, damage, hit_effect_scene, projectile_speed)
	_cooldown = fire_interval
	if fire_sound != null:
		EventBus.sfx_requested.emit(fire_sound, enemy.global_position)
