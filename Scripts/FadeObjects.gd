extends Node2D

func _ready():
	fade()

# We use a tween to make a transparent animation to make the object disappear in a more natural way.
func fade():
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(
		self, # Who
		"modulate", # What
		Color (1,1,1,1), # Initial value
		Color (1,1,1,0), # Final value
		1, # Duration
		Tween.TRANS_LINEAR, # Animation type
		Tween.EASE_IN_OUT, # Ease of animation
		0
	)
	tween.start()
	# Yield waits for something to happen to release the rest of the code, it's like a pause.
	yield(tween,"tween_completed")
	# This idle frame serves as a security frame and also helps to avoid overloading the engine.
	yield(get_tree(),"idle_frame")
	queue_free()
