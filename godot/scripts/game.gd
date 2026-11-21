# Global game state (autoload "Game"): story flags and items that carry between areas.
extends Node

# Story flags, same names as the web game:
# goblinAllies, skornKing, chugWon, lykorDethroned, foreheadLoser, bag_checked, ...
var flags := {}
var inv := { "beer": 0, "bowl": 0 }
var tts_on := true

func flag(name: String) -> bool:
	return flags.get(name, false)

func set_flag(name: String, value = true) -> void:
	flags[name] = value

func reset() -> void:
	flags = {}
	inv = { "beer": 0, "bowl": 0 }

func goto(path: String) -> void:
	get_tree().change_scene_to_file(path)
