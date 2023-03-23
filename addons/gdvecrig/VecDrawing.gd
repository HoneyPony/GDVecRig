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
	
func edit_point(index: int, offset: Vector2):
	if index < 0 or index >= point_centers.size():
		return
	point_centers[index] += offset
	
func try_starting_editing(plugin: GDVecRig):
	if plugin.point_highlight >= 0:
		plugin.point_edited = true
	
func stop_editing(plugin: GDVecRig):
	plugin.point_edited = false
	
func zoom():
	#print(get_viewport().get_screen_transform())
	#return 1.0
	return get_viewport().get_screen_transform().get_scale().x
	#return get_viewport().get_camera_2d().zoom.x

func edit_input(plugin: GDVecRig, event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		if plugin.point_edited:
			#print(event.relative / zoom())
			edit_point(plugin.point_highlight, event.relative / zoom())
			queue_redraw()
			return true
		else:
			var previous_highlight = plugin.point_highlight
			
			var radius = 5 / zoom()
			plugin.point_highlight = -1
			
			var i = 0
			for center in point_centers:
				if (get_local_mouse_position() - center).length_squared() <= (radius * radius):
					plugin.point_highlight = i
					break
				i += 1
				
			if previous_highlight != plugin.point_highlight:
				queue_redraw()
				
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				try_starting_editing(plugin)
				return true
			else:
				stop_editing(plugin)
				
	return false

func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	
#	if Engine.is_editor_hint():
#		print("e")
#		queue_redraw()
	
func compute(p0, p1, p2, p3, t):
	var zt = 1 - t
	return \
		(zt * zt * zt * p0) + \
		(3 * zt * zt * t * p1) + \
		(3 * zt * t * t * p2) + \
		(t * t * t * p3);
	
func _draw():
	if Engine.is_editor_hint():
		var radius = 5 / zoom()
		var plugin: GDVecRig = get_plugin()
	
		if is_currently_edited():
			var i = 0
			for center in point_centers:
				var color = Color.YELLOW if plugin.point_highlight == i else Color.RED
				draw_circle(center, radius, color)
				i += 1
	
	var computed_points: PackedVector2Array = PackedVector2Array()

	# < - > < - >
	# 0 1 2 3 4 5
	#   0 1 2 3
	# (i + 3) <= length -> gives us two handles + two control points

	var i = 1
	while (i + 3) <= point_centers.size():
		var p0 = point_centers[i]
		var p1 = point_centers[i + 1]
		var p2 = point_centers[i + 2]
		var p3 = point_centers[i + 3]
		
		for j in range(0, 10):
			var t = j / 9.0
			computed_points.push_back(compute(p0, p1, p2, p3, t))
		i += 3
			
	computed_points.push_back(point_centers[1])
			
	draw_colored_polygon(computed_points, fill)
