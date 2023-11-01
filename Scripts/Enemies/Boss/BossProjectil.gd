extends Area2D

# We define damage, speed and direction
export (float) var speed = 16 * 24
var direction = Vector2()
var damage = 3

# We store the boss variable.
var boss
export (int) var heal_amount = 5

# Translate is used for movement, in a more crude and direct way.
func _physics_process(delta):
	translate(direction * speed * delta)

# When interacting, if you are the player, do damage and heal the boss.
func _on_BossProjectil_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
		boss.heal(heal_amount)
	queue_free()
