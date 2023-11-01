extends Area2D


export(int) var damage = 7

export(float) var damage_again_time = 1.5
var timer = 0

var player = null

func _on_Spikes_body_entered(body):
	body.take_damage(damage)
	player = body

func _on_Spikes_body_exited(_body):
	player = null
	timer = 0

func _physics_process(delta):
	if player != null:
		timer += delta
		if timer >= damage_again_time:
			timer = 0
			player.take_damage(damage)
