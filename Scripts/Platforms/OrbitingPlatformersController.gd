tool
#Tool refers to enabling the code by the editor, good for real-time views.
extends Node2D


export var radius = Vector2.ONE * 256
# rotation duration
export var rotation_duration: = 4.0

var platforms = []
var orbit_angle_offset = 0
var prev_child_count = 0
func _physics_process(delta):
	if prev_child_count != get_child_count():
		prev_child_count = get_child_count()
		_find_platforms()
	#mark the circle around, 2 * PI for an entire circle and divide by the duration to have the full time
	orbit_angle_offset += 2 * PI * delta / float(rotation_duration)
	# Creates a loop with wrapf from -PI to PI
	orbit_angle_offset = wrapf(orbit_angle_offset, -PI, PI)	
	update_platform()
	
# Updates the position of the platform.
func update_platform():
	#Check if the platform array size is not 0
	if platforms.size () != 0:
		# Platform spacing by array size
		var spacing = 2 * PI / float(platforms.size())
		# For each platform, add a new position in the outside circle.
		for i in platforms.size():
			
			var new_position = Vector2()
			
			new_position.x = cos(spacing * i + orbit_angle_offset) * radius.x
			new_position.y = sin(spacing * i + orbit_angle_offset) * radius.y
			
			platforms[i].position = new_position
			
# Populated the platform array with members of the platforms group
func _find_platforms():
	platforms = []
	for child in get_children():
		if child.is_in_group("platforms"):
			platforms.append(child)
