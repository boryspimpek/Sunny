class_name HealthPickup
extends Pickup
## Życie - leczy gracza.

@export var amount: float = 25.0


func _apply(player: Player) -> void:
	player.health.heal(amount)
