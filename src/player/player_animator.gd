class_name PlayerAnimator
extends Node
## Obsługa animacji gracza: blend space lokomocji, zestawy animacji (pistol/zwykłe),
## animacje akcji (skok, przewrót) oraz kompensacja root motion przewrotu.

@export var animation_reference_speed: float = 5.0
@export var roll_distance: float = 5.0

@onready var body: CharacterBody3D = get_parent()
@onready var animation_tree: AnimationTree = body.get_node("AnimationTree")
@onready var locomotion_blend_space: AnimationNodeBlendSpace2D = animation_tree.tree_root as AnimationNodeBlendSpace2D
@onready var animation_player: AnimationPlayer = body.get_node("AnimationPlayer")
@onready var model: Skeleton3D = body.get_node("Skeleton3D")
@onready var spring_arm_pivot: Node3D = body.get_node("SpringArmPivot")

var action_animation_playing := false
var roll_hips_bone := -1
var roll_root_motion_start := Vector3.ZERO
var roll_direction := Vector3.ZERO
var roll_displacement_pending := Vector3.ZERO
var roll_pivot_initial_position := Vector3.ZERO


func _ready() -> void:
	animation_tree.process_callback = AnimationTree.ANIMATION_PROCESS_MANUAL
	set_combat_mode(false)
	animation_tree.active = true
	roll_hips_bone = model.find_bone("mixamorig_Hips")
	animation_player.animation_finished.connect(_on_animation_finished)


func set_combat_mode(use_pistol: bool) -> void:
	var animation_names: Array[StringName] = []
	if use_pistol:
		animation_names.append_array([
			&"Moves/pistol_idle",
			&"Moves/pistol_strafe_left",
			&"Moves/pistol_strafe_right",
			&"Moves/pistol_run",
			&"Moves/pistol_run_backward"
		])
	else:
		animation_names.append_array([
			&"Moves/idle",
			&"Moves/left_strafe",
			&"Moves/right_strafe",
			&"Moves/running",
			&"Moves/running_backward"
		])
	for index in animation_names.size():
		var animation_node := locomotion_blend_space.get_blend_point_node(index) as AnimationNodeAnimation
		if animation_node != null:
			animation_node.animation = animation_names[index]


func is_rolling() -> bool:
	return action_animation_playing and animation_player.current_animation == &"Moves/roll"


func play_action(animation_name: StringName, action_direction := Vector3.ZERO) -> void:
	if action_animation_playing:
		return

	action_animation_playing = true
	animation_player.speed_scale = 1.0
	animation_tree.active = false
	animation_player.play(animation_name)
	if animation_name == &"Moves/roll" and roll_hips_bone != -1:
		animation_player.advance(0.0)
		roll_direction = action_direction.normalized() if not action_direction.is_zero_approx() else model.global_transform.basis.z.normalized()
		model.global_rotation.y = atan2(roll_direction.x, roll_direction.z)
		roll_pivot_initial_position = spring_arm_pivot.position
		roll_root_motion_start = model.get_bone_global_pose(roll_hips_bone).origin


## Wywoływane na początku _physics_process gracza: kompensacja kamery podczas
## przewrotu oraz zastosowanie przesunięcia po jego zakończeniu.
func update_roll() -> void:
	if is_rolling():
		_update_roll_camera_position()
	if not roll_displacement_pending.is_zero_approx():
		body.move_and_collide(roll_displacement_pending)
		spring_arm_pivot.position = roll_pivot_initial_position
		roll_displacement_pending = Vector3.ZERO


## Wywoływane po move_and_slide: aktualizacja blend space lokomocji.
func update_locomotion(delta: float, combat_mode: bool, input_dir: Vector2) -> void:
	if action_animation_playing:
		return
	var horizontal_speed := Vector2(body.velocity.x, body.velocity.z).length()
	var animation_speed := maxf(horizontal_speed / animation_reference_speed, 1.0)
	var blend_value := Vector2(input_dir.x, -input_dir.y) if combat_mode else Vector2(0.0, 1.0 if not input_dir.is_zero_approx() else 0.0)
	animation_tree.set("parameters/blend_position", blend_value)
	animation_tree.advance(delta * animation_speed)


func _update_roll_camera_position() -> void:
	if roll_hips_bone == -1:
		return

	var current_root_motion: Vector3 = model.get_bone_global_pose(roll_hips_bone).origin
	var root_motion_offset: Vector3 = current_root_motion - roll_root_motion_start
	root_motion_offset.y = 0.0
	spring_arm_pivot.position = roll_pivot_initial_position + model.transform.basis * root_motion_offset


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"Moves/jump" or animation_name == &"Moves/roll":
		if animation_name == &"Moves/roll":
			roll_displacement_pending = roll_direction * roll_distance
		action_animation_playing = false
		animation_tree.active = true
