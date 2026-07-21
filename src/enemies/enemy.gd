class_name Enemy
extends CharacterBody3D
## Baza wroga: HP, śmierć, drop lootu. Ruch i atak delegowane do
## komponentów-dzieci MovementBehavior / AttackBehavior (podpinane w scenie).

@export var score_value: int = 10
@export var drops: Array[PackedScene] = []
@export var death_sound: AudioStream

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var movement_behavior: MovementBehavior
var attack_behavior: AttackBehavior
var target: Node3D

@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	add_to_group("enemy")
	for child in get_children():
		if child is MovementBehavior:
			movement_behavior = child
		elif child is AttackBehavior:
			attack_behavior = child
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player")

	if not is_on_floor():
		velocity.y -= gravity * delta

	if movement_behavior != null:
		var desired := movement_behavior.get_movement(self, target, delta)
		velocity.x = desired.x
		velocity.z = desired.z
	move_and_slide()

	if attack_behavior != null:
		attack_behavior.try_attack(self, target, delta)


func _on_died() -> void:
	EventBus.enemy_died.emit(global_position)
	GameState.add_score(score_value)
	if death_sound != null:
		EventBus.sfx_requested.emit(death_sound, global_position)
	_spawn_drops()
	queue_free()


func _spawn_drops() -> void:
	for drop_scene in drops:
		if drop_scene == null:
			continue
		var drop := drop_scene.instantiate() as Node3D
		get_parent().add_child(drop)
		drop.global_position = global_position
