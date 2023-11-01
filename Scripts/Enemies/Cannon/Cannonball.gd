extends Area2D

# We define damage, speed and direction
export (float) var speed = 10 * 24
var direction
var damage = 3

# Translate is used for movement, in a more crude way.
func _physics_process(delta):
	translate(direction * speed * delta)

# If it collides with the player it does damage.
func _on_Cannonball_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
