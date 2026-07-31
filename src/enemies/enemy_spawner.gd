class_name EnemySpawner
extends Area3D

@export var enemy_scene: PackedScene
@export var max_spawns: int = 1
@export var trigger_group: StringName = "player"
@export var auto_collect_markers: bool = true
@export var spawn_points: Array[Node3D]

var _spawned_count := 0
var _triggered := false
var _cached_points: Array[Node3D] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_collect_points()


func _collect_points() -> void:
	if auto_collect_markers:
		for child in get_children():
			if child is Marker3D:
				_cached_points.append(child)
	_cached_points.append_array(spawn_points)


func _on_body_entered(body: Node3D) -> void:
	if _triggered:
		return
	if not body.is_in_group(trigger_group):
		return
	_triggered = true
	_spawn()


func _spawn() -> void:
	var points := _cached_points if not _cached_points.is_empty() else spawn_points
	for point in points:
		if _spawned_count >= max_spawns:
			break
		if enemy_scene == null:
			break
		var enemy := enemy_scene.instantiate() as Enemy
		get_parent().add_child(enemy)
		enemy.global_position = point.global_position
		_spawned_count += 1
