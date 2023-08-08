# GDVecRig
GDVecRig is a Godot 4 plugin that provides vector graphics with one specific
goal: ability to perform skeletal animation with Bezier control points rather 
than with rasterized vector graphics.

To accomplish this goal, GDVecRig consists of a vector graphics editing tool
built-in to Godot, along with the required architecture to enable rigging vector
graphics to skeletons.

Unfortunately, existing vector formats are generally unsuited to game vector
graphics. In particular, vector graphics editors generally do not support very
nice masking operations or useful models for strokes / lines in drawings.

However, Godot already has a lot of useful operations built in for compositing
graphics, including a hierarchical scene tree, and, in Godot 4, masking
operations!

This means that the only thing really missing from Godot is a way to represent
individual vector graphics objects in a way that can be easily rigged to 2D
skeletons. That is what this plugin intends to provide.

Currently, the plugin is in a work-in-progress state; vector editing works to
some degree, as well as rigging, but it needs more work to be fully usable.
