class_name Pickup
extends Area3D
## Baza dla collectibles (gwiazdki, amunicja, życie, bronie).
## Nadpisz _apply() w klasach pochodnych.

@export var kind: StringName = &"pickup"
@export var collect_sound: AudioStream


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is not Player:
		return
	_apply(body)
	EventBus.pickup_collected.emit(kind)
	if collect_sound != null:
		EventBus.sfx_requested.emit(collect_sound, global_position)
	queue_free()


func _apply(_player: Player) -> void:
	pass
