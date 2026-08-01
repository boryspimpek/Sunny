class_name AttackPunch
extends AttackBehavior
## Wróg atakuje wręcz, gdy gracz znajdzie się w zasięgu.

@export var attack_range: float = 1.5
@export var attack_cooldown: float = 1.0
@export var attack_animations: Array[StringName] = [
	"ZombieMoves/attack_left",
	"ZombieMoves/attack_right",
	"ZombieMoves/punching_left",
	"ZombieMoves/punching_right"
]

var _cooldown: float = 0.0


func _pick_attack() -> StringName:
	if attack_animations.is_empty():
		return &""
	return attack_animations[randi() % attack_animations.size()]


func _is_attack_animation(anim_name: StringName) -> bool:
	return anim_name in attack_animations


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

	if _is_attack_animation(anim.current_animation) and anim.is_playing():
		return

	var attack := _pick_attack()
	if attack == &"":
		return

	anim.play(attack)
	_cooldown = attack_cooldown


func is_attacking(enemy: Enemy) -> bool:
	var anim := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	return anim != null and _is_attack_animation(anim.current_animation) and anim.is_playing()
