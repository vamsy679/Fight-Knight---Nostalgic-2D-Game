extends Control

# We changed the instructions that should be shown based on the node name.
func _on_StateMachine_changed_state(state):
	match state:
		0:
			_set_visible('idle')
		1:
			_set_visible('move')
		2:
			_set_visible('jumpfall')
		3:
			_set_visible('jumpfall')
		4:
			_set_visible('wallSlide')
		5:
			_set_visible('attack')
		6:
			_set_visible('attack')
		7:
			_set_visible('slide')
		8:
			_set_visible("crouch")
		9:
			_set_visible("death")
		_:
			_set_visible("")	
# We check the nodes, if it is the same as that passed to the function, make it visible.			
func _set_visible(node_name):
	for i in $Panel.get_children():
		if i.get_child_count() > 0:
			if i.name == node_name:
				i.visible = true
			else:
				i.visible = false

# Called when we press the button.
func _on_Button_pressed():
	if $Panel.visible:
		$Panel.hide()
		$Button.text = 'Controls'
	else:
		$Panel.show()
		$Button.text = 'Hide'
