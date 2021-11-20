tool
extends EditorPlugin

var dock

var interface: EditorInterface = get_editor_interface()
var selection = interface.get_selection()

func _ready():
	# Interface für Auswahl der Nodes hinzufügen
	#interface = get_editor_interface()
	#dock.editor_interface = interface
	#dock.editor_selection = interface.get_selection()
	pass
	
func _enter_tree():
	dock = preload("res://addons/lowmat/lowmat.tscn").instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UR, dock)


	
func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()

	
#func has_main_screen():
#	return true
