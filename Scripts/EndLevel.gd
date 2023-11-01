extends Area2D

signal end_current_level

# When the player enters, we will make the necessary transitions.
# Connect the end_current_level signal to the Level that places this node.
func _on_EndLevel_body_entered(body):
	body.end_level_state()
	emit_signal("end_current_level")
