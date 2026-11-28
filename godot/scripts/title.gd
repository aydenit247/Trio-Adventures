# Title screen: the camp at night as a live background (fire lit, the trio hanging out), logo + main menu.
# Continue = newest save · New Game · Load Game · Settings · Quit.
extends Node

var bg: Node        # the camp, running in title mode
var ui: CanvasLayer
var menu: MenuUI
var music: AudioStreamPlayer   # "Prophecy of Metocy" (Ebain's track), loops on the title
var prog_lbl_font: Font
const MUSIC_DB := -3.0

func _ready() -> void:
	Game.title_mode = true
	Game.reset()   # unsaved progress from a game you quit is gone anyway; keeps the menu's camp clean (no forehead text etc.)
	Game.pending_resume = {}
	bg = load("res://main.tscn").instantiate()
	add_child(bg)
	ui = CanvasLayer.new()
	ui.layer = 30
	add_child(ui)
	_start_music()
	_logo()
	_open_menu()
	_check_update()
	if "--shots" in OS.get_cmdline_user_args():
		_shot_tour()

# 11/27 shipping polish: the Windows build checks GitHub for a newer build (updater.gd) and adds a menu row if there is one
var updater: Updater
func _check_update() -> void:
	updater = Updater.new()
	add_child(updater)
	if await _do_check() and is_instance_valid(menu) and menu.visible and MenuUI.stack.back() == menu:
		var keep: int = menu.sel
		menu.close()
		_open_menu()
		menu.sel = keep + 1
		menu.refresh()

func _do_check() -> bool:
	updater.check()
	return await updater.checked

func _update() -> void:
	var when := str(updater.info.get("built", ""))
	var what := str(updater.info.get("msg", ""))
	if not await MenuUI.confirm(ui, "A new build is out%s.%s\nDownload it now? The game restarts by itself when it's done." % [
			(" (" + when + ")") if when != "" else "", ("\n\"" + what + "\"") if what != "" else ""], "Update", "Later"):
		return
	var box := { "m": null }
	box["m"] = MenuUI.open(ui, "UPDATING", [{ "text": "Downloading…", "enabled": false }], { "w": 560 })
	box["m"].big_note()
	box["m"].on_back = func(): pass
	updater.progress.connect(func(f): if is_instance_valid(box["m"]): box["m"].set_note("%d%%" % int(f * 100.0)))
	var err := await updater.install()
	if err != "" and is_instance_valid(box["m"]):
		box["m"].close()
		await MenuUI.confirm(ui, err, "OK", "Close")

func _start_music() -> void:
	var stream: AudioStreamOggVorbis = load("res://assets/music/prophecy_of_metocy.ogg")
	stream.loop = true
	music = AudioStreamPlayer.new()
	music.stream = stream
	music.volume_db = -40.0
	music.bus = &"Music"
	add_child(music)
	LibraryUI.mark_heard("prophecy_of_metocy")
	music.play()
	create_tween().tween_property(music, "volume_db", MUSIC_DB, 2.0)
	if bg and "amb" in bg and bg.amb:   # menu = just the song (Ebain): no campfire crackle, no crickets
		bg.amb.cricket_player.stop()
		bg.amb.night_player.stop()
		bg.amb.fire_player.stop()
		bg.amb.set_process(false)

func _process(delta: float) -> void:
	# loading out of the title some other way (e.g. Load Game menu): duck the music fast
	if Game.changing and music and music.volume_db > -40.0:
		music.volume_db -= delta * 140.0

func _fade_music(secs := 0.9) -> void:
	if music:
		var tw := create_tween()
		tw.tween_property(music, "volume_db", -40.0, secs)
		await tw.finished

# Settings → Graphics calls this on the current scene
func apply_graphics() -> void:
	if bg and bg.has_method("apply_graphics"):
		bg.apply_graphics()

func _lbl(text: String, size: int, color: Color, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", outline)
	return l

func _logo() -> void:
	var box := VBoxContainer.new()
	box.anchor_left = 0.0; box.anchor_right = 1.0; box.anchor_top = 0.0
	box.offset_top = 46
	box.add_theme_constant_override("separation", 0)
	ui.add_child(box)
	var t := _lbl("TRIO ADVENTURES", 84, Color("#f0c24a"), 18)   # always gold over the night camp, whatever the menu theme
	t.add_theme_font_override("font", UITheme.head_font())
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	t.add_theme_constant_override("shadow_offset_y", 6)
	t.add_theme_constant_override("shadow_outline_size", 22)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var orn := Control.new()   # gold ornament line under the logo
	orn.custom_minimum_size = Vector2(0, 22)
	orn.draw.connect(func():
		var y := 11.0
		var mid := orn.size.x * 0.5
		var g := Color("#f0c24a")
		for side in [-1.0, 1.0]:
			orn.draw_polyline_colors([Vector2(mid + side * 16, y), Vector2(mid + side * 300, y)], [g, Color(g, 0.0)], 2.0, true)
			orn.draw_colored_polygon([Vector2(mid + side * 30, y - 4), Vector2(mid + side * 34, y), Vector2(mid + side * 30, y + 4), Vector2(mid + side * 26, y)], g)
		orn.draw_colored_polygon([Vector2(mid, y - 9), Vector2(mid + 9, y), Vector2(mid, y + 9), Vector2(mid - 9, y)], g)
		orn.draw_colored_polygon([Vector2(mid, y - 4), Vector2(mid + 4, y), Vector2(mid, y + 4), Vector2(mid - 4, y)], Color("#2a1a08")))
	box.add_child(orn)
	var st := _lbl("", 26, Color("#f3e3b0"), 8)   # (the chapter title now shows once when a new game starts, camp._chapter_card)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(st)
	t.modulate.a = 0.0
	st.modulate.a = 0.0
	orn.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(t, "modulate:a", 1.0, 1.0)
	tw.tween_property(orn, "modulate:a", 1.0, 0.5)
	tw.tween_property(st, "modulate:a", 1.0, 0.6)
	var foot := _lbl("by Ebain  ·  F11 fullscreen  ·  controller supported", 15, Color(1, 1, 1, 0.55), 4)
	foot.anchor_left = 0.0; foot.anchor_right = 1.0; foot.anchor_top = 1.0; foot.anchor_bottom = 1.0
	foot.offset_top = -34; foot.offset_right = -24
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(foot)
	# (Asar) how much of the game you've seen, across every playthrough (progress_data.gd)
	prog_lbl_font = UITheme.row_font()
	var prog := _lbl("Outcomes  %d / %d      %d%% complete" % [Game.outcomes_found(), Game.outcomes_total(), Game.completion_pct()], 22, Color("#f3e3b0"), 6)
	prog.anchor_left = 0.0; prog.anchor_top = 1.0; prog.anchor_bottom = 1.0
	prog.offset_left = 34; prog.offset_top = -46
	prog.add_theme_font_override("font", prog_lbl_font)
	ui.add_child(prog)
	prog.modulate.a = 0.0
	create_tween().tween_property(prog, "modulate:a", 1.0, 0.8).set_delay(1.6)

func _open_menu() -> void:
	var latest := Game.latest_slot()
	var rows := []
	if updater and updater.available:
		rows.append({ "text": "Update available!", "pick": func(): await _update(),
		  "note": "A newer build of Trio Adventures is out. Pick this to download it (the game restarts itself)." })
	rows += [
		{ "text": "Continue", "enabled": latest != "", "pick": func():
			await _fade_music()
			Game.load_game(Game.latest_slot()),
		  "note": _continue_note(latest) },
		{ "text": "New Game", "pick": func(): _new_game() },
		{ "text": "Load Game", "enabled": latest != "", "pick": func(): await _sub(MenuUI.open_slots(ui, "load")) },
		{ "text": "Library", "pick": func(): await _sub_lib(),
		  "note": "Soundtrack: %d / %d songs found. Hear the rest in the game." % [LibraryUI.heard_count(), LibraryUI.SONGS.size()] },
		{ "text": "Achievements  (%d/%d)" % [Game.ach.count(), Achievements.LIST.size()], "pick": func():
			await _sub(MenuUI.open(ui, "Achievements", Game.ach.menu_rows(), { "w": 560 })) },
		{ "text": "Settings", "pick": func(): await _sub(MenuUI.open_settings(ui)) },
		{ "text": "Quit", "pick": func(): get_tree().quit() },
	]
	menu = MenuUI.open(ui, "", rows, { "w": 420, "anchor_x": 0.2, "anchor_y": 0.66, "dim": false, "panel_alpha": 0.82,
		"font": 28, "hint": "E / Enter / A to pick · mouse works too", "silent": true })
	menu.on_back = func(): pass   # Esc does nothing on the title

func _continue_note(slot: String) -> String:
	if slot == "":
		return ""
	var d := Game.read_save(slot)
	var where := String(d.get("label", "")).split(" — ")[-1]
	return "%s · Lv %d · %s" % [where, int(d.get("level", 1)), Game.save_when(float(d["time"]))]

func _new_game() -> void:
	if Game.latest_slot() != "":
		if not await MenuUI.confirm(ui, "Start a new game? Your autosave gets replaced when you reach the camp (Slots 1–3 are kept).", "Start", "Cancel"):
			return
	await _fade_music()
	Game.new_game()

func _sub_lib() -> void:
	menu.visible = false
	var lib := LibraryUI.open(ui, music)
	await lib.closed
	if is_instance_valid(menu):
		menu.visible = true
		menu.refresh()

func _sub(m: MenuUI) -> void:
	menu.visible = false
	await m.closed
	if is_instance_valid(menu):
		menu.visible = true
		menu.refresh()

# --shots: screenshot the title and its menus
func _shot_tour() -> void:
	var lv = bg
	await get_tree().create_timer(4.0).timeout
	await lv.shot("t_01_title")
	var st := MenuUI.open_settings(ui)
	menu.visible = false
	await get_tree().create_timer(0.5).timeout
	await lv.shot("t_02_settings")
	st.close()
	var sl := MenuUI.open_slots(ui, "load")
	await get_tree().create_timer(0.5).timeout
	await lv.shot("t_03_load")
	sl.close()
	var lib := LibraryUI.open(ui, music)
	await get_tree().create_timer(0.5).timeout
	await lv.shot("t_04_library")
	lib._page(lib._soundtrack())
	await get_tree().create_timer(0.5).timeout
	await lv.shot("t_04b_soundtrack")
	lib._lyrics(0)
	await get_tree().create_timer(0.6).timeout
	await lv.shot("t_05_lyrics")
	for th in UITheme.NAMES.size():   # each theme on the settings page
		Game.ui_theme = th
		Game.ui_changed.emit()
		var dp := MenuUI._settings_display(ui)
		await get_tree().create_timer(0.5).timeout
		await lv.shot("t_06_theme_%d" % th)
		dp.close()
	Game.ui_theme = 0
	for pg in [VoiceLinesUI.open(ui), ScrapbookUI.open(ui)]:
		await get_tree().create_timer(0.6).timeout
		await lv.shot("t_07_" + pg.get_script().get_global_name().to_lower())
		pg.queue_free()
	get_tree().quit()
