@tool
extends EditorPlugin
class_name GDVecRig

var current_vecdrawing = null

var point_highlight = 0
var point_selection = []
var point_edited = false

func _handles(node):
	if node is VecDrawing:
		return true
	return false
	
func _edit(object):
	if object is VecDrawing:
		current_vecdrawing = object
		point_highlight = 0
		point_selection = []
		point_edited = false
	else:
		current_vecdrawing = null
	return
		
func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if is_instance_valid(current_vecdrawing):
		return current_vecdrawing.edit_input(self, event)
	return false
	
func _make_visible(visible):
	pass


var button_test

func _enter_tree():
	Engine.register_singleton("GDVecRig", self)
	
	button_test = Button.new()
	button_test.text = "Test"
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, button_test)
	# Initialization of the plugin goes here.
	pass


func _exit_tree():
	Engine.unregister_singleton("GDVecRig")
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, button_test)
	# Clean-up of the plugin goes here.
	pass
