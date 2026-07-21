class_name StarPickup
extends Pickup
## Gwiazdka - punkty.

@export var points: int = 1


func _apply(_player: Player) -> void:
	GameState.add_score(points)
