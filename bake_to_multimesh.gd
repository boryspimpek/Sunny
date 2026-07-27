@tool
extends EditorScript

# Wypakowuje modele 3D z zainstancjonowanych podscen (np. stone_001.tscn)
# i tworzy z nich MultiMeshInstance3D, a same instancje podscen usuwa.
# Kolizje znikaja razem z usunietymi instancjami.

func _run() -> void:
	var scene_root := EditorInterface.get_edited_scene_root()
	if not scene_root:
		push_error("Otworz najpierw scene, ktora chcesz przetworzyc.")
		return

	# Usun ewentualne poprzednie wyniki, jesli skrypt uruchamiasz ponownie.
	var existing := scene_root.get_node_or_null("BakedMultiMeshes")
	if existing:
		existing.queue_free()

	var baked_root := Node3D.new()
	baked_root.name = "BakedMultiMeshes"
	scene_root.add_child(baked_root)
	baked_root.owner = scene_root

	# buckets[key]      = Array[Transform3D]
	# mesh_by_key[key]  = Mesh
	# materials[key]    = { "override": Material, "overlay": Material }
	var buckets: Dictionary = {}
	var mesh_by_key: Dictionary = {}
	var materials: Dictionary = {}
	var to_remove: Array[Node] = []

	# Nie przetwarzaj samego korzenia sceny - tylko jego dzieci.
	for child in scene_root.get_children():
		_gather(child, baked_root, buckets, mesh_by_key, materials, to_remove)

	if buckets.is_empty():
		push_warning("Nie znaleziono MeshInstance3D w zainstancjonowanych podscenach.")
		baked_root.queue_free()
		return

	for key in buckets.keys():
		var transforms: Array = buckets[key]
		var mesh: Mesh = mesh_by_key[key]

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = transforms.size()
		for i in range(transforms.size()):
			mm.set_instance_transform(i, transforms[i])

		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Baked_" + _safe_name(mesh)
		mmi.multimesh = mm

		mmi.material_override = materials[key]["override"]
		mmi.material_overlay = materials[key]["overlay"]

		baked_root.add_child(mmi)
		mmi.owner = scene_root

	for n in to_remove:
		if is_instance_valid(n) and n.get_parent():
			n.get_parent().remove_child(n)
			n.queue_free()

	EditorInterface.mark_scene_as_unsaved()
	print("Przekonwertowano %d instancji podscen na MultiMesh." % to_remove.size())


func _gather(node: Node, baked_root: Node3D, buckets: Dictionary, mesh_by_key: Dictionary, materials: Dictionary, to_remove: Array[Node]) -> void:
	if node != baked_root and node is Node3D and not (node as Node3D).scene_file_path.is_empty():
		_process_instance(node as Node3D, baked_root, buckets, mesh_by_key, materials, to_remove)
		return
	for child in node.get_children():
		_gather(child, baked_root, buckets, mesh_by_key, materials, to_remove)


func _process_instance(inst: Node3D, baked_root: Node3D, buckets: Dictionary, mesh_by_key: Dictionary, materials: Dictionary, to_remove: Array[Node]) -> void:
	var ps := load(inst.scene_file_path) as PackedScene
	if not ps:
		push_warning("Nie mozna zaladowac podsceny: %s" % inst.scene_file_path)
		return

	var temp := ps.instantiate()
	if not temp:
		return

	var meshes: Array[Node] = []
	if temp is MeshInstance3D:
		meshes.append(temp)
	meshes.append_array(temp.find_children("*", "MeshInstance3D", true))

	if meshes.is_empty():
		temp.queue_free()
		return

	var base := baked_root.global_transform.affine_inverse() * inst.global_transform

	for child in meshes:
		var mi := child as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		var mesh: Mesh = mi.mesh
		var key := mesh.resource_path if not mesh.resource_path.is_empty() else str(mesh.get_instance_id())

		if not buckets.has(key):
			buckets[key] = []
			mesh_by_key[key] = mesh
			materials[key] = {
				"override": mi.material_override,
				"overlay": mi.material_overlay
			}

		buckets[key].append(base * mi.transform)

	to_remove.append(inst)
	temp.queue_free()


func _safe_name(mesh: Mesh) -> String:
	var raw := mesh.resource_path.get_file().get_basename() if not mesh.resource_path.is_empty() else str(mesh.get_instance_id())
	var forbidden := ": @ / \\ | * ? \" < > ."
	for c in forbidden:
		raw = raw.replace(c, "_")
	return raw
