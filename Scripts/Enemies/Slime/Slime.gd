extends KinematicBody2D



# speeds on the enemy
export(int) var move_speed = 1 * 21
var velocity = Vector2(0,0)
export(int) var direction = 1

# life
export(int) var life = 8

# Interaction variables when receiving hits from the player.
export(Vector2) var bump_force = Vector2(1*24, - 9*24)
export(Vector2) var knock_up_force = Vector2(0*24, - 10*24)
export(Vector2) var strong_hit_knock_back = Vector2(12*24, 0*24)

# Gravity, bump is when it is hit by the player's slide
var gravity 
var bump = false
var bump_direction = 1
var disable_gravity = false
func _ready():	
	# initial direction of movement
	$Body.scale.x = direction
	# enemie
	add_to_group("enemy")

# Apply gravity
func apply_gravity(delta):
	if !disable_gravity:		
		gravity = Global.gravity
		velocity.y += gravity * delta
	else:
		velocity.y = 0
# Move enemy
func move_enemy(_delta):
	var stop_on_slope = true if get_floor_velocity().x == 0 else false	
	var snap_vector = Vector2(0,24) if is_on_floor() and !bump else Vector2(0,0)

	
	velocity = move_and_slide_with_snap(velocity, snap_vector, Vector2.UP, stop_on_slope,4 , 1)
	if is_on_wall() and velocity.y == 0:
		direction *= -1
		$Body.scale.x = direction

# Apply horizontal movement	
func apply_movement(_delta):
	velocity.x = move_speed * direction

# Place the animation corresponding to the current state.
func play_animation(animation_name):
	$Body/Sprite.animation = animation_name


# VisibilityEnabler is a Node that helps you know when something enters the game screen or leaves it.
func _on_VisibilityEnabler2D_screen_entered():
	if $StateMachine.state != $StateMachine.states.death:
		$StateMachine.set_state($StateMachine.states.move)

# Damage control function
func take_damage(quantity, _node = null):
	life -= quantity
	if life > 0:
		$AnimationPlayer.play("DamageEffect")
		if !is_on_floor():
			bump = false
		if !bump:
			$StateMachine.set_state($StateMachine.states.hurt)
	else:
		$StateMachine.set_state($StateMachine.states.death)

# Bump effect starts,directions set and change the state
func initiate_bump(player, damage):
	if !$BumpCooldown.is_stopped():
		return
	if player.move_direction == 1:
		bump_direction = 1
	else:
		bump_direction = -1
	bump = true
	velocity.y = bump_force.y
	$BumpCooldown.start()
	$StateMachine.set_state($StateMachine.states.bump)
	take_damage(damage)

# Apply horizontal movement during bump.
func apply_bump():
	velocity.x = bump_force.x * bump_direction

#change things when finishing an animation.
func _on_Sprite_animation_finished():
	if $Body/Sprite.animation == 'die':
		queue_free()
	if $Body/Sprite.animation == 'hurt':
		$StateMachine.set_state($StateMachine.states.move)
	if $Body/Sprite.animation == 'attack':
		$StateMachine.set_state($StateMachine.states.move)

# Functions that are called by the player's attack.
func knock_up(extra_force = 0):
	velocity = knock_up_force
	velocity.y += extra_force
	bump = true

func medium_hit():
	velocity.x = 0
	velocity.y = -100
	
func strong_hit(node):
	var hit_direction = 1
	if node.global_position.x > self.global_position.x:
		hit_direction = -1
	velocity.x = strong_hit_knock_back.x * hit_direction
	velocity.y = strong_hit_knock_back.y
	bump = true

func knock_down(_node):
	velocity.x = 0
	velocity.y = 100

func air_attack_1():
	velocity.x = 0
	velocity.y = 0 


func air_attack_2():
	velocity.x = 0
	velocity.y = 0 

# Attack collision with the player.
func _on_AttackArea_body_entered(body):
	# For better interaction, we ensure that the player is not on a slide or attacking
	if ![body.get_node("StateMachine").states.slide, body.get_node("StateMachine").states.attack, body.get_node("StateMachine").states.air_attack].has(body.get_node("StateMachine").state):
		if self.is_on_floor() and $StateMachine.state == $StateMachine.states.move:
			$StateMachine.set_state($StateMachine.states.attack)
			body.take_damage(4)


# When the slime leaves the screen and is still alive, there is no need for it to move
func _on_VisibilityEnabler2D_screen_exited():
	if $StateMachine.state != $StateMachine.states.death and $StateMachine.state != $StateMachine.states.hurt:
		$StateMachine.set_state($StateMachine.states.idle)

# Changes the disable gravity variable.
func change_gravity(boolean):
	disable_gravity = boolean
