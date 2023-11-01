extends KinematicBody2D

# IMPORTANT TO ENABLE THE SYNCS_TO_PHYSIC OPTION in FallPlatform> Motion> Sync To Physics
# this helps the bodies move overhead.

var velocity = Vector2()
var is_triggered = false

export var reset_time : float = 0.8
onready var reset_position = global_position
func _ready():
	set_physics_process(false)

func _physics_process(delta):
	velocity.y += Global.gravity * delta
	position += velocity * delta

func collide_with(_collision : KinematicCollision2D, _collider: KinematicBody2D):
	if !is_triggered:
		is_triggered = true
		$AnimationPlayer.play("shake")
		velocity = Vector2.ZERO
		
func _on_ResetTimer_timeout():
	set_physics_process(false)
	yield(get_tree(),"physics_frame")
	var temp = collision_layer
	collision_layer = 0
	global_position = reset_position
	yield(get_tree(),"physics_frame")
	collision_layer = temp
	is_triggered = false

func _on_AnimationPlayer_animation_finished(_anim_name):
	set_physics_process(true)
	$ResetTimer.start(reset_time)
