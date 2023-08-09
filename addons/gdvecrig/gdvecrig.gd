@tool
extends EditorPlugin
class_name GDVecRig

var current_vecdrawing = null

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

func is_in_toggle_constraint():
	return drawing_tool_toggle_constraint.button_pressed

func _on_bone_list_selected(index: int):
	weight_painting_bone = index

func _handles(node):
	if node is VecDrawing:
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
		current_vecdrawing = object
		cur_drawing_display.text = current_vecdrawing.name
		point_highlight = 0
		point_selection = []
		point_edited = false
		lasso_started = false
		lasso_points.clear()
		
		load_bones(object)
	else:
		current_vecdrawing = null
	return
		
func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if is_instance_valid(current_vecdrawing):
		return current_vecdrawing.edit_input(self, event)
	return false
	
func _make_visible(visible):
	pass

var dock

var dock_tabs: TabContainer
var cur_drawing_display: Label

var tab_drawing: Control
var tab_weightpaint: Control

# --- DRAWING TOOLS ---
var drawing_tool_edit: Button
var drawing_tool_new: Button
var drawing_tool_knife: Button
var drawing_tool_toggle_constraint: Button
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
	
	# SETUP DRAWING UI
	var d_tool = dock_tabs.get_node("Drawing/ToolSelector")
	drawing_tool_group = ButtonGroup.new()
	drawing_tool_edit = setup_button(d_tool, "ToolSelect", drawing_tool_group)
	drawing_tool_new = setup_button(d_tool, "ToolNewPoint", drawing_tool_group)
	drawing_tool_knife = setup_button(d_tool, "ToolKnife", drawing_tool_group)
	drawing_tool_toggle_constraint = setup_button(d_tool, "ToolToggleConstraint", drawing_tool_group)
	drawing_tool_edit.button_pressed = true
	
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
