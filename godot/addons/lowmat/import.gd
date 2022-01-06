tool # Needed so it runs in the editor.
extends EditorScenePostImport

# Materialien
var lowmat: Material = ResourceLoader.load("res://lowmat/mat/lowmat.material")
var lowmat_em: Material = ResourceLoader.load("res://lowmat/mat/lowmat_em.material")
var lowmat_tran: Material = ResourceLoader.load("res://lowmat/mat/lowmat_tran.material")

# Speicherpfad
var dir: Directory = Directory.new()
var source_path: String
var save_path: String

func check_mesh(node: Spatial) -> void:
	if !node is Spatial:
		return
	
	# nur wenn MeshInstance mit Mesh
	if node is MeshInstance and node.mesh:
		var mesh: Mesh = node.mesh
		var instanceName = node.name
		
		# alle Surfaces durchgehen
		for i in range(mesh.get_surface_count()):
			# Material prüfen
			var matName = mesh.surface_get_material(i).resource_name
			if matName == "lowmat":
				mesh.surface_set_material(i, lowmat)
			elif matName == "lowmat_em":
				mesh.surface_set_material(i, lowmat_em)
			elif matName == "lowmat_tran":
				mesh.surface_set_material(i, lowmat_tran)
	
		# Mesh als Resource speichern
		var err = ResourceSaver.save(save_path + "/" + instanceName + ".mesh", mesh)
	
	pass

# Alle Nodes prüfen
func check_node(node):
	if node != null:
		check_mesh(node)
		for child in node.get_children():
			check_node(child)


# wird nach dem Import ausgeführt
func post_import(scene: Object):
	# material prüfen
	if !lowmat or !lowmat_em or !lowmat_tran:
		return
	
	# Namen lesen
	var subName: String = scene.name
	var path = get_source_folder()
	if !subName:
		return

	# ordner prüfen
	save_path = path + "/" + subName
	if !dir.dir_exists(save_path):
		dir.make_dir(save_path)
	
	# Szene prüfen
	check_node(scene)
	
	# Do your stuff here.
	return scene # remember to return the imported scene
