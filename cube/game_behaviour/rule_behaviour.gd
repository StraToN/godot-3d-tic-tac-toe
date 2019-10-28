extends Node
class_name RuleBehaviour

# warning-ignore:unused_signal
signal click_applied(is_gravity)

# warning-ignore:unused_class_variable
onready var cube = get_tree().get_root().find_node("cube", true, false)

# warning-ignore:unused_argument
# warning-ignore:unused_argument
# warning-ignore:unused_argument
func apply_click(ball, player, color):
	pass
