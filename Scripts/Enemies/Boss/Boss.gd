extends KinematicBody2D

# signal passed after the boss's death to activate portal.
signal enable_end_level

# Packedscene to catch The boss's projectile.
export (PackedScene) var bossprojectilscene

# store the player in a variable for checks.
var player = null

# Limit of shots.
export (int) var max_shoots = 3
var number_of_shoots = 0

# Minimum and maximum duration of the flying attack
export(int) var min_fly_attack_duration = 5
export(int) var max_fly_attack_duration = 8

# Flying attack control variables.
var fly_attack_duration
var fly_attack_count_timer = 0
var fly_attack_direction = Vector2()
export(float) var fly_attack_speed = 14 * 25

# Contact damage
var contact_damage = 3

# Boss life
export(int) var life = 135


export(int) var damage_again_timer = 2


var damage_body = null
func _ready():
	
	$ContactDamageAgain.wait_time = damage_again_timer
	$Body.scale.x = -1
	add_to_group("enemy")
	$CanvasLayer/Lifebar/LifebarCount.max_value = life
	$CanvasLayer/Lifebar/LifebarCount.value = life


func take_damage(quantity, _node = null):
	life -= quantity
	$CanvasLayer/Lifebar/LifebarCount.value = life
	if life > 0:
		$AnimationPlayer.play("TakeDamageEffect")
	else:
		$CollisionShape2D.queue_free()
		$StateMachine.set_state($StateMachine.states.death)


func play_animation(animation_name):
	$Body/Sprite.animation = animation_name


func _on_Sprite_animation_finished():
	if $Body/Sprite.animation == 'idle':
		decide_next_attack()
	elif $Body/Sprite.animation == 'attack_1':
		if number_of_shoots < max_shoots:
			number_of_shoots += 1			
			$Body.scale.x = 1 if player.global_position.x > self.global_position.x else -1
		else:
			number_of_shoots = 0
			$StateMachine.set_state($StateMachine.states.idle)
	elif $Body/Sprite.animation == 'prepare_attack_2':
		play_animation('attack_2')
		$StateMachine.set_state($StateMachine.states.attack_2)
	elif $Body/Sprite.animation == 'death':
		emit_signal("enable_end_level")
		queue_free()

# When arrive at the determined frame, do a certain action,
func _on_Sprite_frame_changed():
	if $Body/Sprite.animation == 'attack_1':
		if $Body/Sprite.frame == 7:
			shoot()

# When entering the activation area, start the boss and place it in idle.
func _on_TriggerArea_body_entered(body):
	player = body
	$AnimationPlayer.play("Initiate")
	$StateMachine.set_state($StateMachine.states.idle)

# randomize () to shuffle the seeds.
func decide_next_attack():
	randomize()
	var next_attack = randf()
	if next_attack >= 0.5:
		attack_1()
	else:
		attack_2()

# Attack one, it's the shooting attack.
func attack_1():
	number_of_shoots += 1	
	$Body.scale.x = 1 if player.global_position.x > self.global_position.x else -1
	$StateMachine.set_state($StateMachine.states.attack_1)

# Attack two, this is the flight attack
func attack_2():
	randomize()
	fly_attack_duration =  rand_range(min_fly_attack_duration, max_fly_attack_duration)
	$Body.scale.x = 1 if player.global_position.x > self.global_position.x else -1
	fly_attack_direction.x = $Body.scale.x
	$StateMachine.set_state($StateMachine.states.pre_attack_2)

# Take the shot.
func shoot():
	var bossprojectil = bossprojectilscene.instance()
	bossprojectil.global_position = $Body/Shootpos.global_position
	bossprojectil.direction.x = $Body.scale.x
	bossprojectil.boss = self
	get_parent().add_child(bossprojectil)

# Healing function, the projectile fired upon hitting the player heals the boss for an amount.
func heal(quantity):
	life += quantity
	if life > $CanvasLayer/Lifebar/LifebarCount.max_value:
		life =  $CanvasLayer/Lifebar/LifebarCount.max_value
	$CanvasLayer/Lifebar/LifebarCount.value = life

# Performs the processing of the attack 2. When the specified time is reached, it ends.
func do_attack_2(delta):
	fly_attack_count_timer += delta
	if fly_attack_count_timer >= fly_attack_duration:
		$StateMachine.set_state($StateMachine.states.idle)
		return
	var _speed =	move_and_slide(fly_attack_speed * fly_attack_direction, Vector2.UP)
	if is_on_wall():
		fly_attack_direction.x *= -1
		$Body.scale.x = fly_attack_direction.x

# When the player collides, have him take damage.
func _on_DamagePlayer_body_entered(body):
	body.take_damage(contact_damage)
	damage_body =  body
	$ContactDamageAgain.start()

# If the player leaves the collision area, there is no need for him to take repeated damage.
func _on_DamagePlayer_body_exited(_body):
	damage_body =  null
	$ContactDamageAgain.stop()

# If the player is still within the collision area, damage the player.
func _on_ContactDamageAgain_timeout():
	if damage_body != null:
		damage_body.take_damage(contact_damage)
		$ContactDamageAgain.start()
