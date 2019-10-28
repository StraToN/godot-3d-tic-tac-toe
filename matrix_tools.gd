extends Node

#onready var matrix = [  
#				[ 1, 2, 3, 4 ],
#				[ 5, 6, 7, 8 ],
#				[ 9, 10, 11, 12 ],
#				[ 13, 14, 15, 16 ]]
#onready var matrix = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 ]

#func _ready():
#	print("\n", 1, "\n", matrix)
#	var tr = matrix_rotate(matrix.duplicate(), 90)
#	print(tr)
#
#	print("\n", 2, "\n", matrix)
#	tr = matrix_rotate(matrix.duplicate(), -90)
#	print(tr)
#
#	print("\n", 3, "\n", matrix)
#	tr = matrix_rotate(matrix.duplicate(), -360 - 90)
#	print(tr)
	
# Rotates the rings of given matrix by given angle.
# angle must be a multiple of 90, can be negative
static func matrix_rotate(matrix : Array, angle) -> Array:
	assert(angle % 90 == 0)
	var quarter_turns = angle / 90
	var remaining_turns = quarter_turns % 4
	
	if remaining_turns < 0:
		remaining_turns = 4 + remaining_turns
	
	var rotated = matrix.duplicate(true)
	for i in range(remaining_turns):
		rotated = matrix_rotate_90(rotated)
	
	return rotated

# Rotates the rings of given matrix
static func matrix_rotate_90(matrix : Array) -> Array:
	var rotated = matrix.duplicate(true)
	for i in range(rotated.size()):
		for j in range(i + 1, rotated.size()):
			var tmp = rotated[i][j]
			rotated[i][j] = rotated[j][i]
			rotated[j][i] = tmp
	
	for i in range(rotated.size()):
		var j = 0
		while j < (rotated.size() - 1 - j):
			var tmp = rotated[i][j]
			rotated[i][j] = rotated[i][rotated.size() - 1 - j]
			rotated[i][rotated.size() - 1 - j] = tmp
			j += 1
	return rotated
