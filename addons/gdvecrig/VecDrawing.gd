@tool
extends Node2D
class_name VecDrawing

@export var fill: Color = Color.WHITE

@export var point_centers: PackedVector2Array

func get_plugin() -> GDVecRig:
	return Engine.get_singleton("GDVecRig")

func is_currently_edited():
	var vr: GDVecRig = Engine.get_singleton("GDVecRig")
	return vr.current_vecdrawing == self

func edit_input(plugin: GDVecRig, event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		var radius = 3
		plugin.point_highlight = -1
		
		var i = 0
		for center in point_centers:
			if (get_local_mouse_position() - center).length_squared() <= (radius * radius):
				plugin.point_highlight = i
				break
			i += 1
	return false

func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	queue_redraw()
#	if Engine.is_editor_hint():
#		print("e")
#		queue_redraw()
	
func _draw():
	if Engine.is_editor_hint():
		var plugin: GDVecRig = get_plugin()
	
		if is_currently_edited():
			var i = 0
			for center in point_centers:
				var color = Color.YELLOW if plugin.point_highlight == i else Color.RED
				draw_circle(center, 2, color)
				i += 1
	
	var computed_points: PackedVector2Array = PackedVector2Array()
	
	
#	for i in range(0, 20):
#		computed_points.push_back(Vector2(i * 10.0, sqrt(i * t) * 10.0))
#
#	draw_colored_polygon(computed_points, fill)
