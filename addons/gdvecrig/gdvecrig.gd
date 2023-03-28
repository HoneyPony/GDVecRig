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
var weight_painting_bone: int = -1

func _on_bone_list_selected(index: int):
	weight_painting_bone = index

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

var dock

var bone_list: ItemList

func _enter_tree():
	Engine.register_singleton("GDVecRig", self)
	
	# Load the dock scene and instantiate it.
	dock = preload("res://addons/gdvecrig/Vector Editing.tscn").instantiate()

	# Add the loaded scene to the docks.
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	bone_list = dock.get_node("%BoneList")
	bone_list.connect("item_selected", _on_bone_list_selected)
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
