extends Spatial

func _ready():
	randomize()
	
	game_parameters.game_rules["gravity"] = false

	$cube.init_balls()
	get_tree().call_group("balls", "set_respond_to_inputs", false)
	
	# warning-ignore:return_value_discarded
	get_tree().get_current_scene().find_node("cube_size").connect(
		"value_changed", self, "_on_cube_size_value_changed")
		
	var gravity_checkbox = get_tree().get_current_scene().find_node("gravity")
	gravity_checkbox.connect("pressed", self, "set_option", ["gravity", gravity_checkbox])
	
	var rotations_checkbox = get_tree().get_current_scene().find_node("rotations")
	rotations_checkbox.connect("pressed", self, "set_option", ["rotations", rotations_checkbox])
	
	var cube_rotations_checkbox = get_tree().get_current_scene().find_node("cube_rotations")
	cube_rotations_checkbox.connect("pressed", self, "set_option", ["cube_rotations", cube_rotations_checkbox])
	
# warning-ignore:return_value_discarded
	get_tree().get_current_scene().find_node("back").connect(
		"pressed", self, "_on_back_pressed")
		
# warning-ignore:return_value_discarded
	get_tree().get_current_scene().find_node("start").connect(
		"pressed", self, "_on_start_pressed")

func _on_autorotate_timer_timeout():
	var axis = randi() % 3
	var level = randi() % int($cube.length)
	var rotation_way = randi() % 2 - 1 # -1 or 1
	$cube.rotate_plane(axis, level, rotation_way * PI/2)
	$autorotate_timer.start()

func _on_single_player_pressed():
	$CanvasLayer/main_menu_screens/main_menu.hide()
	$CanvasLayer/main_menu_screens/single_player_menu.show()
	
func _on_multiplayer_pressed():
	pass

func _on_quit_pressed():
	get_tree().quit()

### SINGLE PLAYER
func _on_start_pressed():
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://game.tscn")

func _on_back_pressed():
	$CanvasLayer/main_menu_screens/single_player_menu.hide()
	$CanvasLayer/main_menu_screens/main_menu.show()

func _on_cube_size_value_changed(value):
	$autorotate_timer.stop()
	$cube.set_length(value)
	game_parameters.cube_size = int(value)
	$autorotate_timer.start()
	get_tree().call_group("balls", "set_respond_to_inputs", false)
	
	match int(value):
		3:
			$Camera/Tween.interpolate_property($Camera, "global_transform", 
					$Camera.global_transform, $"3x3_camera".global_transform,
					2.0, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
			$Camera/Tween.start()
		4:
			$Camera/Tween.interpolate_property($Camera, "global_transform", 
					$Camera.global_transform, $"4x4_camera".global_transform,
					2.0, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
			$Camera/Tween.start()
		5:
			$Camera/Tween.interpolate_property($Camera, "global_transform", 
					$Camera.global_transform, $"5x5_camera".global_transform,
					2.0, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
			$Camera/Tween.start()

func set_option(arg_name, element):
	game_parameters.game_rules[arg_name] = element.pressed
	
	if arg_name == "cube_rotations":
		var gravity_checkbox = get_tree().get_current_scene().find_node("gravity")
		gravity_checkbox.pressed = element.pressed
		set_option("gravity", gravity_checkbox)
	
	if arg_name == "rotations":
		$cube.activate_rotations(element.pressed)
