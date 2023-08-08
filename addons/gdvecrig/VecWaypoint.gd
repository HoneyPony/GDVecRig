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
	
func compute_bone_transform(bone: Bone2D, cache: Dictionary) -> Transform2D:
	var existing = cache.get(bone)
	if existing != null:
		return existing
	
	var p: Node = bone.get_parent()
	var p_bone: Bone2D = p as Bone2D
	var p_transform: Transform2D = Transform2D.IDENTITY
	
	if p_bone != null:
		p_transform = compute_bone_transform(p_bone, cache)
	elif p != null:
		p_transform = p.transform
	#else: # Already assigned above
	#	p_transform = Transform2D.IDENTITY	
		
	# The basic transform is just the transform, but relative to the rest pose.
	var result: Transform2D = bone.rest.affine_inverse() * bone.transform
	
	# Root bones have the special property that their origin IS the origin
	# that the skeleton must rotate around. As such, we must manually
	# create that behavior by moving the rotation pivot.
	if p_bone == null:
		result = Transform2D(0, bone.rest.origin) * result * Transform2D(0, -bone.rest.origin)
	else:
		result = Transform2D(0, -bone.rest.origin) * result * Transform2D(0, bone.rest.origin)
	
	# Finally, apply the parent transform.
	result = p_transform * result
	
	# Add this transform to the cache so future callers can skip the computation
	cache[bone] = result
	
	return result

func compute_value(skeleton: Skeleton2D, transform_cache: Dictionary):
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
		var tformed = compute_bone_transform(bone, transform_cache) * value
		computed_value += weight * tformed
		
		total_weight += weight

	if total_weight == 0:
		computed_value = value
		return
	computed_value /= total_weight
#
#func _process(delta):
#	compute_value()
