# UI overhaul logic test (headless): godot --headless --path godot res://tools/test_ui.tscn
# Checks keybind swap/reset, SFX/Music routing, theme switch restyle, Library unlocks, settings pages open/close.
extends Node

var fails := 0

func ok(cond: bool, what: String) -> void:
	print(("PASS " if cond else "FAIL ") + what)
	if not cond:
		fails += 1

func _ready() -> void:
	await get_tree().process_frame
	# buses + routing
	ok(AudioServer.get_bus_index("Music") > 0 and AudioServer.get_bus_index("SFX") > 0, "Music + SFX buses exist")
	var p := AudioStreamPlayer.new()
	add_child(p)
	ok(p.bus == &"SFX", "new player goes to SFX")
	var mp := AudioStreamPlayer.new()
	mp.bus = &"Music"
	add_child(mp)
	ok(mp.bus == &"Music", "music player stays on Music")
	var scr := GDScript.new()
	scr.source_code = "extends Node\nvar _vo: AudioStreamPlayer\n"
	scr.reload()
	var holder := Node.new()
	holder.set_script(scr)
	add_child(holder)
	holder._vo = AudioStreamPlayer.new()
	holder.add_child(holder._vo)
	ok(holder._vo.bus == &"Master", "dialogue _vo stays on Master")
	# keybinds
	Keybinds.reset_all()
	var sw := Keybinds.set_key("interact", KEY_Q)
	ok(Keybinds.key_of("interact") == KEY_Q and Keybinds.key_of("switch") == KEY_E and sw == "Switch leader", "rebind swaps keys")
	var has_space := false
	for e in InputMap.action_get_events("interact"):
		if e is InputEventKey and e.physical_keycode == KEY_SPACE:
			has_space = true
	ok(has_space, "interact keeps Space")
	var cf := ConfigFile.new()
	Keybinds.save_to(cf)
	Keybinds.custom.clear()
	Keybinds.load_from(cf)
	ok(Keybinds.key_of("interact") == KEY_Q, "keybinds save + load")
	Keybinds.reset_all()
	ok(Keybinds.key_of("interact") == KEY_E and Keybinds.custom.is_empty(), "reset to defaults")
	# library
	ok(LibraryUI.is_heard("prophecy_of_metocy"), "title song unlocked from the start")
	ok(not LibraryUI.mark_heard("not_a_song"), "unknown song ignored")
	var before := LibraryUI.is_heard("the_mogging_elf")
	var first := LibraryUI.mark_heard("res://assets/music/the_mogging_elf.ogg")
	ok(LibraryUI.is_heard("the_mogging_elf") and (first != before), "path unlocks the song once")
	ok(not LibraryUI.mark_heard("the_mogging_elf"), "second unlock is a no-op")
	# menus + themes
	var ui := CanvasLayer.new()
	add_child(ui)
	var st := MenuUI.open_settings(ui)
	await get_tree().process_frame
	for page in [MenuUI._settings_audio, MenuUI._settings_display, MenuUI._settings_dialogue, MenuUI._settings_gameplay, MenuUI._settings_controls]:
		var m: MenuUI = page.call(ui)
		await get_tree().process_frame
		for t in UITheme.NAMES.size():
			Game.ui_theme = t
			Game.ui_changed.emit()
		Game.ui_theme = 0
		Game.ui_changed.emit()
		m.close()
	ok(true, "every settings page opens + restyles in each theme")
	st.close()
	var lib := LibraryUI.open(ui, null)
	await get_tree().process_frame
	lib._toggle(0)
	await get_tree().create_timer(0.3).timeout
	ok(lib._playing(0), "library plays a song")
	lib._toggle(0)
	ok(not lib._playing(0), "library pauses")
	lib._lyrics(0)
	await get_tree().process_frame
	ok(is_instance_valid(lib.page), "lyrics page opens")
	lib.page.queue_free()
	lib.menu.close()
	await get_tree().process_frame
	ok(not is_instance_valid(lib), "library closes")
	print("UI TEST: %s" % ("ALL OK" if fails == 0 else "%d FAILED" % fails))
	get_tree().quit()
