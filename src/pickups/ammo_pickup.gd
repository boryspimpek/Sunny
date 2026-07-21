class_name AmmoPickup
extends Pickup
## Amunicja - uzupełnia magazynek aktualnej broni.

@export var amount: int = 6


func _apply(player: Player) -> void:
	player.weapon_manager.add_ammo(amount)
