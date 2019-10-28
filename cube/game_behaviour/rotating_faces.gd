extends RuleBehaviour

signal ready_for_new_rotation

onready var gravity_behaviour_node = get_parent().get_node("Gravity")
var matrix_tools = preload("res://matrix_tools.gd")

var pivot_node

# Rotates by given angle value the plane defined by 
# the given axis (type AXIS.X/Y/Z) and 
# the level (0 to 4 depending on the cube size)
func rotate_plane(axis, level, angle = PI/2):
	assert(level >= 0)
	
	var face2d = []
	for i in range(cube.length):
		face2d.append([])
		for j in range(cube.length):
			face2d[i].append(null)
	
	var face
	var pivot
	var axis_vector
	match axis:
		cube.AXIS.X:
			face = cube.faces_x[level].balls
			pivot = cube.faces_x[level].pivot
			pivot_node = cube.faces_x[level].pivot_node
			axis_vector = Vector3.RIGHT
			
			for b in face:
				var y = b.y_plane_id
				var z = b.z_plane_id
				face2d[y][z] = b
			
			# Perform rotation in matrix and set the new canonical positions into each ball
			var face2d_rotated = matrix_tools.matrix_rotate(face2d, int(rad2deg(angle)))
			for y in range(cube.length):
				for z in range(cube.length):
					face2d_rotated[y][z].y_plane_id = y
					face2d_rotated[y][z].z_plane_id = z
			
		cube.AXIS.Y:
			face = cube.faces_y[level].balls
			pivot = cube.faces_y[level].pivot
			pivot_node = cube.faces_y[level].pivot_node
			axis_vector = Vector3.UP
			
			for b in face:
				var x = b.x_plane_id
				var z = b.z_plane_id
				face2d[x][z] = b
			
			# Perform rotation in matrix and set the new canonical positions into each ball
			var face2d_rotated = matrix_tools.matrix_rotate(face2d, int(rad2deg(angle)))
			for x in range(cube.length):
				for z in range(cube.length):
					face2d_rotated[x][z].x_plane_id = x
					face2d_rotated[x][z].z_plane_id = z
			
		cube.AXIS.Z:
			face = cube.faces_z[level].balls
			pivot = cube.faces_z[level].pivot
			pivot_node = cube.faces_z[level].pivot_node
			axis_vector = Vector3.FORWARD
			
			for b in face:
				var x = b.x_plane_id
				var y = b.y_plane_id
				face2d[x][y] = b
			
			# Perform rotation in matrix and set the new canonical positions into each ball
			var face2d_rotated = matrix_tools.matrix_rotate(face2d, int(rad2deg(angle)))
			for x in range(cube.length):
				for y in range(cube.length):
					face2d_rotated[x][y].x_plane_id = x
					face2d_rotated[x][y].y_plane_id = y
			
#	cube.get_node("roll/yaw/pivot_node").transform.origin = pivot
#	cube.get_node("roll/yaw/pivot_node").rotation = -cube.get_node("roll").rotation
	
	# Animation rotation
	for b in face:
		cube.get_node("roll/yaw/balls_container").remove_child(b)
		pivot_node.add_child(b)
		b.transform.origin -= pivot
		var ball_target_rotation = b.rotation - angle * axis_vector * cube.get_node("roll").rotation
		cube.get_node("roll/yaw/face_rotate").interpolate_property(b, 
			"rotation", b.rotation, ball_target_rotation, 0.4, 
			Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	
	var pivot_target_rotation = pivot_node.rotation + angle * axis_vector
	cube.get_node("roll/yaw/face_rotate").interpolate_property(pivot_node, "rotation", 
		pivot_node.rotation, pivot_target_rotation, 0.4, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	cube.get_node("roll/yaw/face_rotate").start()

# Callback when tweening animation (for face rotations) is completed.
func _on_face_rotate_tween_all_completed():
	for b in pivot_node.get_children():
		var global_transform_before_move = b.global_transform
		pivot_node.remove_child(b)
		cube.get_node("roll/yaw/balls_container").add_child(b)
		b.global_transform = global_transform_before_move
		b.rotation = Vector3.ZERO

	# reset rotation to 0 so that angle value doesn't increase gradually with each new rotation
#	cube.get_node("roll/yaw/pivot_node").rotation = Vector3.ZERO
	
	# balls have moved, faces have changed. Recalculate cube slots and faces
#	cube.recalculate_slots()
	cube.recalculate_faces()
	
	# apply gravity
	if game_parameters.game_rules["gravity"]:
		gravity_behaviour_node.apply_gravity()
	
	emit_signal("ready_for_new_rotation")
