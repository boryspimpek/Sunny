class_name Player
extends CharacterBody3D
## Root gracza: fizyka (grawitacja, move_and_slide) i orkiestracja komponentów.
## Logika podzielona na komponenty-dzieci: PlayerMovement, PlayerCamera,
## PlayerAimAssist, PlayerAnimator, WeaponManager, HealthComponent.

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var combat_mode := false

@onready var movement: PlayerMovement = $PlayerMovement
@onready var player_camera: PlayerCamera = $PlayerCamera
@onready var aim_assist: PlayerAimAssist = $PlayerAimAssist
@onready var animator: PlayerAnimator = $PlayerAnimator
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var health: HealthComponent = $HealthComponent
@onready var flashlight: SpotLight3D = $SpringArmPivot/SpringArm3D/Camera3D/SpotLight3D


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	animator.update_roll()

	var combat_mode_held := Input.is_action_pressed("combat_mode")
	if combat_mode != combat_mode_held:
		combat_mode = combat_mode_held
		animator.set_combat_mode(combat_mode)

	player_camera.update(delta, combat_mode)

	if not is_on_floor():
		velocity.y -= gravity * delta

	if combat_mode:
		aim_assist.apply(delta)
	weapon_manager.update(delta, combat_mode and Input.is_action_pressed("fire"))

	movement.update(delta, combat_mode, player_camera.get_yaw(), animator)
	move_and_slide()
	movement.post_physics_update()
	animator.update_locomotion(delta, combat_mode, movement.last_input_dir)

	if Input.is_action_just_pressed("toggle_flashlight"):
		print("toggle_flashlight action triggered")
		flashlight.visible = not flashlight.visible

	if Input.is_action_just_pressed("weapon_1"):
		weapon_manager.switch_weapon(0)
	if Input.is_action_just_pressed("weapon_2"):
		weapon_manager.switch_weapon(1)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		print("Joypad button pressed: index=", event.button_index, " pressed=", event.pressed, " device=", event.device)

func _on_health_changed(current: float, max_health: float) -> void:
	EventBus.player_health_changed.emit(current, max_health)


func _on_died() -> void:
	EventBus.player_died.emit()
