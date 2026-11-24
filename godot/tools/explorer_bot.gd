# Explorer bot launcher. The bot itself is explorer_bot_player.gd (what it does, settings, how to run: see the top
# of that file). Run: godot --path godot --script res://tools/explorer_bot.gd
# This file stays tiny on purpose: a --script file is compiled before the Game autoload exists, so it can't name
# any game class (Level, Dialogue, MenuUI…). The player is loaded once the game is up, and lives on the root so it
# survives scene changes.
extends SceneTree

func _initialize() -> void:
	_start.call_deferred()

func _start() -> void:
	var bot: Node = load("res://tools/explorer_bot_player.gd").new()
	bot.name = "ExplorerBot"
	root.add_child(bot)
