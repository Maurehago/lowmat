tool
extends Control

# Objekte
var editor: = EditorPlugin.new()
var editor_interface: EditorInterface = editor.get_editor_interface()
var editor_selection: EditorSelection = editor_interface.get_selection()
var selected_nodes: Array

var check_node: Node = null
var check_mesh: Mesh = null
onready var root_node: Node = get_tree().edited_scene_root
var lowmat_material:SpatialMaterial = ResourceLoader.load("res://lowmat/mat/lowmat.material")

var ui_step_lineEdit: LineEdit
var ui_size: BoxContainer
var ui_meshsize_x: LineEdit
var ui_meshsize_y: LineEdit
var ui_meshsize_z: LineEdit
var ui_color_select: OptionButton
var ui_color: TextureRect
var ui_roughness: Slider
var ui_metallic: CheckBox



# Daten
var lowmat_mesh_data: Dictionary = {}
var lowmat_surface_data: Dictionary = {}
var lowmat_color_data: Dictionary = {}
#lowmat_color_data[posX_posY] = {
#	"color": Vector2(posX, posY),
#	"pos":  pos,
#	"roughness": roughness,
#	"metallic": isMetallic,
#	"vectors": {
#		surface: [j]
#	},
#}


# Einstellunge zu den Farben in der Textur
#	"x": [0.008, 0.117, 0.227, 0.336, 0.445, 0.555, 0.664, 0.773, 0.883],
var color_pos: Dictionary = {
	"color_x_count": 9,
	"color_y_count": 8,
	"x": [0.01, 0.12, 0.23, 0.34, 0.45, 0.56, 0.67, 0.78, 0.89],
	"y": [0.008 + 0.096, 0.133 + 0.096, 0.258 + 0.096, 0.383 + 0.096, 0.508 + 0.096, 0.633 + 0.096, 0.758 + 0.096, 0.883 + 0.096],
	"metall": 0.078,
	"rough": 0.016,
}


# Variablen
var data_index := 0
var change_step: float = 0.16	# Schrittweite bei Größenänderung
var oldColor_id: String 		# ID der ausgewählten Farbe zum Ändern
var oldColor_pos: Vector2
var oldColor_roughness: int = 6
var oldColor_metallic: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	editor_selection.connect("selection_changed", self, "_on_selection_change")
	
	# UI Elemente
	ui_step_lineEdit = get_node("UI/Size/Step/StepLineEdit")
	ui_step_lineEdit.text = str(change_step)
	
	ui_size = get_node("UI/Size")
	ui_meshsize_x = get_node("UI/Size/Mesh/MeshX")
	ui_meshsize_y = get_node("UI/Size/Mesh/MeshY")
	ui_meshsize_z = get_node("UI/Size/Mesh/MeshZ")
	
	ui_color_select = get_node("UI/Color/ColorSelect")
	ui_color_select.clear()
	ui_color_select.add_item("select MeshInstance")
	ui_color_select.connect("color_change", self, "_on_color_change")
	
	ui_color = get_node("UI/Color/ColorTexture")
	ui_color.connect("click_color", self, "_on_click_color")
	
	ui_roughness = get_node("UI/Color/RoughnessSlider")
	ui_roughness.connect("value_changed", self, "_on_change_roughness")
	
	ui_metallic = get_node("UI/Color/Metallic")
	ui_metallic.connect("toggled", self, "_on_change_metallic")
	
	print("ready")
	pass # Replace with function body.


# Selektierte Nodes lesen
func get_selected() -> void:
	selected_nodes = editor_selection.get_selected_nodes()
	if selected_nodes and selected_nodes.size() > 0 and selected_nodes[0] is Spatial:
		check_node = selected_nodes[0]
		if check_node is MeshInstance:
			check_mesh = check_node.mesh
		elif check_node is MultiMeshInstance and check_node.multimesh:
			check_mesh = check_node.multimesh.mesh
		else:
			check_mesh = null
		root_node = check_node.get_tree().edited_scene_root
	else:
		check_node = null
		check_mesh = null


	# test:
	#print("sel. Nodes: ", selected_nodes)
	#print("check_node: ", check_node)

# Fügt eine neue Node als Kind hinzu
# @param newChild: Node
func add_at_root(newChild: Node) -> void:
	root_node.add_child(newChild)
	newChild.set_owner(root_node)


# fügt eine Node auf dem Parent der ausgewählten Node hinzu
func add_at_parent(newChild: Node) -> void:
	if !check_node:
		return
	check_node.get_parent().add_child(newChild)
	newChild.set_owner(root_node)


# erstellt pro Material Surface-Daten
func add_lowmat_surface_data(mesh: Mesh, transform: Transform) -> void:
	if !mesh:
		return
	
	var surface_count = mesh.get_surface_count()
	var array_mesh: ArrayMesh = ArrayMesh.new()
	
	# alle Surfaces durchgehen
	for i in range(surface_count):
		var material = mesh.surface_get_material(i)
		if !material:
			material = lowmat_material
				
		var id = material.get_rid().get_id()
		var name = mesh.resource_name
		var path = mesh.resource_path
		var data: Dictionary = {}
		
		# namen prüfen
		if !name:
			data_index += 1
			name = "LM" + str(data_index)
		
		if id in lowmat_surface_data:
			data = lowmat_surface_data[id]
			data.surface_tool.append_from(mesh, i, transform)
		else:
			# neues SurfaceTool
			var st: SurfaceTool = SurfaceTool.new()
			st.append_from(mesh, i, transform)
			st.set_material(material)
			
			# neue daten
			lowmat_surface_data[id] = data
			data.mesh = mesh
			data.name = name
			data.path = path
			data.surface_tool = st
	


# neue Daten/ Transform für Mesch_Daten hinzufügen
func add_lowmat_mesh_data(mesh: Mesh, transform: Transform) -> void:
	if !mesh:
		return
	
	#var name = mesh.resource_name
	var id = mesh.get_rid().get_id()
	var name = mesh.resource_name
	var path = mesh.resource_path
	var data: Dictionary = {}
	
	# namen prüfen
	if !name:
		data_index += 1
		name = "LM" + str(data_index)
	
	if id in lowmat_mesh_data:
		data = lowmat_mesh_data[id]
		data.t_list.push_back(transform)
	else:
		lowmat_mesh_data[id] = data
		data.mesh = mesh
		data.name = name
		data.path = path
		data.t_list = [transform]


# PrimitiveMesh to ArrayMesh
func primitive_to_arrayMesh(mesh: Mesh) -> ArrayMesh:
	if !mesh:
		return ArrayMesh.new()
	
	# Array Mesh erstellen
	var array_mesh: ArrayMesh = ArrayMesh.new()
	if mesh is ArrayMesh:
		array_mesh = mesh
	else:
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.get_mesh_arrays())
	
	var mesh_data: MeshDataTool = MeshDataTool.new()
	mesh_data.create_from_surface(array_mesh, 0)
	
	# neue uv
	var uv: Vector2 = Vector2(color_pos.x[3], color_pos.y[3])
	
	# alle Punkte durchgehen
	for i in range(mesh_data.get_vertex_count()):
		# neuen UVPunkt setzen
		mesh_data.set_vertex_uv(i, uv)
	
	# neue Oberfläche erstellen
	array_mesh.surface_remove(0)
	mesh_data.commit_to_surface(array_mesh)
	
	# material neu setzen
	array_mesh.surface_set_material(0, lowmat_material)

	if !array_mesh.resource_name:
		array_mesh.resource_name = "primitive"
	
	# neues ArrayMesh zurückgeben
	return array_mesh


# Node auf Meshes prüfen
func check_mesh_data(node:Spatial, to_meshinstance: bool) -> void:
	# wir brauchen die Global Transform
	var transf: Transform = node.global_transform
	var check_child = true

	# auf typ prüfen
	if node is CSGShape:
		# Alle Shape Informationen festsetzen
		node._update_shape()

		# MeschInfo lesen 
		# ist ein Array mit 2 Elemente, 0=Transform, 1=Mesh
		var shapeInfo: Array = node.get_meshes()

		# Transform und Mesch lesen
		var pos: Transform = shapeInfo[0]
		var mesh: ArrayMesh = primitive_to_arrayMesh(shapeInfo[1])

		# muss einen Namen haben
		# mesh.resource_name = "CSG" + mesh.resource_name

		if to_meshinstance:
			add_lowmat_surface_data(mesh, pos)
		else:
			add_lowmat_mesh_data(mesh, pos)
		check_child = false


	if node is MeshInstance:
		# Position verschiben
		var new_transform: Transform = Transform(transf.basis, transf.origin - check_node.global_transform.origin)
		
		# Mesh prüfen
		if node.mesh is PrimitiveMesh:
			var array_mesh: ArrayMesh = primitive_to_arrayMesh(node.mesh)
			if to_meshinstance:
				add_lowmat_surface_data(array_mesh, new_transform)
			else:
				add_lowmat_mesh_data(array_mesh, new_transform)
		else:
			if to_meshinstance:
				add_lowmat_surface_data(node.mesh, new_transform)
			else:
				add_lowmat_mesh_data(node.mesh, new_transform)


	if node is MultiMeshInstance:
		# alle instanzen durchgehen
		for i in range(node.multimesh.instance_count):
			# Transform (local zur node) auslesen
			var instance_transf: Transform = node.multimesh.get_instance_transform(i)
			
			# Position Global ermitteln
			var global_pos: Vector3 = node.to_global(instance_transf.origin)
			
			# von der Globalen Position die Position des Skriptes abziehen
			global_pos = global_pos - check_node.global_transform.origin
			
			# Basis(Drehung/Ausrichtung) von der Node nehmen
			# und die Position Global setzen
			var new_transf = Transform(transf.basis * instance_transf.basis, global_pos)
			
			# Mesh und Position merken
			if to_meshinstance:
				add_lowmat_surface_data(node.multimesh.mesh, new_transf)
			else:
				add_lowmat_mesh_data(node.multimesh.mesh, new_transf)


	# Wenn Kindelemente durchsuchen
	if check_child:	
		# alle Kindelemente durchgehen
		for i in range(node.get_child_count()):
			check_mesh_data(node.get_child(i), to_meshinstance)


func create_multimesh() -> void:
	# Mesh Daten zurücksetzen
	lowmat_mesh_data = {}
	data_index = 0

	# Auswahl prüfen
	get_selected()
	if !check_node:
		return

	# neues Multimesh SammelNode erstellen
	var new_node: Spatial = Spatial.new()
	new_node.transform.origin = check_node.transform.origin
	new_node.name = "LowMat"
	
	# alle Kindnodes prüfen
	check_mesh_data(check_node, false)

	# zur Szene hinzufügen
	add_at_parent(new_node)

	# Alle Meshdaten durchgehen
	for key in lowmat_mesh_data:
		var data = lowmat_mesh_data[key]
		
		var multimesh: MultiMesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = data.mesh
		multimesh.instance_count = data.t_list.size()

		# alle Positionen durchgehen
		for i in range(data.t_list.size()):
			# Position merken
			multimesh.set_instance_transform(i, data.t_list[i])
		
		var multimesh_instance: MultiMeshInstance = MultiMeshInstance.new()
		multimesh_instance.multimesh = multimesh
		multimesh_instance.set_name(data.name)
		
		# zur Parent Node hinzufügen
		new_node.add_child(multimesh_instance)
		multimesh_instance.set_owner(root_node)
	
	# Selection umsetzen
	editor_selection.clear()
	editor_selection.add_node(new_node)

	# Mesh Daten zurücksetzen
	lowmat_mesh_data = {}
	data_index = 0



# erzeugt eine einzelne neue MeshInstance
func create_meshinstance() -> void:
	# Mesch Daten zurücksetzen
	lowmat_surface_data = {}
	data_index = 0
	
	# Auswahl prüfen
	get_selected()
	if !check_node:
		return
	
	# neues Multimesh SammelNode erstellen
	var new_node: Spatial = Spatial.new()
	new_node.transform.origin = check_node.transform.origin
	new_node.name = "LowMat"
	
	# alle Kindnodes prüfen
	check_mesh_data(check_node, true)

	# test:
	#print("mesh_data: ", lowmat_surface_data)

	# zur Szene hinzufügen
	add_at_parent(new_node)

	# Alle Meshdaten durchgehen
	for key in lowmat_surface_data:
		var data = lowmat_surface_data[key]
		
		var mesh_instance: MeshInstance = MeshInstance.new()
		var array_mesh: ArrayMesh = ArrayMesh.new()
		data.surface_tool.commit(array_mesh)
			
		mesh_instance.mesh = array_mesh
		new_node.add_child(mesh_instance)
		mesh_instance.set_owner(root_node)
		
	# Selection umsetzen
	editor_selection.clear()
	editor_selection.add_node(new_node)

	# Mesch Daten zurücksetzen
	lowmat_surface_data = {}
	data_index = 0
	

# Größe anzeigen
func show_size(mesh: Mesh) -> void:
	if !ui_meshsize_x:
		return
		
	if !mesh or !mesh is Mesh:
		ui_meshsize_x.text = "null" 
		ui_meshsize_y.text = "null" 
		ui_meshsize_z.text = "null" 
		return

	var aabb = mesh.get_aabb()
	ui_meshsize_x.text = "x: " + str(aabb.size.x)
	ui_meshsize_y.text = "y: " + str(aabb.size.y)
	ui_meshsize_z.text = "z: " + str(aabb.size.z)


# Mesch größe ändern
func change_size(mesh_instance: MeshInstance, direction: Vector3):
	if !mesh_instance:
		return
	if !mesh_instance.mesh:
		return

	var mesh_data_tool: MeshDataTool = MeshDataTool.new()
	var mesh: Mesh = mesh_instance.mesh
	var array_mesh: ArrayMesh = ArrayMesh.new()

	# Wenn Primitives Mesh
	if mesh is PrimitiveMesh:
		mesh = primitive_to_arrayMesh(mesh)
	
	var aabb: AABB = mesh.get_aabb()
	var midPoint: Vector3 = Vector3(aabb.size.x/ 2, aabb.size.y/ 2, aabb.size.z/ 2)
	midPoint += aabb.position
	var half_step = change_step /2
	var isMiddleX = false
	var isMiddleY = false
	var isMiddleZ = false
	

	# darf nicht zu klein werden
	# test: 
	#print("direction: ", direction)
	#print("aabb.size: ", aabb.size)
	#print("aabb.pos: ", aabb.position)
	if direction.x < 0 and aabb.size.x < change_step + 0.155:
		return
	if direction.y < 0 and aabb.size.y < change_step + 0.155:
		return
	if direction.z < 0 and aabb.size.z < change_step + 0.155:
		return

	if abs(aabb.position.x) >= 0.075:
		isMiddleX = true
	if abs(aabb.position.y) >= 0.075:
		isMiddleY = true
	if abs(aabb.position.z) >= 0.075:
		isMiddleZ = true

	# test:
	#print("midPoint: ", midPoint)
	#print("isMiddleY: ", isMiddleY)

	for i in range(mesh.get_surface_count()):
		mesh_data_tool.create_from_surface(mesh, i)
		for j in range(mesh_data_tool.get_vertex_count()):
			var vertex = mesh_data_tool.get_vertex(j)
			#var marginX = abs(midPoint.x - vertex.x)
			#var marginY = abs(midPoint.y - vertex.y)
			#var marginZ = abs(midPoint.z - vertex.z)
			
			# wenn X größer
			if direction.x > 0: # and marginX > half_step:
				if isMiddleX:
					if vertex.x > midPoint.x:
						vertex.x += half_step
					else:
						vertex.x -= half_step
				elif vertex.x > midPoint.x:
					vertex.x += change_step
				mesh_data_tool.set_vertex(j, vertex)
			
			# wenn X kleiner
			if direction.x < 0: # and marginX > half_step:
				if isMiddleX:
					if vertex.x > midPoint.x:
						vertex.x -= half_step
					else:
						vertex.x += half_step
				elif vertex.x > midPoint.x:
					vertex.x -= change_step
				mesh_data_tool.set_vertex(j, vertex)
			
			# wenn Y größer
			if direction.y > 0: # and marginY > half_step:
				if isMiddleY:
					if vertex.y > midPoint.y:
						vertex.y += half_step
					else:
						vertex.y -= half_step
				elif vertex.y > midPoint.y:
					vertex.y += change_step
				mesh_data_tool.set_vertex(j, vertex)
			
			# wenn Y kleiner
			if direction.y < 0: # and marginY > half_step:
				if isMiddleY:
					if vertex.y > midPoint.y:
						vertex.y -= half_step
					else:
						vertex.y += half_step
				elif vertex.y > midPoint.y:
					vertex.y -= change_step
				mesh_data_tool.set_vertex(j, vertex)
				 
			# wenn Z größer
			if direction.z > 0: # and marginZ > half_step:
				if isMiddleZ:
					if vertex.z > midPoint.z:
						vertex.z += half_step
					else:
						vertex.z -= half_step
				elif vertex.z > midPoint.z:
					vertex.z += change_step
				mesh_data_tool.set_vertex(j, vertex)
			
			# wenn Z kleiner
			if direction.z < 0: # and marginZ > half_step:
				if isMiddleZ:
					if vertex.z > midPoint.z:
						vertex.z -= half_step
					else:
						vertex.z += half_step
				elif vertex.z > midPoint.z:
					vertex.z -= change_step
				mesh_data_tool.set_vertex(j, vertex)
				
		mesh_data_tool.commit_to_surface(array_mesh)
	
	# neu zuweisen
	mesh_instance.mesh = array_mesh
	show_size(array_mesh)
	

# Farben Lesen
func check_color(mesh) -> void:
	if !mesh or !mesh is Mesh:
		return
	
	var mesh_data_tool: MeshDataTool = MeshDataTool.new()
	lowmat_color_data = {}

	# Wenn Primitives Mesh
	if mesh is PrimitiveMesh:
		mesh = primitive_to_arrayMesh(mesh)

	# Abstufungen
	#var step_x: float = int(100 / 9) / 100.00
	#var step_y: float = int(100 / 8) / 100.00
	#print("step_x: ", step_x)
	

	# alle surfaces durchgehen
	for i in range(mesh.get_surface_count()):
		var old_mat: Material = mesh.surface_get_material(i) 
		
		# nur wenn Material ein Lowmaterial ist
		if old_mat == lowmat_material:
			mesh_data_tool.create_from_surface(mesh, i)
			for j in range(mesh_data_tool.get_vertex_count()):
				var uv = mesh_data_tool.get_vertex_uv(j)
				
				
				# Position von 0,0 bis 9,8 ermitteln - 9 Farben Horizontal, 8 Farben vertikal
				var colorP_x = uv.x * color_pos.color_x_count #lerp(0, 9, uv.x)
				var colorP_y = uv.y * color_pos.color_y_count #lerp(0, 8, uv.y)
				var pos_x: int = min(int(colorP_x), 8)
				var pos_y: int = min(int(colorP_y), 7)
				var isMetallic: bool = (colorP_x - pos_x) > 0.5
				var roughness:int  = (color_pos.y[pos_y] - uv.y) / color_pos.rough

				# test:
				if j == 1:
					if ui_metallic:
						ui_metallic.pressed = isMetallic
					if ui_roughness:
						ui_roughness.value = roughness
					#print("uv: ", uv)
					#print("colorP_x: ", colorP_x)
					#print("pos_x: ", pos_x)
					#print("isMetallic: ", isMetallic)
					#print("roughness: ", roughness)

				# Punkt bestimmen
				var pos:Vector2 = Vector2(color_pos.x[pos_x], color_pos.y[pos_y])
				if isMetallic:
					pos.x += color_pos.metall
				pos.y -= roughness * color_pos.rough

				# todo: Farben merken
				var index = str(pos_x) + "_" + str(pos_y)
				if index in lowmat_color_data:
					lowmat_color_data[index].vectors[i].append(j)
				else:
					lowmat_color_data[index] = {
						"color": Vector2(pos_x, pos_y),
						"pos":  pos,
						"roughness": roughness,
						"metallic": isMetallic,
						"vectors": {
							i: [j]
						},
					}
			
	# test:
	#print("lowmat_color_data: ", lowmat_color_data)
	
	# alle Farben in der Auswahl anzeigen
	if ui_color and ui_color_select:
		ui_color_select.clear()
		var isFirstColor:bool = true
		for key in lowmat_color_data:
			# Farbe Anzeige aufrufen
			var color_object: Dictionary = lowmat_color_data[key]
			
			# in Liste einfügen
			ui_color_select.add_item(key)
			
			# wenn erstes objekt
			if isFirstColor:
				isFirstColor = false
				# farbe fählen
				_on_color_change(key)
				
				#ui_color.draw_pos(color_object.color, false)
				
				# Zeichen
				#ui_color.update()

# neue Farbe setzen
func set_color_uv(newColorPos: Vector2, _roughness: int, _metallic: bool):
	# prüfen
	if !oldColor_id:
		return
	if !check_node:
		return
	if !check_mesh:
		return
	
	# neue UV Position
	#print("newColorPos: ", newColorPos)
	#print("_roughness: ", _roughness)
	#print("_metallic: ", _metallic)
	var newUV: Vector2 = Vector2(color_pos.x[newColorPos.x], color_pos.y[newColorPos.y])
	
	# Roughness
	newUV.y -= color_pos.rough * _roughness
	
	# Metallic
	if _metallic:
		newUV.x += color_pos.metall
	
	#print("newUV: ", newUV)

	# Color Data
	var colorData = lowmat_color_data[oldColor_id]
	
	# Wenn Primitives Mesh
	if check_mesh is PrimitiveMesh:
		check_mesh = primitive_to_arrayMesh(check_mesh)

	# brauche neue Arraymesh
	var new_mesh: ArrayMesh = ArrayMesh.new()
	
	# Alle Surfaces durchgehen
	for i in range(check_mesh.get_surface_count()):
		# neues MeshDataTool
		var mesh_data: MeshDataTool = MeshDataTool.new()
		mesh_data.create_from_surface(check_mesh, i)
	
		#wenn in den Farbdaten vorhanden
		if i in colorData.vectors:
			# alle Vectoren durchgehen
			for j in colorData.vectors[i]:
				mesh_data.set_vertex_uv(j, newUV)
		
		# neues Surface im Arraymesh erstellen
		mesh_data.commit_to_surface(new_mesh)

	# neue Werte merken
	oldColor_pos = newColorPos
	oldColor_metallic = _metallic
	oldColor_roughness = _roughness
	colorData.color = newColorPos
	colorData.roughness = _roughness
	colorData.metallic = _metallic
	
	# neue ID
	var new_colorID: String = str(newColorPos.x) + "_" + str(newColorPos.y)
	lowmat_color_data[new_colorID] = colorData
	if ui_color_select:
		ui_color_select.set_item_text(ui_color_select.selected, new_colorID)
	
	# alte ID löschen
	# nur wenn nicht die selbe ID
	if oldColor_id != new_colorID:
		lowmat_color_data.erase(oldColor_id)
		oldColor_id = new_colorID
	
	# Mesh in der Instance ändern
	if check_node is MeshInstance:
		check_node.mesh = new_mesh
	elif check_node is MultiMeshInstance:
		check_node.multimesh.mesh = new_mesh


	
# Wenn sich die Selection ändert
func _on_selection_change():
	oldColor_id = ""
	get_selected()

	if check_mesh:
		show_size(check_mesh)
		check_color(check_mesh)
	else:
		if ui_meshsize_x:
			ui_meshsize_x.text = "null" 
			ui_meshsize_y.text = "null" 
			ui_meshsize_z.text = "null" 
		
		# farben zurücksetzen
		if ui_color:
			ui_color.update()
	pass


# wenn Button zum Erstellen von einer Meshinstance gedrückt wird
func _on_JoinMeshButton_pressed():
	# test:
	#print("create_meshinstance")
	create_meshinstance()


# wenn Button zum Erstellen von einer MultiMeshinstance gedrückt wird
func _on_JoinMultimeshButton_pressed():
	create_multimesh()

# wenn sich Ste Änderungs-Stufe ändert
func _on_StepSlider_value_changed(value):
	# ÄnderzngsStufen ändern
	change_step = value
	ui_step_lineEdit.text = str(value)


func _on_SizeXButton2_pressed():
	get_selected()
	change_size(check_node, Vector3(1,0,0))


func _on_SizeXButton_pressed():
	get_selected()
	change_size(check_node, Vector3(-1,0,0))
	pass # Replace with function body.


func _on_SizeYButton_pressed():
	get_selected()
	change_size(check_node, Vector3(0,-1,0))
	pass # Replace with function body.



func _on_SizeYButton2_pressed():
	get_selected()
	change_size(check_node, Vector3(0,1,0))
	pass # Replace with function body.


func _on_SizeZButton_pressed():
	get_selected()
	change_size(check_node, Vector3(0,0,-1))
	pass # Replace with function body.


func _on_SizeZButton2_pressed():
	get_selected()
	change_size(check_node, Vector3(0,0,1))
	pass # Replace with function body.

# Wenn auf die Farbtabelle geklickt wird
func _on_click_color(colorPos: Vector2):
	# wenn bereits eine Farbe gesetzt
	if oldColor_id:
		# neue Farbe setzen
		set_color_uv(colorPos, oldColor_roughness, oldColor_metallic)
		if ui_color:
			ui_color.draw_pos(colorPos, true)
			ui_color.update()


# Wenn eine ander Farbe zum Ändern gewählt
func _on_color_change(colorID: String):
	#print("lowmat_color_data: ", lowmat_color_data)
	get_selected()
	
	# nur wenn vorhanden
	if colorID in lowmat_color_data:
		# Farbe merken
		oldColor_id = colorID
		oldColor_pos = lowmat_color_data[colorID].color
		oldColor_roughness = lowmat_color_data[colorID].roughness
		oldColor_metallic = lowmat_color_data[colorID].metallic
		
		# Roughness und Metallic anzeigen
		if ui_metallic:
			ui_metallic.pressed = oldColor_metallic
		if ui_roughness:
			ui_roughness.value = oldColor_roughness
		
		# auf der Farbtabelle Markierung setzen
		if ui_color:
			ui_color.draw_pos(oldColor_pos, true)
			ui_color.update()


# Wenn sich die Metallic Option ändert
func _on_change_metallic(newValue: bool):
	# Metallic ändern
	set_color_uv(oldColor_pos, oldColor_roughness, newValue)
	pass

# Wenn sich die Roughness ändert
func _on_change_roughness(newValue: float):
	# rough ändern
	set_color_uv(oldColor_pos, int(newValue), oldColor_metallic)
	
