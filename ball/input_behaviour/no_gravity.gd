extends BallInputBehaviour

func _on_ball_mouse_entered():
	
	if !ball.owned:
		ball.outline_material.albedo_color = ball.color_outline
		ball.get_node("sphere").set_surface_material(0, ball.outline_material)
	
func _on_ball_mouse_exited():
	ball.get_node("sphere").set_surface_material(0, ball.normal_material)
