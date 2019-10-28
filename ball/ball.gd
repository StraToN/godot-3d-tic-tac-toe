tool
extends StaticBody

var player 
onready var owned = false
var color_player = Color(0,0,0,1)
var color_outline = Color(0,0,0,1)

var normal_material = ResourceLoader.load("res://materials/ball_white.tres").duplicate()
var transparent_material = ResourceLoader.load("res://materials/ball_white_transparent.tres").duplicate()
# warning-ignore:unused_class_variable
var outline_material = ResourceLoader.load("res://materials/ball_outlined.tres").duplicate()

var x_plane_id : int setget set_x_plane_id,get_x_plane_id
var y_plane_id : int setget set_y_plane_id,get_y_plane_id
var z_plane_id : int setget set_z_plane_id,get_z_plane_id

# True if inputs on balls have to be disabled (clicks and hovers)
onready var respond_to_inputs = true

# Node used for input behaviour, depending on active game rules
var input_behaviour_node

signal hovered
signal unhovered

func _ready():
	add_to_group("balls")
	
	if game_parameters.game_rules["gravity"]:
		input_behaviour_node = $InputBehaviour/Gravity
		$sphere.set_surface_material(0, transparent_material)
	else:
		input_behaviour_node = $InputBehaviour/NoGravity
		$sphere.set_surface_material(0, normal_material)

func is_owned():
	return owned

func set_x_plane_id(xplane):
	x_plane_id = xplane

func get_x_plane_id():
	return x_plane_id

func set_y_plane_id(yplane):
	y_plane_id = yplane

func get_y_plane_id():
	return y_plane_id

func set_z_plane_id(zplane):
	z_plane_id = zplane

func get_z_plane_id():
	return z_plane_id

func _on_ball_mouse_entered():
	if !respond_to_inputs:
		return 
		
	print(get_canonical_position())
	
	input_behaviour_node._on_ball_mouse_entered()
	emit_signal("hovered")
	
func _on_ball_mouse_exited():
	if !respond_to_inputs:
		return 
	
	input_behaviour_node._on_ball_mouse_exited()
	emit_signal("unhovered")


# warning-ignore:unused_argument
# warning-ignore:unused_argument
# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_ball_input_event( camera, event, click_position, click_normal, shape_idx ):
	if !respond_to_inputs:
		return 
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
		get_tree().call_group("game", "ball_clicked", self)

func set_color_outline(color):
	color_outline = color

func set_ball_player_color(player_to_set, color):
	color_player = color
	player = player_to_set
	normal_material.albedo_color = color_player
	$sphere.set_surface_material(0, normal_material)
	owned = true

func set_ball_highlighted(color):
	normal_material.albedo_color = color
	$sphere.set_surface_material(0, normal_material)
	
func set_ball_to_noone_or_player():
	if player != null:
		set_ball_player_color(player, color_player)
	else: # set neutral
		set_neutral()

func set_neutral():
	color_player = Color(1,1,1,1)
	player = null
	normal_material.albedo_color = color_player
	if game_parameters.game_rules["gravity"]:
		$sphere.set_surface_material(0, transparent_material)
	else:
		$sphere.set_surface_material(0, normal_material)
	owned = false

func set_ball_transparent(alpha = 0.2, immediate = false):
	transparent_material = normal_material.duplicate()
	transparent_material.flags_transparent = true
	$sphere.set_surface_material(0, transparent_material)
	
	if immediate:
		set_ball_transparency_alpha(alpha)
	else:
		$tween.interpolate_method(self, "set_ball_transparency_alpha", 1.0, alpha, 2.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$tween.start()

# (private) Called by set_ball_transparent()
func set_ball_transparency_alpha(alpha):
	transparent_material.albedo_color.a = alpha
	
func set_respond_to_inputs(shall_respond):
	respond_to_inputs = shall_respond

# Return ball position set between (0,0,0) and (3,3,3)
func get_canonical_position():
	return Vector3(x_plane_id, y_plane_id, z_plane_id)
	
