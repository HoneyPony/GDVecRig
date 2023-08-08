@tool
extends Node
class_name VecWaypoint

@export var value: Vector2
var computed_value: Vector2 = Vector2.ZERO

@export var weights = {}

#	if not bone.is_empty():
#		#var test: Bone2D = get_node(bone)
#		var bone2d: Bone2D = get_node(bone)
#
#		# TODO: Godot does not currently cache affine_inverse,
#		# we probably want to do it ourselves.
#		computed_value = bone2d.rest.affine_inverse() * bone2d.transform * value
#	else:
#		computed_value = value

#@export var bones: Array[VecBone]
#@export var weights: PackedFloat32Array
#
func get_weight(index):
	return weights.get(index, 0)
	
func edit_weight(index, plugin: GDVecRig):
	var w = get_weight(index)
	w = plugin.paint_weight(w)
	w = clamp(w, 0.0, 1.0)
	weights[index] = w
	
func add_weight(index, weight):
	var w = get_weight(index)
	w += weight
	w = clamp(w, 0.0, 1.0)
	weights[index] = w
	
func compute_bone_transform(bone: Bone2D):
	var p: Node = bone.get_parent()
	if p != null:
		var p_bone: Bone2D = p as Bone2D
		var p_transform: Transform2D
		var own_inverse = bone.rest.affine_inverse()
		if p_bone != null:
			p_transform = compute_bone_transform(p_bone)
		else:
			p_transform = Transform2D.IDENTITY
			#own_inverse.origin = bone.rest.origin
			
		var result = bone.transform
		result = own_inverse * result
		result = p_transform * result
		
		if p_bone == null:
			result = Transform2D(0, bone.rest.origin) * result * Transform2D(0, -bone.rest.origin)
			
		return result
	else:
		return bone.rest.affine_inverse() * bone.transform

func compute_value(skeleton: Skeleton2D):
	if weights.is_empty():
		computed_value = value
		return
	computed_value = Vector2.ZERO

	var total_weight = 0
	for i in weights:
		if i == -1:
			continue
		var weight = weights[i]
		var bone = skeleton.get_bone(i)
		
		#var tformed = bone.rest.affine_inverse() * bone.transform * value
		var tformed = compute_bone_transform(bone) * value
		computed_value += weight * tformed
		
		total_weight += weight

	if total_weight == 0:
		computed_value = value
		return
	computed_value /= total_weight
#
#func _process(delta):
#	compute_value()
