extends KinematicBody2D


export (Vector2) var shoot_direction = Vector2(-1,0)
export (PackedScene) var cannonballscene
export (float) var attack_interval = 1.5


func _ready():
	$AttackInterval.wait_time = attack_interval


func _on_VisibilityNotifier2D_screen_entered():
	$AttackInterval.start()


func _on_AttackInterval_timeout():
	$Body/AnimatedSprite.frame = 0
	$Body/AnimatedSprite.play("attack")


func _on_VisibilityNotifier2D_screen_exited():
	$AttackInterval.stop()


func _on_AnimatedSprite_frame_changed():
	if $Body/AnimatedSprite.frame == 4:
		shoot()


func shoot():
	var cannonball = cannonballscene.instance()
	cannonball.global_position = $Body/CannonballPosition.global_position
	cannonball.direction = shoot_direction
	get_parent().add_child(cannonball)
