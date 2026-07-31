class_name Enemy
extends CharacterBody3D
## Baza wroga: HP, śmierć, drop lootu. Ruch i atak delegowane do
## komponentów-dzieci MovementBehavior / AttackBehavior (podpinane w scenie).

@export var score_value: int = 10
@export var drops: Array[PackedScene] = []

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var movement_behavior: MovementBehavior
var attack_behavior: AttackBehavior
var target: Node3D
var _last_health: float = 0.0

@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	add_to_group("enemy")
	for child in get_children():
		if child is MovementBehavior:
			movement_behavior = child
		elif child is AttackBehavior:
			attack_behavior = child
	_last_health = health.current_health
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")

	if not is_on_floor():
		velocity.y -= gravity * delta

	var animation_player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	var hit_playing := animation_player != null and animation_player.current_animation.begins_with("ZombieMoves/hit") and animation_player.is_playing()

	var is_attacking := attack_behavior != null and attack_behavior.is_attacking(self)

	if not hit_playing and not is_attacking and movement_behavior != null:
		var desired := movement_behavior.get_movement(self, target, delta)
		velocity.x = desired.x
		velocity.z = desired.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()

	if not hit_playing and attack_behavior != null:
		attack_behavior.try_attack(self, target, delta)


func _on_health_changed(current: float, _max_health: float) -> void:
	if current < _last_health and current > 0.0:
		var animation_player := get_node_or_null("AnimationPlayer")
		if animation_player != null:
			var hit_index := randi_range(1, 3)
			animation_player.play("ZombieMoves/hit" + str(hit_index))
	_last_health = current


func _on_died() -> void:
	EventBus.enemy_died.emit(global_position)
	GameState.add_score(score_value)
	set_physics_process(false)
	var idle_audio := get_node_or_null("AudioStreamPlayer3D") as AudioStreamPlayer3D
	if idle_audio != null:
		idle_audio.stop()
	var animation_player := get_node_or_null("AnimationPlayer")
	if animation_player != null:
		var anim_index := randi_range(1, 2)
		animation_player.play("ZombieMoves/dying" + str(anim_index))
		var dying_audio := get_node_or_null("ZombieDying") as AudioStreamPlayer3D
		if dying_audio != null:
			dying_audio.play()

		await animation_player.animation_finished
	_spawn_drops()
	queue_free()


func _spawn_drops() -> void:
	for drop_scene in drops:
		if drop_scene == null:
			continue
		var drop := drop_scene.instantiate() as Node3D
		get_parent().add_child(drop)
		drop.global_position = global_position
