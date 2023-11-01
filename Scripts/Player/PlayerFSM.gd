extends StateMachine

signal changed_state(state)


signal switch_v_margin_mode(mode)

var hit_count = 0
var max_hit = 2
var hit = false

func _ready():
	#Added existing states in the states dictionary.
	add_state("idle")
	add_state("move")
	add_state("jump")
	add_state("fall")
	add_state("wallSlide")
	add_state("attack")
	add_state("air_attack")
	add_state("slide")
	add_state("crouch")
	add_state("death")
	add_state("change_level")
	# Call_deferred is basically a method that calls another method as soon as possible.
	call_deferred("set_state", states.idle)

func _handle_jump(_delta):
	#Important to comment that here the parent values. are in the Player's script.
	# If you are in one of these states, we can either jump or fall off a platform.
	if [states.idle, states.move, states.slide, states.crouch].has(state):
		# When pressing, we snap the snap, turn on the jump variable and pass the jump speed in velocity.y
		if Input.is_action_pressed("jump"):		
			if Input.is_action_pressed("down"):
				# We check if our falling platform raycasts are colliding, if they are,
				# we turn off our BIT to drop the character.
				if parent._check_is_grounded(parent.get_node("PlatformDropRaycasts")): 
					parent.set_collision_mask_bit(parent.PLATFORM_MASK_BIT, false)	
			else:
				parent.jump()
				
	elif state == states.wallSlide:
		if Input.is_action_pressed("jump"):
			parent.wall_jump()
			set_state(states.jump)
	
# We only want to check the jump height if we are jumping
	elif state == states.jump:
# If we release the jump button during the jump and the jump value is low, we adjust to the minimum value.
		if Input.is_action_just_released("jump"):
			if parent.velocity.y < parent.min_jump_velocity:
				parent.velocity.y = parent.min_jump_velocity
		
			
# We override these methods below as they have individual behavior in each instance.

# Applies the logic of movement, gravity, jump and etc.
func _state_logic(delta):
	
	if state == states.death or state == states.change_level:
		return
		
	parent._update_wall_direction()
	parent._update_move_direction()
	if state != states.wallSlide and state != states.crouch:
		parent._handle_move_input()
		
	parent._apply_gravity(delta)
	if state == states.wallSlide:
		parent._gravity_wall_slide()		
		parent._handle_wall_slide_sticking()
	
	if state == states.attack:
		if Input.is_action_just_pressed("attack") and hit_count < max_hit:
			hit = true
	if state == states.air_attack:
		if Input.is_action_just_pressed("attack") and hit_count < max_hit:
			hit = true	
	parent._apply_movement()
	if state == states.crouch:
		# Extra check to avoid problems when changing collider
		if parent.velocity.y < 0:
			parent.velocity.y = 0
	_handle_jump(delta)

# Make appropriate transitions between states.
func _get_transitions(_delta):
	# Match is the switch case of other languages, it serves to check the value of a variable and act on it.
	match state:
		# We put how each transition happens, in which case, which input or event is necessary to occur to validate the exchange.
		states.idle:
			if Input.is_action_just_pressed("attack"):
				return states.attack
			elif !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump 
					
				elif parent.velocity.y >= 0:
					if parent.is_on_floor() or !parent.get_node("CoyoteTimer").is_stopped():
						pass
					else:							
						return states.fall
			elif parent.velocity.x != 0:
				return states.move
			elif Input.is_action_pressed("down"):
				if parent.is_jumping == false and parent.is_on_floor():
					return states.crouch		
		states.move:
			if Input.is_action_just_pressed("down") and parent.is_on_floor():
				if parent.get_node("SlideCooldown").is_stopped():
					return states.slide
			if Input.is_action_just_pressed("attack"):
				return states.attack
			elif !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
					
				elif parent.velocity.y >= 0:
					if parent.is_on_floor() or !parent.get_node("CoyoteTimer").is_stopped():
						pass
					else:							
						return states.fall
						
			elif parent.velocity.x == 0:
				return states.idle
		states.jump:
			if Input.is_action_just_pressed("attack") and parent.can_do_air_attack:
				return states.air_attack
			
			elif parent.wall_direction != 0 and parent.get_node("WallSlideCooldown").is_stopped():
				return states.wallSlide
			elif parent.is_on_floor():
				return states.idle
			elif parent.velocity.y >= 0:					
				return states.fall
		states.fall:
			if Input.is_action_just_pressed("attack") and parent.can_do_air_attack:
				return states.air_attack
			if parent.wall_direction != 0 and parent.get_node("WallSlideCooldown").is_stopped() and parent.move_direction == parent.wall_direction:
				return states.wallSlide
			elif parent.is_on_floor():
				return states.idle
			elif parent.velocity.y < 0:
				return states.jump						
		states.wallSlide:
			if Input.is_action_just_pressed("attack"):
				return states.air_attack
			if parent.is_on_floor():
				return states.idle
			elif parent.wall_direction == 0:
				return states.fall
		states.slide:
			if !parent.is_on_floor():
				if parent.velocity.y < 0:
					return states.jump
					
				elif parent.velocity.y >= 0:
					if parent.is_on_floor() or !parent.get_node("CoyoteTimer").is_stopped():
						pass
					else:							
						return states.fall
						
			elif parent.move_direction == 0 or parent.temporary_move_direction != parent.move_direction:
				return states.idle					
		states.crouch:
			if Input.is_action_just_released("down"):
				return states.idle	
			if Input.is_action_just_pressed("attack"):
				return states.attack		
			if parent.velocity.y >= 0 and !parent.is_on_floor():					
				return states.fall
	return null
# Function for entering a new state. In general, it will play the corresponding animation.
func _enter_state(new_state, old_state):
	match new_state:
		states.idle:
			parent.play_animation('idle')
			parent._set_custom_collision_shape()
		states.move:
			parent.play_animation('move')
			parent._set_custom_collision_shape()
		states.jump:
			# If it's a walljump jump, do the wall_jump animation
			if old_state == states.wallSlide:
				parent.play_animation('wall_jump')
				parent._set_custom_collision_shape("wall_jump")
			else:
				parent.play_animation('jump')
				parent._set_custom_collision_shape()
		states.fall:
			parent.play_animation('fall')
			parent._set_custom_collision_shape()
		states.wallSlide:
			parent.play_animation('wall_slide')
			parent.get_node("BodyPivot").scale.x = -parent.wall_direction
			parent._set_custom_collision_shape()
			emit_signal("switch_v_margin_mode", true)
		states.attack:
			attack()
			parent._set_custom_collision_shape()
		states.air_attack:
			air_attack()
			parent.get_node("BodyPivot/PlayerAttackCollision/CollisionShape2D").disabled = false
			parent._set_custom_collision_shape()
		states.slide:
			parent.temporary_move_direction = parent.move_direction
			parent.velocity.x = parent.slide_speed * parent.move_direction
			parent.slide()
			parent.get_node("BodyPivot/Slideparticles").emitting = true
			parent.play_animation('slide')
			parent._set_custom_collision_shape('slide')
			parent._set_slide_collision_damage(false)
		states.crouch:
			parent.play_animation('crouch')
			parent._set_custom_collision_shape('crouch')
			
		states.death:
			parent.play_animation('death')
			parent._set_custom_collision_shape('death')			
			
		states.change_level:
			parent.hide()
	emit_signal("changed_state",  state)
	
# State exit function.
func _exit_state(old_state, _new_state):
	match old_state:
		states.wallSlide:
			parent.get_node("WallSlideCooldown").start()
			emit_signal("switch_v_margin_mode", false)
		states.slide:
			if !parent.get_node("SlideDuration").is_stopped():
				parent.get_node("SlideDuration").stop()
			parent.get_node("SlideCooldown").start()
			parent.get_node("BodyPivot").rotation = 0
			parent.get_node("BodyPivot/Slideparticles").process_material.gravity.x *= parent.move_direction
			parent.get_node("BodyPivot/Slideparticles").emitting = false
			parent._set_slide_collision_damage(true)
		states.attack:
			yield(get_tree(),"idle_frame")
			parent.movement_speed_while_attack = 0 * 24
			parent.gravity_disabled = false
			parent.get_node("BodyPivot/PlayerAttackCollision/CollisionShape2D").disabled = true						

		states.air_attack:
			yield(get_tree(),"idle_frame")
			parent.movement_speed_while_attack = 0 * 24
			parent.gravity_disabled = false
			parent.get_node("BodyPivot/PlayerAttackCollision/CollisionShape2D").disabled = true


# 'Sticky' on the wall, gives the player a better feeling.
func _on_WallSlimeStickyTimer_timeout():
	if state == states.wallSlide:
		set_state(states.fall)

# If it's a land combo, make the animation
func attack():
	match hit_count:
		0:
			parent.play_animation('attack1')
			parent.movement_speed_while_attack = 0
		1:
			parent.play_animation('attack2')
			parent.movement_speed_while_attack = 0
		2:
			parent.play_animation('attack3')
			parent.movement_speed_while_attack = 4 * 24
			
	hit = false

# If it's an aerial combo, make the animation
func air_attack():
	match hit_count:
		0:
			parent.play_animation('air_attack1')
		1:
			parent.play_animation('air_attack2')
		2:
			parent.play_animation('air_attack3')
	
	parent.movement_speed_while_attack = parent.move_speed		
	hit = false
	

# Validation for ending animations, in this case, serving for the combo.
# If the combo animations run out and there is no more hit, or if the player interrupts the combo.
# Go back to the previous state.
func _on_sprite_animation_finished():
	var anim_name = parent.get_node("BodyPivot/sprite").animation	
	if hit:
		hit_count += 1
		if state == states.air_attack:
			if parent.is_on_floor():
				attack()
			else:
				air_attack()
		elif state == states.attack:
			if parent.is_on_floor():
				attack()
			else:
				air_attack()
		return
	if anim_name == 'attack1' or anim_name == 'attack2' or anim_name == 'attack3':	
		hit_count = 0
		hit = false
		if previous_state == states.crouch:
			if Input.is_action_pressed("down"):
				set_state(previous_state)
			else:
				set_state(states.idle)		
		else:
			set_state(previous_state)
		
	elif anim_name == 'air_attack1' or anim_name == 'air_attack2' or anim_name == 'air_attack3':	
		hit_count = 0
		hit = false
		# We do an extra security check
		if previous_state == states.crouch:
			if Input.is_action_pressed("down"):
				set_state(previous_state)
			else:
				set_state(states.idle)		
		else:
			set_state(previous_state)
	# If the animation is death, reload the current scene
	if anim_name == "death":
		# We check if there is a manager level, if it does not exist (in this case, if it does not have the function we are looking for)
	# We reload the current scene.
		if owner.get_parent().get_parent().has_method("restart_current_level"):
			owner.get_parent().get_parent().restart_current_level()
		else:
			var _reload_scene = get_tree().reload_current_scene()
# We return to the previous state of the Slide
func _on_SlideDuration_timeout():
	set_state(previous_state)	

# We make changes depending on the animation we are working on.
# In these cases, it is the attack animations, we enable and disable the attack collider.
func _on_sprite_frame_changed():
	var anim_node = parent.get_node("BodyPivot/sprite")
	var atk_collision_shape = parent.get_node("BodyPivot/PlayerAttackCollision/CollisionShape2D")
	if anim_node.animation == 'attack1':
		if anim_node.frame == 3:
			atk_collision_shape.disabled = false
		elif anim_node.frame == 8:
			atk_collision_shape.disabled = true

	elif anim_node.animation == 'attack2':
		if anim_node.frame == 2:
			atk_collision_shape.disabled = false
		elif anim_node.frame == 5:
			atk_collision_shape.disabled = true

	elif anim_node.animation == 'attack3':
		if anim_node.frame == 1:
			atk_collision_shape.disabled = false
		elif anim_node.frame == 4:
			atk_collision_shape.disabled = true
			parent.movement_speed_while_attack = 0
			
	elif anim_node.animation == 'air_attack1':
		if anim_node.frame == 0:
			atk_collision_shape.disabled = false
		elif anim_node.frame == 3:
			atk_collision_shape.disabled = true
			parent.gravity_disabled = false
	elif anim_node.animation == 'air_attack2':
		if anim_node.frame == 0:
			atk_collision_shape.disabled = false
		elif anim_node.frame == 2:
			atk_collision_shape.disabled = true	
			parent.gravity_disabled = false
	elif anim_node.animation == 'air_attack3':
		if anim_node.frame == 0:
			atk_collision_shape.disabled = false
		elif anim_node.frame == 4:
			atk_collision_shape.disabled = true
			parent.gravity_disabled = false
