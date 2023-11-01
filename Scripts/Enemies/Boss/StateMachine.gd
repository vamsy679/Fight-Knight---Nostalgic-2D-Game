extends StateMachine

# Add states and set the initial state.
func _ready():
	add_state('waiting')
	add_state('idle')
	add_state('attack_1')
	add_state('pre_attack_2')
	add_state('attack_2')
	add_state('death')
	
	call_deferred("set_state", states.waiting)

# We apply the current state logic
func _state_logic(delta):
	if [states.attack_2].has(state):
		
		parent.do_attack_2(delta)

# Function for entering a new state.
func _enter_state(_new_state, _old_state):
	match state:
		states.waiting:
			parent.play_animation('waiting')
		states.idle:
			parent.play_animation('idle')
		states.attack_1:
			parent.play_animation('attack_1')
		states.pre_attack_2:
			parent.play_animation('prepare_attack_2')
		states.death:
			parent.get_node("DamagePlayer").queue_free()
			parent.play_animation('death')
		

# State exit function.
func _exit_state(old_state, _new_state):
	match old_state:
		states.attack_2:
			parent.fly_attack_count_timer = 0

