tool
extends OptionButton

signal color_change(colorID)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Bei Item auswahl
func _on_ColorSelect_item_selected(index):
	var colorID = get_item_text(index)
	emit_signal("color_change", colorID)
