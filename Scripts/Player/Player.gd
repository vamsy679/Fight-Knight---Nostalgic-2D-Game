extends KinematicBody2D

signal grounded_updated(is_grounded)
const SLOPE_STOP = 64 # Ssliding on diagonal platforms
const PLATFORM_MASK_BIT = 1 #used to collide the character with platforms
const WALL_JUMP_OPPOSITE_FORCE = 10 * 24 # the strength of the X jump on the wall
var velocity = Vector2 () # Velocity is our character's speed

export (float) var move_speed = 9 * 24
export (float) var max_jump_height = 3.25 * 24
export (float) var min_jump_height = 0.8 * 24
export (float) var jump_duration = 0.5


export (int) var weak_hit_damage = 2.5 # Damage variables on enemies.
export (int) var medium_hit_damage = 4
export (int) var strong_hit_damage = 5
export (int) var slide_damage = 1
var move_direction = Vector2 () # player direction

# Temporary jump control variable
var temporary_move_direction
# These values ​​are defined in _ready () based on a formula.
var gravity
var max_jump_velocity
var min_jump_velocity

# Variables related to blows in the air, we disable gravity to give a better feeling
# And we also enable and disable airborne attack to prevent abuse
var can_do_air_attack = true
var gravity_disabled = false
# Snap_vector is a vector to "stick" the character to the floor, it will be seen below
var snap_vector = Vector2 (0,0)

# Control variables for ground detection and whether you are jumping
var is_grounded
var is_jumping = false

# We detect the direction of the wall
var wall_direction = 1

# Player's life
var life = 35

# Speed ​​we can walk while attacking, we will switch to a little momentum
# During the third animation

var movement_speed_while_attack = 0 * 37

# Slip speed, we put a higher value because we want q for a speed gain and then a brake
var slide_speed = 40 * 24
# We define gravity based on our jump and jump duration, making it dynamic
# pow refers to potentiation
# sqrt is square root
func _ready():
	# We store the severity variable in a singleton (autoload) to be accessed from other places as well.
	Global.set_gravity(max_jump_height, jump_duration)
	gravity = Global.gravity
	max_jump_velocity = -sqrt(2 * gravity * max_jump_height)
	min_jump_velocity = -sqrt(2 * gravity * min_jump_height)
	
	# We control our lifebar based on the player's life.
	$HUD/Control/Lifebar/LifeBar.max_value = life
	$HUD/Control/Lifebar/LifeBar.value = life
func _apply_movement():
# Inputs capture method (movement, jump, etc.)

# If we are not moving and the movement speed is less than the slide value, stop the player.	
	if move_direction == 0 and abs(velocity.x) < SLOPE_STOP:
		velocity.x = 0
# We say that if the ground speed is 0, we should stop sliding, if not, continue. This is good for mobile platforms.
	var stop_on_slope = true if get_floor_velocity().x == 0 else false	
# We updated the value of being on the floor or not and moved on to the camera.
	var was_grounded = is_on_floor()
	
	_check_is_on_slope()
# The move_and_slide_with_snap function is a standard function, it is suitable for platforms
# and helps in detecting moving platforms, glides and others.
# It can be checked out at: https://godot-es-docs.readthedocs.io/en/latest/tutorials/physics/using_kinematic_body_2d.html
	velocity = move_and_slide_with_snap(velocity, snap_vector, Vector2.UP, stop_on_slope,4 , 1)
# If we were on the ground and we are not jumping, start the coyote timer.
# This timer helps the game feel of the game, giving the player a short break after jumping off a platform.
	if !is_on_floor() and was_grounded and !is_jumping:
		$CoyoteTimer.start()
		
	
	# This repetition informs the colliders obtained in the last move_and_slide_with_snap
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		
	# We check if this collider has the 'collide_with' method
		if collision.collider.has_method("collide_with"):
			collision.collider.collide_with(collision, self)
			

# sliding on the ground, to check a 'ramp', normal of the floor and rotate the character to adjust.
		if $StateMachine.state == $StateMachine.states.slide:
			var normal = collision.normal
			var angleDelta = normal.angle() - ($BodyPivot.rotation - PI * .5)
			$BodyPivot.rotation = angleDelta + $BodyPivot.rotation
			
	is_grounded = is_on_floor()
	
	if was_grounded == null or is_grounded != was_grounded:
		emit_signal("grounded_updated", is_grounded)
	

# With some parameters and checks, we define if it is on the floor.
# If not jumping, our platform BIT is active we can say that it is on the ground.
	is_grounded = !is_jumping and get_collision_mask_bit(PLATFORM_MASK_BIT) and _check_is_grounded($RayCasts)
	
	if is_grounded:
		can_do_air_attack = true

# change the value to make the jump.
	snap_vector = Vector2(0,24) if is_grounded else Vector2(0,0)
	print(_check_is_grounded($RayCasts))
# We apply gravity
func _apply_gravity(delta):
	if !gravity_disabled:
		velocity.y += gravity * delta
	else:
		velocity.y = 0
# we're not jumping anymore
	if is_jumping and velocity.y >= 0:
		is_jumping = false
		
func _update_move_direction():
	if !gravity_disabled:
		move_direction = - int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))

func _handle_move_input():
# to know the direction of movement, the Input returns a boolean, transform the direction and also change the direction of the body.
	move_direction = - int(Input.is_action_pressed("move_left")) + int(Input.is_action_pressed("move_right"))
	if !$WallJumpControlCooldown.is_stopped():
		move_direction = temporary_move_direction
# If we are during the slide, we will apply a slightly different speed
	if !$SlideDuration.is_stopped():
		slide()	
	elif $StateMachine.state == $StateMachine.states.attack or $StateMachine.state == $StateMachine.states.air_attack :
		velocity.x =  lerp(velocity.x, movement_speed_while_attack * move_direction, _get_h_weight())
	else:
		velocity.x =  lerp(velocity.x, move_speed * move_direction, _get_h_weight())
	if gravity_disabled:
		velocity.x = 0
	if move_direction != 0:
		$BodyPivot.scale.x = move_direction

func _handle_wall_slide_sticking():
	if move_direction != 0 and move_direction != wall_direction:
		if $WallSlimeStickyTimer.is_stopped():
			$WallSlimeStickyTimer.start()
	else:
		$WallSlimeStickyTimer.stop()
# Controls the speed value of X 
func _get_h_weight():
	if is_on_floor():
		return 1
	else:
		if move_direction == 0:
			return 0.5
		elif move_direction == sign(velocity.x) and abs(velocity.x) > move_speed:
			return 0.2
		else:
			return 0.8
			

# Checks raycasts for collision
func _check_is_grounded(raycasts):
	for raycast in raycasts.get_children():
		if raycast.is_colliding():
			return true
			
	return false

func _check_is_on_slope():
		
	pass

# It is a collision area, if a body leaves it, that is, if we go down the platform, return the bit to the on state.
func _on_CheckPlatformCollision_body_exited(_body):
	set_collision_mask_bit(PLATFORM_MASK_BIT, true)

# We run the animation based on the current state.
func play_animation(animation_name):	
	$BodyPivot/sprite.flip_h = true if animation_name == 'wall_slide' else false
	$BodyPivot/sprite.play(animation_name)
	if animation_name == 'wall_slide':
		animation_name = 'Wall Slide'
	if animation_name == 'wall_jump':
		animation_name = 'jump'
		
	$State.text = animation_name	


# Update the direction of the wall, check which side we are on and whether it is possible to choose the side.
func _update_wall_direction():
	var is_near_wall_left = _check_is_valid_wall($WallRaycasts/LeftRaycast)
	var is_near_wall_right = _check_is_valid_wall($WallRaycasts/RightRaycast)
	
	if is_near_wall_left and is_near_wall_right:
		wall_direction = move_direction
	else:
		wall_direction = -int(is_near_wall_left) + int(is_near_wall_right)

func _check_is_valid_wall(wall_raycasts):
	for raycast in wall_raycasts.get_children():
		if raycast.is_colliding():
			# DOT is a vector operation that returns a scalar, it is useful to check if we are looking in a given direction.
			# For more information about, check here: https://docs.godotengine.org/pt_BR/stable/tutorials/math/vector_math.html#dot-product
			#acos returns the cosine arc.
			var dot = acos(Vector2.UP.dot(raycast.get_collision_normal()))
			if dot > PI * 0.35 and dot < PI * 0.55:
				return dot
	return false	

# We apply gravity if we are on a wall slide
# 24 is the tile size, so with the value we want 1 tile to fall.
# This is if we do not press the down key, which accelerates the fall.
func _gravity_wall_slide():
	var max_velocity = 1 * 24 if !Input.is_action_pressed("down") else 6 * 24
	# min returns the minimum between 2 values, that is, the lowest value
	velocity.y = min(velocity.y, max_velocity)

# We calculate the direction of the wall jump
# If the player is not looking in one direction or looking at the wall,
# make a null jump. If you're looking in the opposite direction, make a jump
# normal and temporarily prevent it from changing direction
func wall_jump():
	var wall_jump_velocity = Vector2(WALL_JUMP_OPPOSITE_FORCE, max_jump_velocity)
	
	if $WallJumpControlCooldown.is_stopped():
		$WallJumpControlCooldown.start()
	temporary_move_direction = -wall_direction
	wall_jump_velocity.x *= -wall_direction
	velocity = wall_jump_velocity

# jump
func jump():
	get_node("CoyoteTimer").stop()
	velocity.y = max_jump_velocity
	snap_vector = Vector2()
	is_jumping = true

# slide 
func slide():
	velocity.x *= 0.89
	
	# stop sliding "up".
	if velocity.y < 0:
		velocity.y = 0
	if $SlideDuration.is_stopped():
		$SlideDuration.start()

# We place a specific collision based on the animation and state, alternating when necessary.
func _set_custom_collision_shape(shape_type: String = ""):
	match shape_type:
		"slide":
			$CollisionShape2D.shape.extents = Vector2(12,6)
			$CollisionShape2D.position = Vector2(0,10)
		"wall_jump":
			$CollisionShape2D.shape.extents = Vector2(6, 9)
			$CollisionShape2D.position = Vector2(0,1)			
		"crouch":
			$CollisionShape2D.shape.extents = Vector2(6, 10)
			$CollisionShape2D.position = Vector2(0,6)					
		"death":
			yield(get_tree(),"idle_frame")
			$CollisionShape2D.disabled = true
		_:
			$CollisionShape2D.shape.extents = Vector2(6, 15)
			$CollisionShape2D.position = Vector2(0,1)

	

func take_damage(quantity):	# controls the damage received by the player.
	life -= quantity
	$HUD/Control/Lifebar/LifeBar.value = life
	if life > 0:
		$TakeDamageEffect.play("effect")
	else:
		$StateMachine.set_state($StateMachine.states.death)


func _on_PlayerAttackCollision_body_entered(body): # We check the collisions with the player's attack
	if body.has_method("destroy"):
		body.destroy()
	elif body.is_in_group("enemy"):
		
# We check which attack we are in and apply different effects.
# call_group calls any existing group, all nodes that are
# in this group they will call the method presented as the second argument.
		if $StateMachine.state == $StateMachine.states.attack:
			match $StateMachine.hit_count:
				0:
					body.take_damage(weak_hit_damage, self)
					get_tree().call_group("camera","shake", 0.2, 0.2)
					if Input.is_action_pressed("down"):
							
						body.knock_up(-5 * 24)
#					else:
#						body.knock_up()
				1:
					body.take_damage(medium_hit_damage, self)
					get_tree().call_group("camera","shake", 0.4, 0.2)
					if body.has_method("medium_hit"):
						body.medium_hit()
				2:
					body.take_damage(strong_hit_damage, self)
					get_tree().call_group("camera","shake", 0.6, 0.4)
					if body.has_method("strong_hit"):
						body.strong_hit(self)
					
		elif $StateMachine.state == $StateMachine.states.air_attack:
			can_do_air_attack = false
			match $StateMachine.hit_count:
				0:
					body.take_damage(weak_hit_damage, self)
					get_tree().call_group("camera","shake", 0.2, 0.2)
					if body.has_method("change_gravity"):
						body.change_gravity(true)
					if body.has_method("air_attack_1"):
						body.air_attack_1()
				1:
					body.take_damage(medium_hit_damage, self)
					get_tree().call_group("camera","shake", 0.4, 0.2)
					if body.has_method("change_gravity"):
						body.change_gravity(true)
					if body.has_method("air_attack_2"):
						body.air_attack_2()
				2:
					body.take_damage(strong_hit_damage, self)
					get_tree().call_group("camera","shake", 0.8, 0.4)
					if body.has_method("knock_down"):
						body.knock_down(self)
			
			gravity_disabled = true						


func _on_SlideDamage_body_entered(body): # damage to the enemy.
	if body.is_in_group("enemy"):
		if body.has_method("initiate_bump"):
			body.initiate_bump(self, slide_damage)
		

func _set_slide_collision_damage(boolean): # Enable / disable the slide collider
	$SlideDamage/CollisionShape2D.disabled = boolean


func heal(quantity): # healing function
	life += quantity
	if life > $HUD/Control/Lifebar/LifeBar.max_value:
		life =  $HUD/Control/Lifebar/LifeBar.max_value
	$HUD/Control/Lifebar/LifeBar.value = life

func end_level_state():
	$StateMachine.set_state($StateMachine.states.change_level)
