extends Node2D

export(Array, PackedScene) var gameLevels = []

var current_level
var level_index = 0

# We start the game with the first level
func _ready():
	next_level()
	

func transition_to_next_level(old_level): # Transition to next level
	$CanvasLayer/AnimationPlayer.play("Transition_in")
	yield($CanvasLayer/AnimationPlayer,"animation_finished")
	old_level.queue_free()	
	current_level = null
	if level_index == gameLevels.size():
		level_index = 0
	
	yield(get_tree(),"idle_frame")
	next_level()


func next_level(): # To the next level
	$CanvasLayer/AnimationPlayer.play("Transition_out")
	current_level = gameLevels[level_index].instance()
	level_index += 1
	add_child(current_level)


func restart_current_level(): # when dead, restart
	$CanvasLayer/AnimationPlayer.play("Transition_in")
	yield($CanvasLayer/AnimationPlayer,"animation_finished")
	current_level.queue_free()
	yield(get_tree(),"idle_frame")
	$CanvasLayer/AnimationPlayer.play("Transition_out")
	current_level = gameLevels[level_index - 1].instance()
	add_child(current_level)	
