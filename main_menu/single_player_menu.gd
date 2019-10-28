extends Control

onready var gravity_checkbox = $rules_panel/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer2/gravity
onready var rotations_checkbox = $rules_panel/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer3/rotations
onready var cube_rotations = $rules_panel/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer4/cube_rotations

func _ready():
	if game_parameters.game_rules["gravity"]:
		gravity_checkbox.pressed = true
	
	if game_parameters.game_rules["rotations"]:
		rotations_checkbox.pressed = true
	
	if game_parameters.game_rules["cube_rotations"]:
		cube_rotations.pressed = true
		gravity_checkbox.pressed = true
