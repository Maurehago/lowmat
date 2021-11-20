tool
extends TextureRect

# Farben
var color1: Color = Color(1,1,1)
var color2: Color = Color(1,0,0)
var color3: Color = Color(1,0,0)

# Variablen
var my_half_size: float
var drawData: Array = []

var from_pos: Vector2
var to_pos: Vector2

var old_color_pos: Vector2
var new_color_pos: Vector2
var isSelected: bool = false	# Wenn die Farbe als ausgewählt gezeichnet werden soll



# Signals
signal click_color(colorPos)

# Called when the node enters the scene tree for the first time.
func _ready():
	drawData = []
	pass # Replace with function body.

func _draw():
	var top_color = color2
	if isSelected:
		top_color = color3
		
	for data in drawData:
		# zeichne ein Recheck an der Farb Position
		draw_rect(data, color1, false, 4)
		draw_rect(data, top_color, false, 2)
		# draw_circle(color_mid_pos, my_half_size, Color(1,0,0))
		# draw_circle(color_mid_pos, my_half_size -3, Color(1,1,1))

	# drawData zurücksetzen
	drawData = []

# Funktion für die anzeige der position
func draw_pos(pos: Vector2, _selected: bool) -> void:
	# aktuelle größe lesen, es könnte ja das Panel inzwischen verändert haben
	var my_size: Vector2 = rect_size
	var step_x = my_size.x / 9	# Anzahl der Farben Horizontal
	var step_y = my_size.y / 8	# Anzahl der Farben Vertical
	my_half_size = step_y / 2
	
	# Farbbereich festlegen
	var color_area: Rect2 = Rect2(Vector2(pos.x * step_x -2, pos.y * step_y -2), Vector2(step_x +2, step_y +2))
	var color_mid_pos: Vector2 = Vector2(pos.x * step_x + my_half_size, (pos.y * step_y) + (step_y / 2))

	# in Array schreiben
	drawData.append(color_area)	

	# wenn ausgewählt
	if _selected:
		isSelected = true
	else:
		isSelected = false


func _on_ColorTexture_gui_input(event):
	if event is InputEventMouseButton:
		var my_size: Vector2 = rect_size
		var step_x = my_size.x / 9	# Anzahl der Farben Horizontal
		var step_y = my_size.y / 8	# Anzahl der Farben Vertical
		var pixel_pos = event.position
		var color_pos = Vector2(int(pixel_pos.x / step_x), int(pixel_pos.y / step_y))
		
		# wenn gedrückt
		if !event.pressed:
			# wenn noch kein Startpunkt
			from_pos = pixel_pos
			old_color_pos = color_pos
			emit_signal("click_color", color_pos)

