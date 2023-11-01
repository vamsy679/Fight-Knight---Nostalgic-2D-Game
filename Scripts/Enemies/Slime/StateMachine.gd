extends StateMachine

# 
func _ready():
	add_state('idle')
	add_state('move')
	add_state('attack')
	add_state('hurt')
	add_state('bump')
	add_state('death')
	call_deferred("set_state", states.idle)

# We apply the current state logic
func _state_logic(delta):
	if ![states.death].has(state):
		parent.move_enemy(delta)
	
	parent.apply_gravity(delta)		
	if [states.move].has(state):
		parent.apply_movement(delta)
	elif [states.bump].has(state):
		parent.apply_bump()
	elif [states.hurt, states.attack].has(state):
		if parent.is_on_floor():
			parent.velocity.x = 0
	
# Make appropriate transitions between states.
func _get_transitions(_delta):
	match state:
		states.bump:
			if parent.is_on_floor():
				return states.move

# Function for entering a new state.
func _enter_state(_new_state, _old_state):
	match state:
		states.idle:
			parent.play_animation('idle')
		states.move:
			parent.bump = false
			parent.disable_gravity = false
			parent.play_animation('move')
		states.hurt:
			parent.play_animation('hurt')			
		states.attack:
			parent.play_animation('attack')
		states.death:
			parent.play_animation('die')

# State exit function.
func _exit_state(old_state, _new_state):
	match old_state:
		states.bump:
			parent.bump = false
		states.hurt:
			parent.bump = false
			parent.disable_gravity = false
			set_state(states.move)

