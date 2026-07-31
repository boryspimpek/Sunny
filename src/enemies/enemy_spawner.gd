class_name EnemySpawner
extends Area3D

@export var enemy_scene: PackedScene
@export var max_spawns: int = 1
@export var trigger_group: StringName = "player"
@export var auto_collect_markers: bool = true
@export var marker_group: StringName = ""
@export var initial_delay: float = 0.0
@export var spawn_interval: float = 0.0
@export var spawn_points: Array[Node3D]

var _spawned_count := 0
var _triggered := false
var _cached_points: Array[Node3D] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_collect_points()


func _collect_points() -> void:
	if not marker_group.is_empty():
		for node in get_tree().get_nodes_in_group(marker_group):
			if node is Node3D:
				_cached_points.append(node as Node3D)
		return

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
	if initial_delay > 0.0:
		await get_tree().create_timer(initial_delay).timeout

	var points := _cached_points if not _cached_points.is_empty() else spawn_points
	for i in range(points.size()):
		if _spawned_count >= max_spawns:
			break
		if enemy_scene == null:
			break

		var enemy := enemy_scene.instantiate() as Enemy
		get_parent().add_child(enemy)
		enemy.global_position = points[i].global_position
		_spawned_count += 1

		if spawn_interval > 0.0 and i < points.size() - 1 and _spawned_count < max_spawns:
			await get_tree().create_timer(spawn_interval).timeout
