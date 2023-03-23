@tool
extends EditorPlugin
class_name GDVecRig

var current_vecdrawing = null

var point_highlight = 0

func _handles(node):
	if node is VecDrawing:
		return true
	return false
	
func _edit(object):
	if object is VecDrawing:
		current_vecdrawing = object
	else:
		current_vecdrawing = null
	return
		
func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if is_instance_valid(current_vecdrawing):
		return current_vecdrawing.edit_input(self, event)
	return false
	
func _make_visible(visible):
	pass

func _enter_tree():
	Engine.register_singleton("GDVecRig", self)
	# Initialization of the plugin goes here.
	pass


func _exit_tree():
	Engine.unregister_singleton("GDVecRig")
	# Clean-up of the plugin goes here.
	pass
