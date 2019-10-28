tool
extends Spatial

const BASE_DISTANCE = 5.0
var distance = 20.0 setget set_distance
var camspeed = 0.02
var pressed = false

func _ready():
	pass

func update_distance():
	$yaw/Camera.transform.origin = Vector3(0,0,distance)
	
func set_distance_from_cube_size(cube_size, spacing):
		set_distance(cube_size + spacing * BASE_DISTANCE)
	
func set_distance(d):
	distance = d
	update_distance()


func _input(ev):
	if ev is InputEventMouseButton:
		if ev.is_pressed() and ev.button_index == BUTTON_RIGHT:
			pressed = true
		else:
			pressed = false
			
	if pressed and ev is InputEventMouseMotion:
		rotate_y(-camspeed * ev.relative.x)
		$yaw.rotate_x(-camspeed * ev.relative.y)
		$yaw.rotation_degrees.x = clamp($yaw.rotation_degrees.x, -80, 60)
