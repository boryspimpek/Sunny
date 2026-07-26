class_name AttackBehavior
extends Node
## Baza dla zachowań ataku wroga. Podpinaj konkretny wariant jako dziecko
## sceny wroga - Enemy wykryje go automatycznie. Baza = brak ataku.


## Wywoływane przez Enemy w każdej klatce _physics_process.
func try_attack(_enemy: Enemy, _target: Node3D, _delta: float) -> void:
	pass
