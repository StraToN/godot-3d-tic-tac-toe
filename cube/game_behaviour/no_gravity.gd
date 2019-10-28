extends RuleBehaviour
class_name NoGravityBehaviour

# This script is only active when no gravity rule is set.

func apply_click(ball, player, color):
	printt("Ball clicked: ", ball.get_name(), ball.x_plane_id, ball.y_plane_id, ball.z_plane_id)
	if !ball.is_owned():
		ball.set_ball_player_color(player, color)
		cube.acquired_ball = ball
		emit_signal("click_applied", false)
	else:
		print("Ball is already owned by player " + str(ball.get_owner()))
