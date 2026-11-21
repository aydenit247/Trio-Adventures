# Title screen: the camp at night as a live background (fire lit, the trio hanging out), logo + main menu.
# Continue = newest save · New Game · Load Game · Settings · Quit.
extends Node

var bg: Node        # the camp, running in title mode
var ui: CanvasLayer
var menu: MenuUI
var music: AudioStreamPlayer   # "Prophecy of Metocy" (Ebain's track), loops on the title
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
	if "--shots" in OS.get_cmdline_user_args():
		_shot_tour()

func _start_music() -> void:
	var stream: AudioStreamOggVorbis = load("res://assets/music/prophecy_of_metocy.ogg")
	stream.loop = true
	music = AudioStreamPlayer.new()
	music.stream = stream
	music.volume_db = -40.0
	add_child(music)
	music.play()
	create_tween().tween_property(music, "volume_db", MUSIC_DB, 2.0)
	if bg and "amb" in bg and bg.amb:   # menu = just the song (Ebain): no campfire crackle, no crickets
		bg.amb.cricket_player.stop()
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
	var t := _lbl("TRIO ADVENTURES", 84, Color("#e8b923"), 18)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var st := _lbl("Chapter 1 — The Quest for the Metocy", 26, Color("#f3e3b0"), 8)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(st)
	t.modulate.a = 0.0
	st.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(t, "modulate:a", 1.0, 1.0)
	tw.tween_property(st, "modulate:a", 1.0, 0.6)
	var foot := _lbl("by Ebain  ·  F11 fullscreen  ·  controller supported", 15, Color(1, 1, 1, 0.55), 4)
	foot.anchor_left = 0.0; foot.anchor_right = 1.0; foot.anchor_top = 1.0; foot.anchor_bottom = 1.0
	foot.offset_top = -34; foot.offset_right = -24
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ui.add_child(foot)

func _open_menu() -> void:
	var latest := Game.latest_slot()
	var rows := [
		{ "text": "Continue", "enabled": latest != "", "pick": func():
			await _fade_music()
			Game.load_game(Game.latest_slot()),
		  "note": _continue_note(latest) },
		{ "text": "New Game", "pick": func(): _new_game() },
		{ "text": "Load Game", "enabled": latest != "", "pick": func(): await _sub(MenuUI.open_slots(ui, "load")) },
		{ "text": "Settings", "pick": func(): await _sub(MenuUI.open_settings(ui)) },
		{ "text": "Quit", "pick": func(): get_tree().quit() },
	]
	menu = MenuUI.open(ui, "", rows, { "w": 420, "anchor_x": 0.2, "anchor_y": 0.66, "dim": false, "panel_alpha": 0.82,
		"font": 28, "hint": "E / Enter / A to pick · mouse works too" })
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
	get_tree().quit()
