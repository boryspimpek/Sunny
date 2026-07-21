class_name WeaponResource
extends Resource
## Definicja broni jako zasób (.tres). Nowa broń = nowy plik w resources/weapons/.

@export var display_name: String = "Weapon"
@export var damage: float = 10.0
@export var fire_interval: float = 0.2
@export var magazine_size: int = 12
@export var reload_time: float = 1.5
@export var projectile_scene: PackedScene
@export var hit_effect_scene: PackedScene
@export var muzzle_flash_scene: PackedScene
@export var fire_sound: AudioStream
@export var reload_sound: AudioStream
