extends Node

# Global script. To create one, go to Project> Project Settings> Autoload
# Facilitates global access to certain information.

var gravity = 0

# We define the severity, this is defined by the player.
func set_gravity(player_max_jump_height, player_jump_duration):
	gravity = 2 * player_max_jump_height / pow(player_jump_duration,2)
	
