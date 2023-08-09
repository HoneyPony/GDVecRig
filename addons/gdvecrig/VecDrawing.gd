@tool
extends Node2D
class_name VecDrawing

@export var cyclic: bool = false

@export var fill: Color = Color.WHITE
@export_range(1, 256) var steps: int = 10

@export var show_rest: bool = true
@export var always_show_points: bool = false

var waypoints = [VecWaypoint]
var strokes = [VecStroke]

@export_node_path("Skeleton2D") var skeleton
@onready var skeleton_node = get_skeleton_from_tree()

# Gets the associated Skeleton2D from the 'skeleton' NodePath variable, OR
# returns null if the path is either null or invalid. This is because
# get_node_or_null unfortunately does not like it when the NodePath is null.
func get_skeleton_from_tree() -> Skeleton2D:
	return null if skeleton == null else get_node_or_null(skeleton)

func collect_children():
	waypoints.clear()
	strokes.clear()
	for child in get_children():
		if child is VecWaypoint:
			waypoints.push_back(child)
		if child is VecStroke:
			strokes.push_back(child)
	

func get_waypoint(index):
	return waypoints[index]
	
func get_waypoint_place(index):
	if show_rest:
		return waypoints[index].value
	else:
		return waypoints[index].computed_value
	
func waypoint_count():
	return waypoints.size()

func get_plugin() -> GDVecRig:
	return Engine.get_singleton("GDVecRig")

func is_currently_edited():
	var vr: GDVecRig = Engine.get_singleton("GDVecRig")
	return vr.current_vecdrawing == self
	
func edit_point(index: int, offset: Vector2):
	if index < 0 or index >= waypoint_count():
		return
	get_waypoint(index).value += offset
	
func try_starting_editing(plugin: GDVecRig):
	if plugin.point_highlight >= 0:
		plugin.point_edited = true
		if not plugin.point_selection.has(plugin.point_highlight):
			# Clear the selection we we're selecitng a new point
			plugin.point_selection.clear()
			add_to_select(plugin, plugin.point_highlight)
		return true
	
	return false
	
func stop_editing(plugin: GDVecRig):
	plugin.point_edited = false
	
func add_to_select(plugin: GDVecRig, point: int):
	if not plugin.point_selection.has(point):
		plugin.point_selection.push_back(point)
	
func add_to_select_from_target(plugin: GDVecRig, target: Vector2):
	var radius = 5 / zoom()
	
	for i in range(0, waypoint_count()):
		var center = get_waypoint_place(i)
		if (target - center).length_squared() <= (radius * radius):
			add_to_select(plugin, i)
			
func select_in_lasso(plugin: GDVecRig):
	for i in range(0, waypoint_count()):
		var p = get_waypoint_place(i)
		if Geometry2D.is_point_in_polygon(p, plugin.lasso_points):
			add_to_select(plugin, i)
	
func is_selected(index):
	return get_plugin().point_selection.has(index)
	
func zoom():
	return get_viewport().get_screen_transform().get_scale().x
	
func paint_from_target(plugin: GDVecRig, target: Vector2):
	var radius = 10 / zoom()
	
	for i in range(0, waypoint_count()):
		var center = get_waypoint_place(i)
		if (target - center).length_squared() <= (radius * radius):
			get_waypoint(i).edit_weight(plugin.weight_painting_bone, plugin)

func handle_editing_mouse_motion(plugin: GDVecRig, event: InputEventMouseMotion):
	if plugin.lasso_started:
		plugin.lasso_points.push_back(get_local_mouse_position())
	elif plugin.point_edited:
		for point in plugin.point_selection:
		#print(event.relative / zoom())
			edit_point(point, event.relative / zoom())
		#queue_redraw()
		return true
	else:
		var previous_highlight = plugin.point_highlight
		
		var radius = 7 / zoom()
		plugin.point_highlight = -1
		
		for i in range(0, waypoint_count()):
			var center = get_waypoint_place(i)
			if (get_local_mouse_position() - center).length_squared() <= (radius * radius):
				plugin.point_highlight = i
				break
			
		if previous_highlight != plugin.point_highlight:
			pass
	return false

func handle_editing_mouse_button(plugin: GDVecRig, event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if plugin.add_end_point():
				for i in range(0, 3):
					var waypoint = VecWaypoint.new()
					waypoint.value = get_local_mouse_position()
					add_child(waypoint)
					waypoint.owner = owner
				return true
			
			if event.get_modifiers_mask() & KEY_MASK_SHIFT:
				var selected = add_to_select_from_target(plugin, get_local_mouse_position())
				if not selected:
					plugin.lasso_started = true
				return true
			else:
				var editing = try_starting_editing(plugin)
				if not editing:
					plugin.lasso_started = true
					
				return true
		else:
			if plugin.lasso_started:
				if event.get_modifiers_mask() & KEY_MASK_SHIFT:
					pass # Don't throw out old points
				else:
					# CLear selection
					plugin.point_selection.clear()
				select_in_lasso(plugin)
				plugin.lasso_started = false
				plugin.lasso_points.clear()
			else:
				stop_editing(plugin)
	return false
	
func handle_weight_paint_mouse_motion(plugin: GDVecRig, event: InputEventMouseMotion):
	if plugin.weight_painting_now:
		paint_from_target(plugin, get_local_mouse_position())
		return true
	return false
	
func handle_weight_paint_mouse_button(plugin: GDVecRig, event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			plugin.weight_painting_now = true
		else:
			plugin.weight_painting_now = false
		return true
	return false

func edit_input(plugin: GDVecRig, event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		if plugin.in_mode_weightpaint():
			return handle_weight_paint_mouse_motion(plugin, event)
		else:
			return handle_editing_mouse_motion(plugin, event)
				
	if event is InputEventMouseButton:
		if plugin.in_mode_weightpaint():
			return handle_weight_paint_mouse_button(plugin, event)
		else:
			return handle_editing_mouse_button(plugin, event)
		
				
	return false

func _ready():
	collect_children()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		# Always collect waypoints while being edited.
		collect_children()
	queue_redraw()
	
	# Cache used to speed up bone computations
	var transform_cache = {}
	for i in range(0, waypoint_count()):
		var s = skeleton_node
		if Engine.is_editor_hint() and skeleton != null:
			s = get_node_or_null(skeleton)
		get_waypoint(i).compute_value(s, transform_cache)
	
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
	
func draw_editor_handle(radius, left, mid, right, ls, ms, rs):
	draw_line(left, mid, Color.WHITE)
	draw_line(mid, right, Color.WHITE)
	
	draw_circle(left, radius * 0.9, Color.BLUE if ls else Color.WHITE)
	draw_circle(mid, radius, Color.BLUE if ms else Color.GRAY)
	draw_circle(right, radius * 0.9, Color.BLUE if rs else Color.WHITE)
	
func draw_editor_weights(radius, left, mid, right, ls, ms, rs):
	draw_line(left, mid, Color.WHITE)
	draw_line(mid, right, Color.WHITE)
	
	draw_circle(left, radius * 0.9, Color(ls, ls, ls))
	draw_circle(mid, radius, Color(ms, ms, ms))
	draw_circle(right, radius * 0.9, Color(rs, rs, rs))
	
func draw_line_width(points: PackedVector2Array, width: PackedVector2Array):
	pass
	
func draw_lasso(plugin: GDVecRig):
	var radius = 1.0 / zoom()
	if plugin.lasso_points.size() >= 2:
		draw_polyline(plugin.lasso_points, Color.WHITE, radius)
		draw_line(plugin.lasso_points[plugin.lasso_points.size() - 1], plugin.lasso_points[0], Color.GRAY, radius)
	
func _draw():
	var computed_points: PackedVector2Array = PackedVector2Array()

	# < - > < - >
	# 0 1 2 3 4 5
	#   0 1 2 3
	# (i + 3) <= length -> gives us two handles + two control points

	var i = 1
	while (i + 3) <= waypoint_count():
		var p0 = get_waypoint_place(i)
		var p1 = get_waypoint_place(i + 1)
		var p2 = get_waypoint_place(i + 2)
		var p3 = get_waypoint_place(i + 3)
		
		for j in range(0, steps):
			var t = j / float(steps - 1)
			computed_points.push_back(compute(p0, p1, p2, p3, t))
		i += 3
		
	if cyclic:
		if waypoint_count() >= 6:
			var end = waypoint_count() - 2
			var p0 = get_waypoint_place(end + 0)
			var p1 = get_waypoint_place(end + 1)
			var p2 = get_waypoint_place(0)
			var p3 = get_waypoint_place(1)
			for j in range(0, steps):
				var t = j / float(steps - 1)
				computed_points.push_back(compute(p0, p1, p2, p3, t))
		
	if computed_points.size() >= 3:	
		draw_colored_polygon(computed_points, fill)
	for stroke in strokes:
		stroke.points = computed_points
	
	if Engine.is_editor_hint():
		var radius = 5 / zoom()
		var plugin: GDVecRig = get_plugin()
	
		if is_currently_edited() or always_show_points:
			if plugin.in_mode_weightpaint(): # "In weight painting mode"
				var bone = 0
				i = 0
				while (i + 2) <= waypoint_count():
					var p0 = get_waypoint_place(i)
					var p0s = get_waypoint(i).get_weight(plugin.weight_painting_bone)
					var p1 = get_waypoint_place(i + 1)
					var p1s = get_waypoint(i + 1).get_weight(plugin.weight_painting_bone)
					var p2 = get_waypoint_place(i + 2)
					var p2s = get_waypoint(i + 2).get_weight(plugin.weight_painting_bone)
					draw_editor_weights(radius, p0, p1, p2, p0s, p1s, p2s)
					
					i += 3
			else:
				i = 0
				while (i + 2) <= waypoint_count():
					var p0 = get_waypoint_place(i)
					var p0s = is_selected(i)
					var p1 = get_waypoint_place(i + 1)
					var p1s = is_selected(i + 1)
					var p2 = get_waypoint_place(i + 2)
					var p2s = is_selected(i + 2)
					draw_editor_handle(radius, p0, p1, p2, p0s, p1s, p2s)
					
					i += 3
		
		if plugin.lasso_started:
			#print("Yo ", plugin.lasso_points.size())
			draw_lasso(plugin)
						
		
