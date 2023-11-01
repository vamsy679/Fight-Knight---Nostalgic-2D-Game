extends Camera2D

# Change factor
const LOOK_AHEAD_FACTOR = 0.2
# Facing is the variable q that indicates the direction to be looked at.
var facing = 0
# onready var is a type of variable that will only have its value when starting the script, good for getting nodes or function values.
onready var prev_camera_pos = get_camera_position ()

# Variables to validate the margin that will pull the camera.
export (float) var camera_drag_margin_top = 0.5
export (float) var wall_slide_camera_drag_margin_top = 0.2

# Variables that help to shake the screen.
var intensity
var rot_ang = 0
var shake_camera = false
var offset_val = Vector2 ()

# We put it in the camera group in case someone needs to make the screen shake
func _ready():
	add_to_group("camera")
# The process is similar to physics_process, but it is recommended for things that depend only on the machine, without having a fixed cyclic value.
func _process(_delta):
	_check_facing()
	prev_camera_pos = get_camera_position()
	# If we must shake the screen, move its offset.
	if shake_camera:
		rot_ang += PI / 3
		offset = Vector2(sin(rot_ang), cos(rot_ang)) * intensity + offset_val
# Check the correct side, sign returns the signal. Then, we change the position of the camera.
func _check_facing():
	var new_facing = sign(get_camera_position().x - prev_camera_pos.x)
	# If it is not the same direction, switch sides.
	if new_facing != 0 and facing != new_facing and owner.move_direction == new_facing:
		facing = new_facing
		# get_viewport_rect (). size.x returns the width of the screen
		var target_offset = get_viewport_rect().size.x * LOOK_AHEAD_FACTOR * facing
		#position.x = target_offset
		# The Tween node is a great node for making transitions from non-absolute values.
		$ShiftTween.interpolate_property(
			self, #Who
			"position:x", # Which property
			position.x, # Start
			target_offset, #Final
			1.0, # Duration
			Tween.TRANS_SINE, #Transition type
			Tween.EASE_OUT, #Ease of animation
			0) #Delay to start
			# Once the tween is defined, we must start it
		$ShiftTween.start()
# Signal connected to the player, if you have not slid the camera upwards.
func _on_Player_grounded_updated(is_grounded):
	drag_margin_v_enabled = !is_grounded

# Signal connected to the state machine. We change the margin value when we need it (in this case, when we are in the wall slide state as previously mentioned).
func _on_StateMachine_switch_v_margin_mode(mode: bool):
	if mode == true:
		drag_margin_top = wall_slide_camera_drag_margin_top
	else:
		drag_margin_top = camera_drag_margin_top
	drag_margin_v_enabled = mode

# Function that starts shaking, setting intensity, duration and everything
func shake(intensity_shake, duration_shake):
	shake_camera = true
	offset_val = offset
	self.intensity = intensity_shake
	var _timer = get_tree().create_timer(duration_shake).connect("timeout", self, "_on_timeout")
	
# Stop shaking
func _on_timeout():
	offset = offset_val
	get_tree().call_group("MoveCamera", "move_camera")
	shake_camera = false
