extends Node2D

func _ready():
	_set_player_camera_limits()

# limits of the player's camera based on the size Tilemap.
func _set_player_camera_limits():
	var map_size = $Tilemaps/GeneralGround.get_used_rect()
	var cell_size = $Tilemaps/GeneralGround.cell_size
	$Player/Camera2D.limit_left = map_size.position.x * cell_size.x	
	$Player/Camera2D.limit_top = map_size.position.y * cell_size.y
	$Player/Camera2D.limit_right = map_size.end.x * cell_size.x
	$Player/Camera2D.limit_bottom = map_size.end.y * cell_size.y

#  move on to the next phase.
func _on_EndLevel_end_current_level():
	if get_parent().has_method("transition_to_next_level"):
		get_parent().transition_to_next_level(self)
	else:
		print("It is not possible to get next level, for this, use LevelInstantiate")

func _on_Boss_enable_end_level():
	$EndLevel.global_position = Vector2(4271, 383)

