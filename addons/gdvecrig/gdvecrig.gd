@tool
extends EditorPlugin
class_name GDVecRig

var current_vecdrawing = null
var current_vecdrawing_is_selected_in_tree = false

var point_highlight = 0
var point_selection = []
var point_edited = false

var lasso_started = false
var lasso_points: PackedVector2Array = PackedVector2Array()

var weight_painting_now = false
var weight_painting_bone: int = 0

func in_mode_drawing():
	return dock_tabs.get_current_tab_control() == tab_drawing

func in_mode_weightpaint():
	return dock_tabs.get_current_tab_control() == tab_weightpaint
	
func add_end_point():
	return drawing_tool_new.button_pressed
	
# Determines whether we can start a lasso.
# 
# We're only allowed to start a lasso if the Editor's selection
# consists ONLY of the current_vecdrawing... I guess.
func may_start_lasso():
	var select = get_editor_interface().get_selection()
	var select_nodes = select.get_selected_nodes()
	if select_nodes.size() > 1 or select_nodes.is_empty():
		return false
	return select_nodes[0] == current_vecdrawing
	
# Vector graphics editing is a little special in that, we want to be able to
# continuously edit our current_vecdrawing, even if it's not selected, IF
# the Vector Editing tab is open.
#
# As such, this function will just return whether we *want* to edit the object.
# This can be used for things like, determining whether the object should draw,
# or the return value from _handles().
func wants_to_edit_the_object():
	# We ALWAYS want to edit if the VecDrawing is directly selected.
	if current_vecdrawing_is_selected_in_tree:
		return true
	
	if current_vecdrawing != null:
		return dock.get_parent().get_current_tab_control() == dock
		
	return false

func is_in_toggle_constraint():
	return drawing_tool_toggle_constraint.button_pressed
func is_in_delete():
	return drawing_tool_delete.button_pressed

func _on_bone_list_selected(index: int):
	weight_painting_bone = index

func _handles(node):
	# We will ALWAYS handle a VecDrawing if it is currently selected.
	if node is VecDrawing:
		return true
		
	# If we have a current_vecdrawing, unfortunately, Godot doesn't re-poll
	# our _handles method when switching the tabs. So instead, we have to
	# just always return true, and then do nothing in _forward_gui_input
	# when the tab isn't selected.
	if current_vecdrawing != null:
		return true
		
	return false
	
func load_bones(drawing: VecDrawing):
	bone_list.clear()
	
	var skeleton: Skeleton2D = drawing.get_skeleton_from_tree()
	if skeleton == null:
		return
	
	for i in range(0, skeleton.get_bone_count()):
		var bone = skeleton.get_bone(i)
		
		bone_list.add_item(bone.name)
	
func _edit(object):
	if object is VecDrawing:
		if object != current_vecdrawing:
			point_selection = []
		
		current_vecdrawing = object
		print("Select vecdrawing: ", current_vecdrawing)
		current_vecdrawing_is_selected_in_tree = true
		cur_drawing_display.text = current_vecdrawing.name
		point_highlight = 0
		
		point_edited = false
		lasso_started = false
		lasso_points.clear()
		
		load_bones(object)
	else:
		current_vecdrawing_is_selected_in_tree = false
		
		# If we're editing a Bone2D, and it's one of the bones in the current
		# armature, we want to select it in the weight painting list.
		if object is Bone2D:
			var bone: Bone2D = object
			if current_vecdrawing != null:
				var skeleton: Skeleton2D = current_vecdrawing.get_skeleton_from_tree()
				
				# Try to find the bone in the skeleton
				for i in range(0, skeleton.get_bone_count()):
					var test = skeleton.get_bone(i)
					if test == bone:
						# If we found the bone, select it in the weight painting
						# list.
						bone_list.select(i, true)
						# The signal will not be fired by the list, do it ourselves.
						_on_bone_list_selected(i)
						break
						
		#current_vecdrawing = null
	return
	
# These commented-out functions are used to find where the 2d viewports are
# in the interface, so that we can manually implmeent the _input functions.
#func the_search(node, index: int) -> bool:
#	var child = node.get_child(index)
#	if child is SubViewport:
#		print(index, " <- ")
#		return true
#
#	for i in child.get_child_count():
#		if the_search(child, i):
#			print(index, " <- ")
#			return true
#
#	return false
#
#func search_for_viewports():
#	var m = get_editor_interface().get_editor_main_screen()
#
#	print("---start search---")
#	for x in m.get_child_count():
#		print("child--")
#		the_search(m, x)
#		print("end--")
#	print("---end search---")
	
# Reference:
# https://cookiebadger.itch.io/assetplacer/devlog/537327/godot-plugins-what-nobody-tells-you
func get_2d_viewports():
	var main_screen = get_editor_interface().get_editor_main_screen()
	var viewports_place = main_screen \
		.get_child(0) \
		.get_child(1) \
		.get_child(0) \
		.get_child(0).get_children()
	var viewports = []
	for v in viewports_place:
		viewports.append(v.get_child(0).get_child(0) as SubViewport)
	return viewports
	
func get_focused_2d_viewport():
	var viewports = get_2d_viewports()
	for sub_view in viewports:
		if is_editor_viewport_focused(sub_view):
			return sub_view
	return null
	
func is_editor_viewport_focused(viewport: Viewport) -> bool:
	var editor_viewport: Control = viewport.get_parent().get_parent()
	var viewport_control = editor_viewport.get_child(1) as Control
	return editor_viewport.visible and (viewport_control != null and viewport_control.has_focus())
		
func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if not wants_to_edit_the_object():
		return false

	if is_instance_valid(current_vecdrawing):
		return current_vecdrawing.edit_input(self, event)
	return false


# The following code is meant to workaround the no-calls-to _forward_canvas_gui_input
# problem, but it doesn't really work.
# - _unhandled_input does not seem to ever be called.
# - _input is called, but there doesn't seem to be a good way to avoid eating
#   the input when we're not actually supposed to eat it.

#func _my_forward_input(event: InputEvent) -> bool:
#	if not wants_to_edit_the_object():
#		return false
#
#	if is_instance_valid(current_vecdrawing):
#		return current_vecdrawing.edit_input(self, event)
#	return false
	
#func _input(event: InputEvent):
#	if not Engine.is_editor_hint():
#		return
#
#	var viewport = get_focused_2d_viewport()
#	if viewport != null:
#		var input_handled = _my_forward_input(event)
#		#if input_handled:
			#viewport.set_input_as_handled()
	
func _make_visible(visible):
	pass

var dock: Control

var dock_tabs: TabContainer
var cur_drawing_display: Label

var tab_drawing: Control
var tab_weightpaint: Control

# --- DRAWING TOOLS ---
var drawing_tool_edit: Button
var drawing_tool_new: Button
var drawing_tool_knife: Button
var drawing_tool_toggle_constraint: Button
var drawing_tool_delete: Button
var drawing_tool_group: ButtonGroup

# --- WEIGHT PAINT TOOLS ---
var weight_paint_tool_add: Button
var weight_paint_tool_sub: Button
var weight_paint_tool_mix: Button
var weight_paint_tool_group: ButtonGroup

# --- WEIGHT PAINT OPTIONS ---
var bone_list: ItemList
var weight_paint_value_box: SpinBox
var weight_paint_strength_box: SpinBox

func paint_weight(input: float) -> float:
	# Compute output based on selected painting style
	var output = input + weight_paint_value_box.value
	if weight_paint_tool_group.get_pressed_button() == weight_paint_tool_sub:
		output = input - weight_paint_value_box.value
	elif weight_paint_tool_group.get_pressed_button() == weight_paint_tool_mix:
		# We mix in the lerp call below
		output = weight_paint_value_box.value
	
	# Blend output
	return lerp(input, output, weight_paint_strength_box.value)

func setup_button(source_node: Node, path, group: ButtonGroup) -> Button:
	var node: Button = source_node.get_node(path)
	node.button_group = group
	return node
	
func _process(delta):
	# This is a hack so that we always have something selected,
	# so that _forward_canvas_gui_input will work.
	if get_editor_interface().get_selection().get_selected_nodes().is_empty():
		if dock.get_parent().get_current_tab_control() == dock:
			if current_vecdrawing != null:
				get_editor_interface().get_selection().add_node(current_vecdrawing)
				#get_editor_interface().edit_node(current_vecdrawing)


	# When the current tab control is NOT Vector Editing, the only
	# real meaningful mode is to select.
	#
	# We could at some point also add, like, a toolbar to the top of
	# the 2D view, but for now we'll just do this.
	if dock.get_parent().get_current_tab_control() != dock:
		dock_tabs.current_tab = dock_tabs.get_tab_idx_from_control(tab_drawing)
		drawing_tool_edit.button_pressed = true

func _dock_tab_changed(idx: int):
	if dock_tabs.get_current_tab_control() == tab_drawing:
		# Automatically reselect the drawing so that lasso will work,
		# IF select mode is on.
		if drawing_tool_edit.button_pressed and current_vecdrawing != null:
			get_editor_interface().get_selection().clear()
			get_editor_interface().get_selection().add_node(current_vecdrawing)

func _drawing_tool_edit_pressed():
	if current_vecdrawing != null:
		# Reset the selection to the current drawing when the edit button is pressed.
		get_editor_interface().get_selection().clear()
		get_editor_interface().get_selection().add_node(current_vecdrawing)

func _enter_tree():
	Engine.register_singleton("GDVecRig", self)
	
	# Load the dock scene and instantiate it.
	dock = preload("res://addons/gdvecrig/Vector Editing.tscn").instantiate()

	# Add the loaded scene to the docks.
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)

	dock_tabs = dock.get_node("TopVLayout/TabContainer")
	cur_drawing_display = dock.get_node("TopVLayout/CurrentDrawingUI/CurrentDrawingDisplay")
	tab_drawing = dock_tabs.get_node("Drawing")
	tab_weightpaint = dock_tabs.get_node("Weight Painting")
	
	dock_tabs.tab_changed.connect(_dock_tab_changed)
	
	# SETUP DRAWING UI
	var d_tool = dock_tabs.get_node("Drawing/ToolSelector")
	drawing_tool_group = ButtonGroup.new()
	drawing_tool_edit = setup_button(d_tool, "ToolSelect", drawing_tool_group)
	drawing_tool_new = setup_button(d_tool, "ToolNewPoint", drawing_tool_group)
	drawing_tool_knife = setup_button(d_tool, "ToolKnife", drawing_tool_group)
	drawing_tool_toggle_constraint = setup_button(d_tool, "ToolToggleConstraint", drawing_tool_group)
	drawing_tool_delete = setup_button(d_tool, "ToolDelete", drawing_tool_group)
	drawing_tool_edit.button_pressed = true
	
	drawing_tool_edit.pressed.connect(_drawing_tool_edit_pressed)
	
	# SETUP WEIGHT PAINTING UI
	bone_list = dock.get_node("%BoneList")
	bone_list.connect("item_selected", _on_bone_list_selected)
	
	weight_paint_value_box = dock.get_node("%WeightPaintValBox")
	weight_paint_strength_box = dock.get_node("%WeightPaintStrengthBox")
	
	var wp_tool = dock_tabs.get_node("Weight Painting/VBox/ToolSelector")
	weight_paint_tool_group = ButtonGroup.new()
	weight_paint_tool_add = setup_button(wp_tool, "Add", weight_paint_tool_group)
	weight_paint_tool_sub = setup_button(wp_tool, "Subtract", weight_paint_tool_group)
	weight_paint_tool_mix = setup_button(wp_tool, "Mix", weight_paint_tool_group)
	weight_paint_tool_add.button_pressed = true
	# Note that LEFT_UL means the left of the editor, upper-left dock.
	# Initialization of the plugin goes here.
	pass


func _exit_tree():
	remove_control_from_docks(dock)
	# Erase the control from the memory.
	dock.free()
	# Clean-up of the plugin goes here.
	
	Engine.unregister_singleton("GDVecRig")
	pass
