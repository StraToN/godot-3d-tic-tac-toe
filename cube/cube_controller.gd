tool
extends Spatial

#signal column_ball_falldown_anim_finished(target_ball)

# Strategy pattern: behaviour nodes
var input_behaviour_node
var face_rotations_behaviour_node = null
var cube_rotations_behaviour_node = null
#var bonus_behaviour_node = null

var ball_scene = load("res://ball/ball_static.tscn")

# target ball to falldown in gravity rules
# warning-ignore:unused_class_variable
var acquired_ball

export(int, 3, 5) var length = 4 setget set_length,get_length
export(float, 3.0, 10.0) var spacing = 3.5 setget set_spacing,get_spacing

# Slots are "cells" that do not move, contrarily to balls. 
# Thus, slots actually change their content all the time
var balls_slots = {} # canonical_position => ball instance, ie. (0,0,0) => ball1

# Every ball belongs to 3 "faces" in the cube
# a "face" is a plane of `length*length` balls, on a given axis and a given level
# Each of these arrays has a size of `length`
# Each element of these arrays is an dict containing :
# 	- an array containing all the balls of the given face
#	- a pivot value containing the coords of the face pivot
# ie. faces_x = [ 	0 => { "balls" => [ list of balls in the face ], "pivot": (0, 4.5, 4.5) }
#					1 => {...}, 2 => {...}, 3 => {...} ]
var faces_x = []
var faces_y = []
var faces_z = []

onready var target_balls_for_player_change = []

enum AXIS {X, Y, Z}

var gravity_center : Vector3

func _ready():
	if Engine.is_editor_hint():
		init_balls() # not needed : called on game.reset()
	
	# Remove face pivots position3ds nodes
	for c in $roll/yaw/face_pivots_container.get_children():
		$roll/yaw/face_pivots_container.remove_child(c)
	
	# warning-ignore:return_value_discarded
	$roll/yaw/GameRulesBehaviour/Gravity.connect("click_applied", 
			get_parent(), "_on_click_applied")
	# warning-ignore:return_value_discarded
	$roll/yaw/GameRulesBehaviour/NoGravity.connect("click_applied", 
			get_parent(), "_on_click_applied")
	# warning-ignore:return_value_discarded
	$roll/yaw/GameRulesBehaviour/Gravity/RotatingCube.connect("cube_rotation_finished", 
			get_parent(), "_on_RotatingFaces_ready_for_new_rotation")
	# warning-ignore:return_value_discarded
	$roll/yaw/GameRulesBehaviour/RotatingFaces.connect("ready_for_new_rotation", 
			get_parent(), "_on_RotatingFaces_ready_for_new_rotation")
	
	if game_parameters.game_rules["gravity"]:
		input_behaviour_node = $roll/yaw/GameRulesBehaviour/Gravity
	else:
		input_behaviour_node = $roll/yaw/GameRulesBehaviour/NoGravity
	
	if game_parameters.game_rules["rotations"]:
		face_rotations_behaviour_node = $roll/yaw/GameRulesBehaviour/RotatingFaces
	
	if game_parameters.game_rules["cube_rotations"]:
		cube_rotations_behaviour_node = $roll/yaw/GameRulesBehaviour/Gravity/RotatingCube

# Activate demonstrations for new game menu
func activate_rotations(active):
	if active:
		face_rotations_behaviour_node = $roll/yaw/GameRulesBehaviour/RotatingFaces
	else:
		face_rotations_behaviour_node = null

func init_balls():
	var numball = 0
	$roll/yaw/balls_container.global_transform.origin = Vector3.ZERO
	delete_all_balls()
	for x in range(length):
		for y in range(length):
			for z in range(length):
				var ball_pos = Vector3(x,y,z)
				var ball = ball_scene.instance()
				ball.x_plane_id = x
				ball.y_plane_id = y
				ball.z_plane_id = z
				balls_slots[ball_pos] = ball
				$roll/yaw/balls_container.add_child(ball)
				ball.name = "ball"+str(numball)
				ball.global_transform.origin = ball_pos * spacing
				numball += 1
	recalculate_faces()
	recalculate_cube_gravity_point()
#	reset_face_pivot_viewers()
	

#func reset_face_pivot_viewers():
#	# Reset face pivots viewers
#	#if Engine.is_editor_hint():
#		for pivots in $roll/yaw/balls_faces_pivots.get_children():
#			pivots.queue_free()
#
#		for pivots_x in faces_x:
#			var px = MeshInstance.new()
#			px.mesh = SphereMesh.new()
#			$roll/yaw/balls_faces_pivots.add_child(px)
#			px.global_transform.origin = pivots_x.pivot
#			px.global_transform.basis = Basis(Vector3.UP, 0)
#			px.rotation = $roll.rotation
#
#		for pivots_y in faces_y:
#			var py = MeshInstance.new()
#			py.mesh = SphereMesh.new()
#			$roll/yaw/balls_faces_pivots.add_child(py)
#			py.global_transform.origin = pivots_y.pivot
#			py.global_transform.basis = Basis(Vector3.UP, 0)
#			py.rotation = $roll.rotation
#
#		for pivots_z in faces_z:
#			var pz = MeshInstance.new()
#			pz.mesh = SphereMesh.new()
#			$roll/yaw/balls_faces_pivots.add_child(pz)
#			pz.global_transform.origin = pivots_z.pivot
#			pz.global_transform.basis = Basis(Vector3.UP, 0)
#			pz.rotation = $roll.rotation
		

func recalculate_slots():
	balls_slots.clear()
#	BACKUP 23 oct 13h30 before attempting to calculate expected in balls
#	for b in $roll/yaw/balls_container.get_children():
#		var canonical_position = (b.global_transform.origin + 1.5 * Vector3(spacing, spacing, spacing))
#		canonical_position /= spacing
#		canonical_position = canonical_position.round()
#		balls_slots[canonical_position] = b
	for b in $roll/yaw/balls_container.get_children():
		var canonical_position = b.get_canonical_position()
		balls_slots[canonical_position] = b
		

	assert(balls_slots.size() == pow(length, 3))

# After a rotation, faces contents (ie. balls contained by each face) change. 
# We need to recalculate them in order to determine if there's a win or not.
func recalculate_faces():
	if Engine.is_editor_hint():
		return
	
	faces_x.clear()
	faces_y.clear()
	faces_z.clear()
	
	# X
	for x in range(length):
		var face = []
		for y in range(length):
			for z in range(length):
				var ball_pos = Vector3(x,y,z)
				var ball
				for b in $roll/yaw/balls_container.get_children():
					if b.get_canonical_position() == ball_pos:
						ball = b
						break
				assert(ball.x_plane_id == x)
				face.push_back(ball)
		
		var node_pivot_position_name = "face_pivot_x"+str(x)
		var pivot_position_node = null
		if $roll/yaw/face_pivots_container.has_node(node_pivot_position_name):
			pivot_position_node = $roll/yaw/face_pivots_container.get_node(node_pivot_position_name)
		var face_pivot_position
		if pivot_position_node:
			face_pivot_position = pivot_position_node.transform.origin
		else: # On 1st time, calculate pivot and insert Position3D in face_pivots_container
			pivot_position_node = Position3D.new()
			$roll/yaw/face_pivots_container.add_child(pivot_position_node)
			pivot_position_node.name = node_pivot_position_name
			face_pivot_position = recalculate_gravity_point(face)
			pivot_position_node.transform.origin = face_pivot_position
		pivot_position_node.rotation = $roll.rotation
		faces_x.push_back({"balls": face, "pivot" : face_pivot_position, "pivot_node": pivot_position_node})
	
	# Z
	for z in range(length):
		var face = []
		for y in range(length):
			for x in range(length):
				var ball_pos = Vector3(x,y,z)
				var ball
				for b in $roll/yaw/balls_container.get_children():
					if b.get_canonical_position() == ball_pos:
						ball = b
						break
				assert(ball.x_plane_id == x)
				face.push_back(ball)
				
		var node_pivot_position_name = "face_pivot_z"+str(z)
		var pivot_position_node = null
		if $roll/yaw/face_pivots_container.has_node(node_pivot_position_name):
			pivot_position_node = $roll/yaw/face_pivots_container.get_node(node_pivot_position_name)
		var face_pivot_position
		if pivot_position_node:
			face_pivot_position = pivot_position_node.transform.origin
		else: # On 1st time, calculate pivot and insert Position3D in face_pivots_container
			pivot_position_node = Position3D.new()
			$roll/yaw/face_pivots_container.add_child(pivot_position_node)
			pivot_position_node.name = node_pivot_position_name
			face_pivot_position = recalculate_gravity_point(face)
			pivot_position_node.transform.origin = face_pivot_position
		pivot_position_node.rotation = $roll.rotation
		faces_z.push_back({"balls": face, "pivot" : face_pivot_position, "pivot_node": pivot_position_node})
	
	# Y
	for y in range(length):
		var face = []
		for z in range(length):
			for x in range(length):
				var ball_pos = Vector3(x,y,z)
				var ball
				for b in $roll/yaw/balls_container.get_children():
					if b.get_canonical_position() == ball_pos:
						ball = b
						break
				assert(ball.x_plane_id == x)
				face.push_back(ball)
		
		var node_pivot_position_name = "face_pivot_y"+str(y)
		var pivot_position_node = null
		if $roll/yaw/face_pivots_container.has_node(node_pivot_position_name):
			pivot_position_node = $roll/yaw/face_pivots_container.get_node(node_pivot_position_name)
		var face_pivot_position
		if pivot_position_node:
			face_pivot_position = pivot_position_node.transform.origin
		else: # On 1st time, calculate pivot and insert Position3D in face_pivots_container
			pivot_position_node = Position3D.new()
			$roll/yaw/face_pivots_container.add_child(pivot_position_node)
			pivot_position_node.name = node_pivot_position_name
			face_pivot_position = recalculate_gravity_point(face)
			pivot_position_node.transform.origin = face_pivot_position
		pivot_position_node.rotation = $roll.rotation
		faces_y.push_back({"balls": face, "pivot" : face_pivot_position, "pivot_node": pivot_position_node})

	assert(faces_x.size() == length)
	assert(faces_y.size() == length)
	assert(faces_z.size() == length)
	
#	reset_face_pivot_viewers()

func delete_all_balls():
	if balls_slots.empty():
		return
		
	for b in balls_slots.values():
		b.get_parent().remove_child(b)
		b.queue_free()
	balls_slots.clear()

func update_balls_spacing():
	if balls_slots.empty():
		return
		
	for pos in balls_slots.keys():
		var ball = balls_slots.get(pos)
		ball.global_transform.origin = pos * spacing
	recalculate_cube_gravity_point()

func set_length(l):
	length = l
	init_balls()

func get_length():
	return length

func set_spacing(s):
	spacing = s
	update_balls_spacing()

func get_spacing():
	return spacing

# Calculates the gravity point from all balls contained in the given array
func recalculate_gravity_point(balls_array):
	# Find center of gravity using mean position (RISKY?)
	var grav_x = 0
	var grav_y = 0
	var grav_z = 0
	for b in balls_array:
		grav_x += (b.global_transform.origin.x - 1.5 * spacing) 
		grav_y += (b.global_transform.origin.y - 1.5 * spacing) 
		grav_z += (b.global_transform.origin.z - 1.5 * spacing)
	
	var gravity_center_face_point3d = Vector3(grav_x, grav_y, grav_z) / balls_array.size()
	return gravity_center_face_point3d

# Recalculates the 3D position of the cube center of gravity
func recalculate_cube_gravity_point():
	# to recalculate the center, sum the 8 corner spheres' positions and calculate the mean
	var corner_balls_positions = []
	var length_coord = length - 1
	corner_balls_positions.push_back(balls_slots.get(Vector3(0,0,0)).global_transform.origin)
	corner_balls_positions.push_back(balls_slots.get(Vector3(0,0,length_coord)).global_transform.origin)
	corner_balls_positions.push_back(balls_slots.get(Vector3(length_coord,0,0)).global_transform.origin)
	corner_balls_positions.push_back(balls_slots.get(Vector3(length_coord,0,length_coord)).global_transform.origin)
	corner_balls_positions.push_back(balls_slots.get(Vector3(0,length_coord,0)).global_transform.origin)
	corner_balls_positions.push_back(balls_slots.get(Vector3(0,length_coord,length_coord)).global_transform.origin)
	corner_balls_positions.push_back(balls_slots.get(Vector3(length_coord,length_coord,0)).global_transform.origin)
	corner_balls_positions.push_back(balls_slots.get(Vector3(length_coord,length_coord,length_coord)).global_transform.origin)
	assert(corner_balls_positions.size() == 8)
	
	gravity_center = Vector3.ZERO
	for c in corner_balls_positions:
		gravity_center += c
	gravity_center /= 8
	for b in balls_slots.values():
		b.global_transform.origin -= gravity_center
	
		
func rotate_plane(axis, level, angle):
	if face_rotations_behaviour_node:
		face_rotations_behaviour_node.rotate_plane(axis, level, angle)

func rotate_cube(axis, angle):
	if cube_rotations_behaviour_node:
		recalculate_cube_gravity_point()
		cube_rotations_behaviour_node.rotate_cube(axis, angle)

# Determines a winner player on the whole cube.
# returns an array composed of [winner, winning_balls]
# If no winner is found, returns null.
func determine_win():
	for level in range(length):
		var winner_and_array_x = determine_win_on_face(AXIS.X, level)
		if winner_and_array_x != null:
			return winner_and_array_x
		
		var winner_and_array_y = determine_win_on_face(AXIS.Y, level)
		if winner_and_array_y != null:
			return winner_and_array_y
		
		var winner_and_array_z = determine_win_on_face(AXIS.Z, level)
		if winner_and_array_z != null:
			return winner_and_array_z
		
		# inner diagonals
		var winner_and_array_inner_diag = determine_win_on_inner_diagonals()
		if winner_and_array_inner_diag != null:
			return winner_and_array_inner_diag 
			
	return null

# return id of the winner if all elements of the array are identical. Else return null
func get_winner_in_balls_line(balls_array):
	var preceding = balls_array[0].player
	if preceding == null:
		return null
		
	for ball in balls_array:
		if ball.player != preceding:
			return null
	return preceding

# (private) Called by determine_win()
# Determines the winner player on a given face
# returns an array composed of [winner, winning_balls]
# If no winner is found, returns nothing.
func determine_win_on_face(axis, level):
	assert(level >= 0)
	match axis:
		AXIS.X:
			# columns
			for y in range(length):
				var balls_players = []
				for z in range(length):
					var ball_pos = Vector3(level,y,z)
					var ball = balls_slots.get(ball_pos)
					balls_players.push_back(ball)
				var winner = get_winner_in_balls_line(balls_players)
				if winner != null:
					return [winner, balls_players]
			
			# lines
			for z in range(length):
				var balls_players = []
				for y in range(length):
					var ball_pos = Vector3(level,y,z)
					var ball = balls_slots.get(ball_pos)
					balls_players.push_back(ball)
				var winner = get_winner_in_balls_line(balls_players)
				if winner != null:
					return [winner, balls_players]
			
			# diagonals
			var diagonal1 = []
			for i in range(length):
				diagonal1.push_back(balls_slots.get(Vector3(level,i,i)))
			var winner = get_winner_in_balls_line(diagonal1)
			if winner != null:
				return [winner, diagonal1]
					
			var diagonal2 = []
			for j in range(length):
				diagonal2.push_back(balls_slots.get(Vector3(level,j, length-j-1)))
			winner = get_winner_in_balls_line(diagonal2)
			if winner != null:
				return [winner, diagonal2]
			
		AXIS.Y:
			# columns
			for x in range(length):
				var balls_players = []
				for z in range(length):
					var ball_pos = Vector3(x,level,z)
					var ball = balls_slots.get(ball_pos)
					balls_players.push_back(ball)
				var winner = get_winner_in_balls_line(balls_players)
				if winner != null:
					return [winner, balls_players]
			
			# lines
			for z in range(length):
				var balls_players = []
				for x in range(length):
					var ball_pos = Vector3(x,level,z)
					var ball = balls_slots.get(ball_pos)
					balls_players.push_back(ball)
				var winner = get_winner_in_balls_line(balls_players)
				if winner != null:
					return [winner, balls_players]
				
			# diagonals
			var diagonal1 = []
			for i in range(length):
				diagonal1.push_back(balls_slots.get(Vector3(i,level,i)))
			var winner = get_winner_in_balls_line(diagonal1)
			if winner != null:
				return [winner, diagonal1]
					
			var diagonal2 = []
			for j in range(length):
				diagonal2.push_back(balls_slots.get(Vector3(j,level,length-j-1)))
			winner = get_winner_in_balls_line(diagonal2)
			if winner != null:
				return [winner, diagonal2]
				
		AXIS.Z:
			# columns
			for y in range(length):
				var balls_players = []
				for x in range(length):
					var ball_pos = Vector3(x,y,level)
					var ball = balls_slots.get(ball_pos)
					balls_players.push_back(ball)
				var winner = get_winner_in_balls_line(balls_players)
				if winner != null:
					return [winner, balls_players]
			
			# lines
			for x in range(length):
				var balls_players = []
				for y in range(length):
					var ball_pos = Vector3(x,y,level)
					var ball = balls_slots.get(ball_pos)
					balls_players.push_back(ball)
				var winner = get_winner_in_balls_line(balls_players)
				if winner != null:
					return [winner, balls_players]
			
			# diagonals
			var diagonal1 = []
			for i in range(length):
				diagonal1.push_back(balls_slots.get(Vector3(i,i,level)))
			var winner = get_winner_in_balls_line(diagonal1)
			if winner != null:
				return [winner, diagonal1]
					
			var diagonal2 = []
			for j in range(length):
				diagonal2.push_back(balls_slots.get(Vector3(j,length-j-1,level)))
			winner = get_winner_in_balls_line(diagonal2)
			if winner != null:
				return [winner, diagonal2]

# (private) Called by determine_win()
# Determines win the 4 inner diagonals of the cube.
# returns an array composed of [winner, winning_balls]
# If no winner is found, returns nothing.
func determine_win_on_inner_diagonals():
	# diagonal 1
	var diagonal1 = []
	for i in range(length):
		diagonal1.push_back(balls_slots.get(Vector3(i,i,length-i-1)))
	var winner = get_winner_in_balls_line(diagonal1)
	if winner != null:
		return [winner, diagonal1]
		
	# diagonal 2
	var diagonal2 = []
	for i in range(length):
		diagonal2.push_back(balls_slots.get(Vector3(length-i-1,i,length-i-1)))
	winner = get_winner_in_balls_line(diagonal2)
	if winner != null:
		return [winner, diagonal2]
	
	# diagonal 3
	var diagonal3 = []
	for i in range(length):
		diagonal3.push_back(balls_slots.get(Vector3(i,length-i-1,length-i-1)))
	winner = get_winner_in_balls_line(diagonal3)
	if winner != null:
		return [winner, diagonal3]
	
	# diagonal 4
	var diagonal4 = []
	for i in range(length):
		diagonal4.push_back(balls_slots.get(Vector3(length-i-1,length-i-1,length-i-1)))
	winner = get_winner_in_balls_line(diagonal4)
	if winner != null:
		return [winner, diagonal4]

# Starts an animation where all balls except given balls get transparent
# used for game over animation.
func animate_game_over(winning_balls_array):
	for b in $roll/yaw/balls_container.get_children():
		if !winning_balls_array.has(b):
			b.set_ball_transparent()

# Specific for gameplay with gravity.
# Returns the lowest neutral ball in the column of given ball parameter, if any
# else, returns null 
func get_lowest_in_column(ball):
	printt("Column clicked: ", ball.x_plane_id, ball.z_plane_id)
	for i in range(length):
		var pos = Vector3(ball.x_plane_id, i, ball.z_plane_id)
		if !balls_slots[pos].is_owned():
			return balls_slots[pos]
	return null

func set_column_respond_to_inputs(ball, shall_respond):
	for i in range(length):
		var pos = Vector3(ball.x_plane_id, i, ball.z_plane_id)
		balls_slots[pos].set_respond_to_inputs(shall_respond)

func set_column_to_noone_or_player(ball):
	for i in range(length):
		var pos = Vector3(ball.x_plane_id, i, ball.z_plane_id)
		balls_slots[pos].set_ball_to_noone_or_player()

func apply_ball_click(ball, player, color):
	input_behaviour_node.apply_click(ball, player, color)

func queue_ball_player_change(target_ball, player, color_player):
	target_balls_for_player_change.append({"ball": target_ball, "player": player, "color_player": color_player})

func apply_queued_ball_player_change():
	for item in target_balls_for_player_change:
		item.ball.set_ball_player_color(item.player, item.color_player)
	target_balls_for_player_change.clear()
