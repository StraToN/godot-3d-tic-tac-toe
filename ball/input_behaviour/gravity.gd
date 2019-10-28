#extends "res://ball/input_behaviour/ball_input_behaviour.gd"
extends BallInputBehaviour

func _on_ball_mouse_entered():
	get_tree().call_group("game", "highlight_y_column", ball)
	#printt("Hovered ball position:", ball.x_plane_id, ball.y_plane_id, ball.z_plane_id)

func _on_ball_mouse_exited():
	ball.get_node("sphere").set_surface_material(0, ball.transparent_material)
	get_tree().call_group("game", "highlight_y_column", ball, true)
