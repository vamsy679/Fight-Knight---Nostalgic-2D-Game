extends Area2D

# Heal 
export (int) var heal_amount = 5

func _on_Heal_body_entered(body):
	body.heal(heal_amount)
	$AnimationPlayer.play("collected")
