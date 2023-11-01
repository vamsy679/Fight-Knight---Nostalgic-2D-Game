extends Node2D

# IMPORTANT TO ENABLE THE SYNCS_TO_PHYSIC OPTION in MovingPlatform / Platform> Motion> Sync To Physics
# this helps the bodies move overhead.
const IDLE_DURATION = 1.0

var follow = Vector2.ZERO

# 6 is the number of tiles we want to move
export var move_to = Vector2.RIGHT * 6
export var speed = 3.0
func _ready():
	_init_tween()

func _init_tween():
	# Again based on the size of the tileset.
	move_to *= 24
	var duration = move_to.length() / float(speed * 24)
	$MovePlatform.interpolate_property(
		self, # Who
		"follow", # What
		Vector2.ZERO, # Top
		move_to, # End
		duration, # Duration
		Tween.TRANS_LINEAR, # Interpolation type
		Tween.EASE_IN_OUT, # Ease type, in this case it makes no difference because it is linear
		IDLE_DURATION # Delay to start
	)

	$MovePlatform.interpolate_property(
		self, # Who
		"follow", # What
		move_to, # Inicio
		Vector2.ZERO, # End
		duration, # Duration
		Tween.TRANS_LINEAR, # Interpolation type
		Tween.EASE_IN_OUT, # Ease type, in this case it makes no difference because it is linear
		duration + IDLE_DURATION # Delay to start, in this case we add it because we want it to start only after reaching the other side	
		)
	$MovePlatform.start()
	
func _physics_process(_delta):
	# Moves the platform with a Linear interpolation smoothly, the last value is a value between 0 and 1 and is like a step to complete.
	$Platform.position = $Platform.position.linear_interpolate(follow, 0.075)


