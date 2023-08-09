@tool
extends Node
class_name VecWaypoint

@export var value: Vector2
var computed_value: Vector2 = Vector2.ZERO

# TODO: Consider using a more efficient data structure than a dictionary for
# this. E.g., maybe a PackedFloat32Array that is the size of the skeleton.
@export var weights = {}

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
	var result: Transform2D = bone.transform
	result = bone.rest.affine_inverse() * result
	
	# Bones must be rotated around their pivot point. This accomplishes this,
	# by changing the pivot point of the transform space (of the previously
	# computed transform).
	#
	# get_skeleton_rest() seems to get the correct pivot point.
	#
	# Note on get_skeleton_rest(): Perusing the Godot source code, this method
	# is not the most efficient... it walks all the way up the skeleton
	# heirarchy. BUT... we only have to call it once per bone, and it might
	# overall be faster than our own method... if we need to repalce it,
	# we can, using the compute_bone_overall_rest function from commit 672cfa9
	# and just add a second dictionary cache.
	var pivot = bone.get_skeleton_rest().origin
	result = Transform2D(0, pivot) * result * Transform2D(0, -pivot)
		#result = Transform2D(0, -bone.rest.origin) * result * Transform2D(0, bone.rest.origin)
	
	# Finally, apply the parent transform.
	result = p_transform * result
	
	# Add this transform to the cache so future callers can skip the computation
	cache[bone] = result
	
	return result

func compute_value(skeleton: Skeleton2D, transform_cache: Dictionary):
	if weights.is_empty() or skeleton == null:
		computed_value = value
		return
	computed_value = Vector2.ZERO

	var total_weight = 0
	for i in weights:
		if i == -1:
			continue
		var weight = weights[i]
		if weight == 0:
			continue
		var bone = skeleton.get_bone(i)
		
		# Compute the associated bone transform times each value, for every
		# bone with a non-zero weight.
		var tformed = compute_bone_transform(bone, transform_cache) * value
		computed_value += weight * tformed
		
		total_weight += weight

	if total_weight == 0:
		computed_value = value
		return
	computed_value /= total_weight
