class_name WeaponManager
extends Node
## Ekwipunek broni gracza: strzelanie, amunicja, przeładowanie, przełączanie broni.
## Bronie definiowane jako WeaponResource (.tres) w resources/weapons/.

@export var weapons: Array[WeaponResource] = []

@onready var body: CharacterBody3D = get_parent()
@onready var camera: Camera3D = body.get_node("SpringArmPivot/SpringArm3D/Camera3D")

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
	if weapon == null or weapon.projectile_scene == null:
		return
	if weapon.magazine_size > 0 and ammo[current_index] <= 0:
		start_reload()
		return

	var projectile: Projectile = weapon.projectile_scene.instantiate()
	var direction := -camera.global_transform.basis.z
	direction.y = 0.0
	direction = direction.normalized()
	body.get_parent().add_child(projectile)
	projectile.global_position = body.global_position + direction + Vector3.UP
	projectile.setup(direction, weapon.damage, weapon.hit_effect_scene, weapon.projectile_speed)
	fire_cooldown = weapon.fire_interval

	if weapon.magazine_size > 0:
		ammo[current_index] -= 1
		EventBus.ammo_changed.emit(ammo[current_index], weapon.magazine_size)
	if weapon.fire_sound != null:
		EventBus.sfx_requested.emit(weapon.fire_sound, body.global_position)


func _finish_reload() -> void:
	reload_timer = 0.0
	var weapon := current_weapon()
	if weapon == null:
		return
	ammo[current_index] = weapon.magazine_size
	EventBus.reload_finished.emit()
	EventBus.ammo_changed.emit(ammo[current_index], weapon.magazine_size)
