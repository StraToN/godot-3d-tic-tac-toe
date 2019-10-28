extends GravityBehaviour

signal cube_rotation_finished

var rotation_applied : Vector3

func rotate_cube(axis, angle = PI/2):
	var axis_vector
	
	var rotating_node = cube.get_node("roll")
	match axis:
		cube.AXIS.X:
			axis_vector = Vector3.RIGHT
		cube.AXIS.Z:
			axis_vector = Vector3.FORWARD
			if rotating_node.rotation_degrees.x == 90 || rotating_node.rotation_degrees.x == 270:
				axis_vector = Vector3.UP
				rotating_node = cube.get_node("roll/yaw")
				
				
	rotation_applied = angle * axis_vector
	
	for b in cube.get_node("roll/yaw/balls_container").get_children():
		var ball_target_rotation = b.rotation - angle * axis_vector
		cube.get_node("roll/yaw/cube_rotate").interpolate_property(b, 
			"rotation", b.rotation, ball_target_rotation, 0.4, 
			Tween.TRANS_QUAD, Tween.EASE_IN_OUT)

	var pivot_target_rotation = rotating_node.rotation + angle * axis_vector
	cube.get_node("roll/yaw/cube_rotate").interpolate_property(rotating_node, 
		"rotation", rotating_node.rotation, 
		pivot_target_rotation, 0.4, 
		Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	
	
	for face_pivot in cube.get_node("roll/yaw/face_pivots_container").get_children():
		# reset rotation to 0 so that angle value doesn't increase gradually with each new rotation
		var face_pivot_target_rotation = face_pivot.rotation + angle * axis_vector
		cube.get_node("roll/yaw/face_rotate").interpolate_property(face_pivot, 
			"rotation", face_pivot.rotation, face_pivot_target_rotation, 0.4, 
			Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	cube.get_node("roll/yaw/cube_rotate").start()


func _on_cube_rotate_tween_all_completed():
	cube.get_node("roll").rotation_degrees = cube.get_node("roll").rotation_degrees.round()
	cube.get_node("roll").rotation_degrees.x = clamp0360(cube.get_node("roll").rotation_degrees.x)
	cube.get_node("roll").rotation_degrees.y = clamp0360(cube.get_node("roll").rotation_degrees.y)
	cube.get_node("roll").rotation_degrees.z = clamp0360(cube.get_node("roll").rotation_degrees.z)
	
#	cube.get_node("roll/yaw").rotation_degrees = cube.get_node("roll/yaw").rotation_degrees.round()
#	cube.get_node("roll/yaw").rotation_degrees.x = clamp0360(cube.get_node("roll/yaw").rotation_degrees.x)
#	cube.get_node("roll/yaw").rotation_degrees.y = clamp0360(cube.get_node("roll/yaw").rotation_degrees.y)
#	cube.get_node("roll/yaw").rotation_degrees.z = clamp0360(cube.get_node("roll/yaw").rotation_degrees.z)
	
	cube.recalculate_slots()
	cube.recalculate_faces()
	get_parent().apply_gravity()
	emit_signal("cube_rotation_finished")

func clamp0360(var eulerAngles):
	var result = eulerAngles - ceil(eulerAngles / 360.0) * 360.0
	if (result < 0.0):
		result += 360.0;
	return result;
