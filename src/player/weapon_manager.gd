class_name WeaponManager
extends Node
## Ekwipunek broni gracza: strzelanie, amunicja, przeładowanie, przełączanie broni.
## Bronie definiowane jako WeaponResource (.tres) w resources/weapons/.

@export var weapons: Array[WeaponResource] = []

@onready var body: CharacterBody3D = get_parent()
@onready var aim_assist: PlayerAimAssist = body.get_node("PlayerAimAssist")
@onready var muzzle_marker: Marker3D = body.get_node_or_null("Skeleton3D/WeaponAttachment/PistolMount/gun_6/Muzzle")

var current_index := 0
var ammo: Array[int] = []
var fire_cooldown := 0.0
var reload_timer := 0.0


func _ready() -> void:
	for weapon in weapons:
		ammo.append(weapon.magazine_size)
	if current_weapon() != null:
		EventBus.weapon_changed.emit(current_weapon())
		EventBus.ammo_changed.emit(ammo[current_index], current_weapon().magazine_size)


func current_weapon() -> WeaponResource:
	if current_index >= 0 and current_index < weapons.size():
		return weapons[current_index]
	return null


func update(delta: float, want_fire: bool) -> void:
	fire_cooldown = maxf(fire_cooldown - delta, 0.0)

	if reload_timer > 0.0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()
		return

	if want_fire and fire_cooldown <= 0.0:
		_shoot()


func add_weapon(weapon: WeaponResource) -> void:
	weapons.append(weapon)
	ammo.append(weapon.magazine_size)


func switch_weapon(index: int) -> void:
	if index < 0 or index >= weapons.size() or index == current_index:
		return
	current_index = index
	reload_timer = 0.0
	fire_cooldown = 0.0
	EventBus.weapon_changed.emit(current_weapon())
	EventBus.ammo_changed.emit(ammo[current_index], current_weapon().magazine_size)


func add_ammo(amount: int) -> void:
	var weapon := current_weapon()
	if weapon == null:
		return
	ammo[current_index] = mini(ammo[current_index] + amount, weapon.magazine_size)
	EventBus.ammo_changed.emit(ammo[current_index], weapon.magazine_size)


func start_reload() -> void:
	var weapon := current_weapon()
	if weapon == null or reload_timer > 0.0:
		return
	reload_timer = weapon.reload_time
	EventBus.reload_started.emit(weapon.reload_time)
	if weapon.reload_sound != null:
		EventBus.sfx_requested.emit(weapon.reload_sound, body.global_position)


func _shoot() -> void:
	var weapon := current_weapon()
	if weapon == null:
		return
	if weapon.magazine_size > 0 and ammo[current_index] <= 0:
		start_reload()
		return

	var direction: Vector3 = aim_assist.get_aim_direction()
	var spawn_pos := body.global_position + Vector3.UP
	if muzzle_marker != null:
		spawn_pos = muzzle_marker.global_position
	var end_pos := spawn_pos + direction * aim_assist.aim_assist_range

	var space_state := body.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(spawn_pos, end_pos, 1 | 4, [body.get_rid()])
	var result := space_state.intersect_ray(query)
	if not result.is_empty():
		var hit_body := result["collider"] as Node3D
		if hit_body != null:
			var health := hit_body.get_node_or_null("HealthComponent") as HealthComponent
			if health != null:
				health.take_damage(weapon.damage)
		if weapon.hit_effect_scene != null:
			_spawn_hit_effect(result["position"], weapon.hit_effect_scene)

	if weapon.muzzle_flash_scene != null:
		var muzzle: Node3D = weapon.muzzle_flash_scene.instantiate()
		body.get_parent().add_child(muzzle)
		muzzle.global_position = spawn_pos + direction
		muzzle.look_at(muzzle.global_position + direction)
		muzzle.rotate_object_local(Vector3.UP, deg_to_rad(90))
		get_tree().create_timer(0.5).timeout.connect(muzzle.queue_free)

	fire_cooldown = weapon.fire_interval

	if weapon.magazine_size > 0:
		ammo[current_index] -= 1
		EventBus.ammo_changed.emit(ammo[current_index], weapon.magazine_size)
		if ammo[current_index] <= 0:
			start_reload()
	if weapon.fire_sound != null:
		EventBus.sfx_requested.emit(weapon.fire_sound, body.global_position)


func _spawn_hit_effect(position: Vector3, scene: PackedScene) -> void:
	var effect := scene.instantiate() as Node3D
	body.get_parent().add_child(effect)
	effect.global_position = position


func _finish_reload() -> void:
	reload_timer = 0.0
	var weapon := current_weapon()
	if weapon == null:
		return
	ammo[current_index] = weapon.magazine_size
	EventBus.reload_finished.emit()
	EventBus.ammo_changed.emit(ammo[current_index], weapon.magazine_size)
