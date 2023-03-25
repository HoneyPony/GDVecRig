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

func _handles(node):
	if node is VecDrawing:
		return true
	return false
	
func load_bones(drawing: VecDrawing):
	bone_list.clear()
	
	var skeleton: Skeleton2D = drawing.get_node_or_null(drawing.skeleton)
	if skeleton == null:
		return
	
	for i in range(0, skeleton.get_bone_count()):
		var bone = skeleton.get_bone(i)
		
		bone_list.add_item(bone.name)
	
func _edit(object):
	if object is VecDrawing:
		current_vecdrawing = object
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


var button_draw
var button_paint
var button_group

var dock

var bone_list: ItemList

func _enter_tree():
	Engine.register_singleton("GDVecRig", self)
	
	button_group = ButtonGroup.new()
	
	button_draw = Button.new()
	button_draw.toggle_mode = true
	button_draw.text = "Draw"
	button_draw.button_group = button_group
	
	button_paint = Button.new()
	button_paint.toggle_mode = true
	button_paint.text = "Paint"
	button_paint.button_group = button_group
	
	
	
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, button_draw)
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, button_paint)
	
	
	# Load the dock scene and instantiate it.
	dock = preload("res://addons/gdvecrig/Vector Editing.tscn").instantiate()

	# Add the loaded scene to the docks.
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	bone_list = dock.get_node("TabContainer/Weight Painting/BoneList")
	# Note that LEFT_UL means the left of the editor, upper-left dock.
	# Initialization of the plugin goes here.
	pass


func _exit_tree():
	Engine.unregister_singleton("GDVecRig")
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, button_draw)
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, button_paint)
	
	remove_control_from_docks(dock)
	# Erase the control from the memory.
	dock.free()
	# Clean-up of the plugin goes here.
	pass
