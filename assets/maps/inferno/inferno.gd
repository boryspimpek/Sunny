extends Node3D


@export var generate_collision: bool = true


func _ready() -> void:
	if not generate_collision:
		return

	for mesh_instance: MeshInstance3D in find_children("*", "MeshInstance3D", true):
		if mesh_instance.mesh == null:
			print("MeshInstance3D with null mesh: ", mesh_instance.name, " (", mesh_instance.get_path(), ")")
			continue
		var shape: ConcavePolygonShape3D = mesh_instance.mesh.create_trimesh_shape()
		if shape == null or shape.get_faces().size() == 0:
			continue

		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		body.name = mesh_instance.name + "_StaticBody"
		collision.shape = shape
		body.add_child(collision)
		mesh_instance.add_sibling(body)
		body.global_transform = mesh_instance.global_transform
