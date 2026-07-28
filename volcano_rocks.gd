extends Node3D


func _ready() -> void:
	# Znajdź wszystkie MeshInstance3D w poddrzewie VolcanoRocks (też zagnieżdżone)
	var rocks := find_children("*", "MeshInstance3D", true)
	for rock in rocks:
		rock.set_instance_shader_parameter("phase_offset", randf() * TAU)
