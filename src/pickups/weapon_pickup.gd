class_name WeaponPickup
extends Pickup
## Broń - dodaje broń do ekwipunku gracza.

@export var weapon: WeaponResource


func _apply(player: Player) -> void:
	if weapon != null:
		player.weapon_manager.add_weapon(weapon)
