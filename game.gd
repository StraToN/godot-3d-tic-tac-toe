extends Spatial

export(Array) var colors_players = []

export(int, 2, 3) var players_number = 2

enum STATES { 
	PLAYER_1, 
	PLAYER_2, 
	PLAYER_3, 
	GAME_OVER,
}
onready var current_state = STATES.PLAYER_1

# id of the winner
var winner = null
# Array of balls (instances, not coords) that made player win the game
var winning_balls = []

func _ready():
	add_to_group("game")
	
	set_process(false)
	reset()
	
	# set gimbal position to cube's gravity_center
	update_gimbal_position_and_distance()
	
	# hide rotation buttons depending on cube length
	for i in $HBoxContainer/vbox_rotatex.get_child_count():
		if i >= $cube.length:
			$HBoxContainer/vbox_rotatex.get_child(i).set_visible(false)
	for i in $HBoxContainer/vbox_rotatey.get_child_count():
		if i >= $cube.length:
			$HBoxContainer/vbox_rotatey.get_child(i).set_visible(false)	
	for i in $HBoxContainer/vbox_rotatez.get_child_count():
		if i >= $cube.length:
			$HBoxContainer/vbox_rotatez.get_child(i).set_visible(false)

func change_state(new_state):
	assert(new_state != null)
	current_state = new_state
	
	match current_state:
		STATES.PLAYER_1:
			get_tree().call_group("balls", "set_color_outline", colors_players[STATES.PLAYER_1])
		STATES.PLAYER_2:
			get_tree().call_group("balls", "set_color_outline", colors_players[STATES.PLAYER_2])
		STATES.PLAYER_3:
			get_tree().call_group("balls", "set_color_outline", colors_players[STATES.PLAYER_3])
		STATES.GAME_OVER:
			$win_controls.visible = true
			$cube.animate_game_over(winning_balls) # parameter : array of winning balls
			get_tree().call_group("balls", "set_respond_to_inputs", false)

func end_turn():
	if current_state == STATES.PLAYER_1:
		change_state(STATES.PLAYER_2)
	elif current_state == STATES.PLAYER_2:
		if players_number == 2:
			change_state(STATES.PLAYER_1)
		else:
			change_state(STATES.PLAYER_3)
	elif current_state == STATES.PLAYER_3:
		change_state(STATES.PLAYER_1)
	
func reset():
	$cube.length = game_parameters.cube_size
	$cube.init_balls()
	$win_controls.visible = false
	$spacing_slider.value = $cube.spacing
	change_state(STATES.PLAYER_1)
	
func ball_clicked(ball):
	$cube.apply_ball_click(ball, current_state, colors_players[current_state])

func _on_click_applied(is_gravity):
	if (!is_gravity):
		$cube.acquired_ball.set_ball_player_color(current_state, colors_players[current_state])
	test_win()
	end_turn()
	
	if winner == null:
		get_tree().call_group("balls", "set_respond_to_inputs", true)

func set_rotation_buttons_enabled(enabled):
	for c in $HBoxContainer/vbox_rotatex.get_children():
		c.disabled = !enabled
	for c in $HBoxContainer/vbox_rotatey.get_children():
		c.disabled = !enabled
	for c in $HBoxContainer/vbox_rotatez.get_children():
		c.disabled = !enabled

		
func rotate_face(axis, level, angle = PI/2):
	set_rotation_buttons_enabled(false)
	match axis:
		0:	#X
			$cube.rotate_plane($cube.AXIS.X, level, angle)
		1:	#Y
			$cube.rotate_plane($cube.AXIS.Y, level, angle)
		2: #Z
			$cube.rotate_plane($cube.AXIS.Z, level, angle)

func rotate_cube(axis, angle = PI/2):
	set_rotation_buttons_enabled(false)
	match axis:
		0:	#X
			$cube.rotate_cube($cube.AXIS.X, angle)
		2: #Z
			$cube.rotate_cube($cube.AXIS.Z, angle)
		1:
			set_rotation_buttons_enabled(true)
	
# Highlights a face (given by axis and level) with the current player's color.
# If reverse is true, resets all face's balls to neutral or owning player color (if any)
func highlight_face(axis, level, reverse = false):
	if current_state >= STATES.GAME_OVER:
		return
		
	var face
	var face_pivot
	match axis:
		0:	#X
			face = $cube.faces_x[level].balls
			face_pivot = $cube.faces_x[level].pivot
		1:	#Y
			face = $cube.faces_y[level].balls
			face_pivot = $cube.faces_y[level].pivot
		2:	#Z
			face = $cube.faces_z[level].balls
			face_pivot = $cube.faces_z[level].pivot
	
	print("\n\nHIGHLIGHT")
	printt("face ", axis, " level ", level, "face_pivot ", face_pivot)
	var c = 0
	for b in face:
		printt(str(c), b.name, b.global_transform.origin)
		if reverse:
			b.set_ball_to_noone_or_player()
			$cube/roll/yaw/face_pivot.hide()
		else:
			b.set_ball_highlighted(colors_players[current_state])
			$cube/roll/yaw/face_pivot.transform.origin = face_pivot
			$cube/roll/yaw/face_pivot.rotation = -$cube/roll.rotation
			$cube/roll/yaw/face_pivot.show()

# Highlights all balls of given ball's column with the current player's color.
# If reverse is true, resets all face's balls to neutral or owning player color (if any)
func highlight_y_column(ball, reverse = false):
	for i in range($cube.length):
		var pos = Vector3(ball.x_plane_id, i, ball.z_plane_id)
		if reverse:
			$cube.balls_slots[pos].set_ball_to_noone_or_player()
		else:
			if !$cube.balls_slots[pos].is_owned():
				$cube.balls_slots[pos].set_ball_highlighted(colors_players[current_state])
#			var top_ball_in_column = $cube.balls_slots[Vector3(ball.x_plane_id, 3, ball.z_plane_id)]
#			top_ball_in_column.set_ball_highlighted(ColorN("blue"))

func test_win():
	var winner_and_balls = $cube.determine_win()
	
	if winner_and_balls != null:
		winner = winner_and_balls[0]
		winning_balls = winner_and_balls[1]
		change_state(STATES.GAME_OVER)

func _on_spacing_slider_value_changed(value):
	$cube.set_spacing(value)
	update_gimbal_position_and_distance()

func update_gimbal_position_and_distance():
	$gimbal.global_transform.origin = $cube/roll/yaw/camera_pivot.global_transform.origin
	#$gimbal.set_distance_from_cube_size($cube.length, $cube.spacing)

func _on_back_button_pressed():
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://main_menu/main_menu.tscn")


func _on_RotatingFaces_ready_for_new_rotation():
	set_rotation_buttons_enabled(true)
	test_win()
