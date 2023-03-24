@tool
extends Node
class_name VecWaypoint

@export var value: Vector2
var computed_value: Vector2 = Vector2.ZERO

@export var bone: NodePath = NodePath()

func compute_value():
	if not bone.is_empty():
		computed_value = get_node(bone).transform * value
	else:
		computed_value = value

#@export var bones: Array[VecBone]
#@export var weights: PackedFloat32Array
#
#func compute_value():
#	if bones.is_empty():
#		computed_value = value
#		return
#	computed_value = Vector2.ZERO
#
#	var i = 0
#	var weight = 0
#	for bone in bones:
#		if not is_instance_valid(bone):
#			continue
#		var tformed = bone.transform * value
#		computed_value += weights[i] * tformed
#		weight += weights[i]
#		i += 1
#
#	if weight == 0:
#		computed_value = value
#		return
#	computed_value /= weight
#
func _process(delta):
	compute_value()
