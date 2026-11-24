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
	lib._page(lib._soundtrack())
	await get_tree().process_frame
	ok(not lib.hub.visible and is_instance_valid(lib.menu), "soundtrack page opens over the hub")
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
	ok(lib.hub.visible and not lib._playing(0), "back to the hub, song stopped")
	# voice lines
	var vls := ScriptScan.voice_lines()
	ok(vls.size() > 200, "voice lines found: %d" % vls.size())
	ok(vls.all(func(l): return ResourceLoader.exists(l["path"]) and l["text"] != ""), "every voice line has a file + text")
	var others := vls.filter(func(l): return l["cat"] == "Others").size()
	ok(others < 10, "few uncategorized lines (%d)" % others)
	var vp := VoiceLinesUI.open(ui)
	await get_tree().process_frame
	vp.search.text = "metocy"
	vp._filter()
	ok(vp.shown.size() > 0 and vp.shown.all(func(l): return "metocy" in (l["text"] + " " + l["name"]).to_lower()), "search filters (%d for metocy)" % vp.shown.size())
	vp._set_tab(1)
	ok(vp.shown.all(func(l): return l["cat"] == vp.tabs[1][0]), "character tab filters")
	vp.search.text = ""
	vp._filter()
	vp.sel = 0
	vp._toggle()
	ok(vp.playing == 0, "voice line plays")
	vp._close()
	# scrapbook
	var story := ScrapbookUI.story_items().size()
	var found := 0
	for it in ScrapbookUI.story_items():
		if ScriptScan.outcome(it[0]).get("choice", "") != "":
			found += 1
	ok(found == story, "every story outcome found in the scripts (%d/%d)" % [found, story])
	Game.progress["village_speech"] = true
	var sb := ScrapbookUI.open(ui)
	await get_tree().process_frame
	ok(sb.entries.filter(func(e): return not e.get("secret", false)).size() == story, "scrapbook has a page per outcome")
	ok(sb.entries.back().get("secret", false), "scrapbook ends with the secret Deloye Lore page")
	sb.sel = 0
	sb._render()
	await get_tree().process_frame
	ok(sb.page.get_child_count() > 3, "unlocked page shows the moment")
	sb.queue_free()
	Game.progress.erase("village_speech")
	lib.hub.close()
	await get_tree().process_frame
	ok(not is_instance_valid(lib), "library closes")
	print("UI TEST: %s" % ("ALL OK" if fails == 0 else "%d FAILED" % fails))
	get_tree().quit()
