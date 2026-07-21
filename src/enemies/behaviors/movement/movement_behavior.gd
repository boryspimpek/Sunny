class_name MovementBehavior
extends Node
## Baza dla zachowań ruchu wroga. Podpinaj konkretny wariant jako dziecko
## sceny wroga - Enemy wykryje go automatycznie.


## Zwraca pożądaną prędkość poziomą (XZ). Komponent Y jest ignorowany.
func get_movement(_enemy: Enemy, _target: Node3D, _delta: float) -> Vector3:
	return Vector3.ZERO
