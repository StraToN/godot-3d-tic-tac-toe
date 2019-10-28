extends RuleBehaviour
class_name GravityBehaviour

onready var is_gravity = false
onready var click_started = false

# temporary balls created for column falldown animation in gravity rules
var animated_balls = []

func apply_click(ball, player, color):
	is_gravity = false
	var lowest = cube.get_lowest_in_column(ball)
	if lowest:
		click_started = true
		animate_ball_falldown_column(lowest, player, color)
		
func animate_ball_falldown_column(ball, player, color):
	get_tree().call_group("balls", "set_respond_to_inputs", false)
	cube.set_column_to_noone_or_player(ball)
	
	cube.acquired_ball = ball
	var animated_ball = cube.ball_scene.instance()
	animated_balls.append(animated_ball)
	cube.get_node("roll/yaw").add_child(animated_ball)
	animated_ball.set_respond_to_inputs(false)
	animated_ball.set_ball_player_color(player, color)
	var top_ball_in_column = cube.balls_slots[Vector3(ball.x_plane_id, 3, ball.z_plane_id)]
	animated_ball.global_transform = top_ball_in_column.global_transform.translated(Vector3(0, 5.0, 0))
	
	cube.get_node("roll/yaw/ball_falldown").interpolate_property(animated_ball, "global_transform", 
		animated_ball.global_transform, 
		ball.global_transform, 1.0, 
		Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	cube.get_node("roll/yaw/ball_falldown").start()

func _on_ball_falldown_tween_all_completed():
	if !animated_balls.empty():
		for instance in animated_balls:
			instance.queue_free()
		animated_balls.clear()
	
	if is_gravity:
		cube.apply_queued_ball_player_change()
	
	if click_started:
		emit_signal("click_applied", is_gravity)
		click_started = false
	is_gravity = false

func apply_gravity():
	is_gravity = true
	
	# for each column
	for colx in range(cube.length):
		for colz in range(cube.length):
			
			# for owned each ball in column, starting from level 1 instead of 0 because 0 is the floor
			var owned_balls_in_column = []
			for coly in range(cube.length):
				var tested_ball = cube.balls_slots[Vector3(colx, coly, colz)]
				if tested_ball.is_owned():
					owned_balls_in_column.append(tested_ball)
					
			for ball_i in range(owned_balls_in_column.size()):
				var ball = owned_balls_in_column[ball_i]
				var target_ball_pos_y = ball_i
				
				if ball.y_plane_id != target_ball_pos_y:
					var target_ball = cube.balls_slots[Vector3(colx, target_ball_pos_y, colz)]
					var player = ball.player
					var color_player = ball.color_player
					cube.queue_ball_player_change(target_ball, player, color_player)
					
					var animated_ball = cube.ball_scene.instance()
					animated_balls.append(animated_ball)
					cube.get_node("roll/yaw").add_child(animated_ball)
					animated_ball.name = "animated"
					animated_ball.set_respond_to_inputs(false)
					animated_ball.set_ball_player_color(player, color_player)
					animated_ball.transform = ball.transform
					
					cube.get_node("roll/yaw/ball_falldown").interpolate_property(animated_ball, 
							"global_transform", 
							animated_ball.global_transform, 
							target_ball.global_transform, 1.0, 
							Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
					
					ball.set_neutral()
	
	cube.get_node("roll/yaw/ball_falldown").start()
