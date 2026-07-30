class_name AttackPunch
extends AttackBehavior
## Wróg atakuje wręcz, gdy gracz znajdzie się w zasięgu.

@export var attack_range: float = 1.5
@export var attack_cooldown: float = 1.0
@export var attack_animation: StringName = "ZombieMoves/punching"

var _cooldown: float = 0.0


func try_attack(enemy: Enemy, target: Node3D, delta: float) -> void:
	if target == null:
		return

	if _cooldown > 0.0:
		_cooldown -= delta
		return

	var distance := enemy.global_position.distance_to(target.global_position)
	if distance > attack_range:
		return

	var anim := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim == null:
		return

	if anim.current_animation == attack_animation and anim.is_playing():
		return

	anim.play(attack_animation)
	_cooldown = attack_cooldown


func is_attacking(enemy: Enemy) -> bool:
	var anim := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	return anim != null and anim.current_animation == attack_animation and anim.is_playing()
