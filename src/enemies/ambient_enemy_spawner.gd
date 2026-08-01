class_name AmbientEnemySpawner
extends Node3D
## Ciągły spawner wrogów wokół gracza.
## Co losowy czas spawnuje małą, losową falę wrogów na pierścieniu
## między min_spawn_radius a max_spawn_radius, dopasowując pozycję Y do terenu.

@export var enemy_scene: PackedScene
@export var min_spawn_radius: float = 12.0
@export var max_spawn_radius: float = 20.0
@export var min_spawn_count: int = 1
@export var max_spawn_count: int = 3
@export var min_spawn_interval: float = 8.0
@export var max_spawn_interval: float = 15.0
@export var max_active_enemies: int = 10
@export var terrain_collision_mask: int = 1
@export var spawn_height_offset: float = 50.0
@export var max_spawn_retries: int = 5

var _timer: Timer
var _player: Node3D


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_start_timer()


func _start_timer() -> void:
	var wait := randf_range(min_spawn_interval, max_spawn_interval)
	_timer.start(wait)


func _on_timer_timeout() -> void:
	_spawn_wave()
	_start_timer()


func _spawn_wave() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null or not is_instance_valid(_player):
		return

	var active := get_tree().get_nodes_in_group("enemy").size()
	var to_spawn := randi_range(min_spawn_count, max_spawn_count)

	if active < max_active_enemies:
		to_spawn = min(to_spawn, max_active_enemies - active)
		for i in range(to_spawn):
			var spawn_pos := _find_spawn_position()
			if spawn_pos == Vector3.INF:
				continue
			_spawn_enemy(spawn_pos)
	else:
		# przy pełnym limicie przesuwamy najdalszych zamiast tworzyć nowych
		for i in range(to_spawn):
			var spawn_pos := _find_spawn_position()
			if spawn_pos == Vector3.INF:
				continue
			_respawn_furthest_enemy(spawn_pos)


func _find_spawn_position() -> Vector3:
	var player_pos := _player.global_position
	var angle := randf() * TAU
	# jednolity rozkład w pierścieniu (r^2 zamiast r)
	var t := randf()
	var r_min_sq := min_spawn_radius * min_spawn_radius
	var r_max_sq := max_spawn_radius * max_spawn_radius
	var radius := sqrt(r_min_sq + t * (r_max_sq - r_min_sq))
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * radius
	var origin := player_pos + offset

	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.new()
	query.from = origin + Vector3.UP * spawn_height_offset
	query.to = origin - Vector3.UP * spawn_height_offset
	query.collision_mask = terrain_collision_mask
	var result := space.intersect_ray(query)
	if result.is_empty():
		return Vector3.INF

	return result.position


func _spawn_enemy(spawn_position: Vector3) -> void:
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		return
	get_parent().add_child(enemy)
	enemy.global_position = spawn_position
	enemy.target = _player


func _respawn_furthest_enemy(spawn_position: Vector3) -> void:
	var furthest: Enemy = null
	var furthest_dist_sq := -1.0
	for node in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(node) or not (node is Enemy):
			continue
		var enemy := node as Enemy
		if not enemy.is_physics_processing():
			continue
		var dist_sq := _player.global_position.distance_squared_to(enemy.global_position)
		if dist_sq > furthest_dist_sq:
			furthest_dist_sq = dist_sq
			furthest = enemy
	if furthest == null:
		return
	furthest.global_position = spawn_position
	furthest.velocity = Vector3.ZERO
	furthest.target = _player
