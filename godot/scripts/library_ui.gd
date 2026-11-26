# LibraryUI: Title → Library (Ebain 11/24). A hub with three pages:
#   Soundtrack (here), Voice Lines (voice_lines_ui.gd: every recorded line, per character, searchable),
#   Scrapbook (scrapbook_ui.gd: a page per story outcome).
# The Soundtrack: every song with play/pause, a now-playing bar you can
# click to seek, and a Lyrics page (lyrics.gd). A song shows as "? ? ?" until you've heard it in the game
# (AreaMusic calls LibraryUI.mark_heard() once its song is audible; the title song is unlocked from the start).
# Heard songs are saved in user://library.cfg, across every playthrough (New Game never clears them).
#   LibraryUI.open(ui_canvas_layer, title_music_player)  →  await lib.closed
# To add a song: add it to SONGS (id = the .ogg name) and to Lyrics.TEXT, and give its area an AreaMusic node.
class_name LibraryUI
extends Node

signal closed

const SONGS := [
	{ "id": "prophecy_of_metocy", "title": "Prophecy of Metocy", "by": "Ebain", "where": "the title screen", "always": true },
	{ "id": "the_mogging_elf", "title": "The Mogging Elf", "by": "Ebain", "where": "the goblin village" },
	{ "id": "the_hymn_of_metocin_mattias", "title": "The Hymn of Metocin Mattias", "by": "Ebain", "where": "the Summit Path" },
	{ "id": "deloye_lore", "title": "Deloye Lore", "by": "Ebain", "where": "the Deloye library radio" },
	{ "id": "the_tale_of_diddy_chud", "title": "The Tale of Diddy Chud", "by": "Ebain", "where": "the Pass (the giant's music video)" },
]
const CFG := "user://library.cfg"

static var _heard := {}
static var _loaded := false

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var cf := ConfigFile.new()
	if cf.load(CFG) == OK:
		for id in cf.get_section_keys("heard") if cf.has_section("heard") else []:
			_heard[id] = true

static func song(id: String) -> Dictionary:
	for s in SONGS:
		if s["id"] == id:
			return s
	return {}

static func is_heard(id: String) -> bool:
	_load()
	return song(id).get("always", false) or _heard.has(id)

static func heard_count() -> int:
	var n := 0
	for s in SONGS:
		if is_heard(s["id"]):
			n += 1
	return n

# id or a res:// path to the .ogg. Returns true the first time (so the caller can show a toast).
static func mark_heard(id_or_path: String) -> bool:
	var id := id_or_path.get_file().get_basename()
	if song(id).is_empty() or is_heard(id):
		return false
	_heard[id] = true
	var cf := ConfigFile.new()
	cf.load(CFG)
	cf.set_value("heard", id, true)
	cf.save(CFG)
	return true

static func open(parent: Node, title_music: AudioStreamPlayer = null) -> LibraryUI:
	var lib := LibraryUI.new()
	lib.add_to_group("library_open")   # AreaMusic goes quiet while it's open (pause menu → Library)
	parent.add_child(lib)
	lib._build(parent, title_music)
	return lib

# ---------------------------------------------------------------- the screen
var hub: MenuUI                # the Library's first page: Soundtrack / Voice Lines / Scrapbook
var menu: MenuUI               # the Soundtrack page
var player: AudioStreamPlayer
var cur := -1
var title_music: AudioStreamPlayer
var _title_db := 0.0
var _title_ducked := false
var bar: SeekBar
var now_lbl: Label
var time_lbl: Label
var now_icon: UITheme.Icon
var page: Control
var _ui: Node

func _build(parent: Node, tm: AudioStreamPlayer) -> void:
	_ui = parent
	title_music = tm
	player = AudioStreamPlayer.new()
	player.bus = &"Music"
	add_child(player)
	player.finished.connect(func():
		if is_instance_valid(menu):
			menu.refresh())
	var n_lines := ScriptScan.voice_lines().size()
	hub = MenuUI.open(parent, "LIBRARY", [
		{ "text": "Soundtrack", "value": "%d / %d found" % [heard_count(), SONGS.size()], "pick": func(): await _page(_soundtrack()),
		  "note": "Play every song you've heard, and read the lyrics." },
		{ "text": "Voice Lines", "value": "%d lines" % n_lines, "pick": func():
			_duck_title(true)
			await _page(VoiceLinesUI.open(parent))
			_duck_title(false),
		  "note": "Every recorded line in the game. Pick a character or search for any line." },
		{ "text": "Scrapbook", "value": "%d / %d" % [ScrapbookUI.found_count(), ScrapbookUI.story_items().size()], "pick": func(): await _page(ScrapbookUI.open(parent)),
		  "note": "A page for every story choice you've found, and hints for the ones you haven't." },
		{ "text": "Back", "pick": func(): hub.close() },
	], { "w": 560, "font": 24 })
	hub.closed.connect(_on_closed)

# Open a page over the hub; the hub comes back when it closes.
func _page(p: Node) -> void:
	hub.visible = false
	await p.closed
	if is_instance_valid(hub):
		hub.visible = true
		hub.refresh()

func _soundtrack() -> MenuUI:
	var parent := _ui
	var rows := []
	for i in SONGS.size():
		var s: Dictionary = SONGS[i]
		var id: String = s["id"]
		rows.append({
			"text": func(): return "%d.   %s" % [i + 1, s["title"] if is_heard(id) else "? ? ?"],
			"value": func(): return _dur(i) if is_heard(id) else "",
			"icon": func(): return "lock" if not is_heard(id) else ("pause" if _playing(i) else "play"),
			"pick": func(): _toggle(i),
			"change": func(d): _skip(i, d),
			"arrows": false,
			"note": func(): return ("by %s  ·  plays on %s" % [s["by"], s["where"]]) if is_heard(id) else "Locked. Keep playing and you'll hear this one.",
			"side": { "text": "Lyrics", "pick": func(): _lyrics(i), "enabled": func(): return is_heard(id) },
			"side2": { "text": "Save", "pick": func(): _save_song(i), "enabled": func(): return is_heard(id) },
		})
	rows.append({ "text": "Back", "pick": func(): menu.close() })
	menu = MenuUI.open(parent, "LIBRARY  ·  SOUNDTRACK", rows, { "w": 820, "font": 22, "footer": _now_playing(),
		"hint": "E play / pause · A/D skip 10 s · L or Y lyrics · K or X save · Esc back · mouse works too" })
	menu.closed.connect(func():
		player.stop()
		_duck_title(false))
	return menu

func _now_playing() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	var top := Control.new()
	top.custom_minimum_size = Vector2(0, 6)
	v.add_child(top)
	v.add_child(UITheme.Divider.new())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var btn := Control.new()   # big play/pause, clickable
	btn.custom_minimum_size = Vector2(34, 34)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and cur >= 0:
			UITheme.play("pick")
			_toggle(cur))
	now_icon = UITheme.Icon.new("note", 30)
	now_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_child(now_icon)
	h.add_child(btn)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 2)
	h.add_child(mid)
	now_lbl = UITheme.lbl("Pick a song", 17, "dim", UITheme.row_font())
	mid.add_child(now_lbl)
	bar = SeekBar.new()
	bar.seek.connect(func(r: float):
		if cur >= 0 and player.stream:
			player.play(r * player.stream.get_length())
			player.stream_paused = false)
	mid.add_child(bar)
	time_lbl = UITheme.lbl("0:00 / 0:00", 15, "dim")
	time_lbl.size_flags_vertical = Control.SIZE_SHRINK_END
	h.add_child(time_lbl)
	return v

func _process(_d: float) -> void:
	if not is_instance_valid(now_lbl):
		return
	var has := cur >= 0 and player.stream != null
	var length: float = player.stream.get_length() if has else 0.0
	var pos := player.get_playback_position() if has and (player.playing or player.stream_paused) else 0.0
	now_lbl.text = ("%s  —  %s" % [SONGS[cur]["title"], SONGS[cur]["by"]]) if has else "Pick a song"
	now_lbl.add_theme_color_override("font_color", UITheme.c("accent") if _playing(cur) else UITheme.c("dim"))
	time_lbl.text = "%s / %s" % [_mmss(pos), _mmss(length)]
	time_lbl.add_theme_color_override("font_color", UITheme.c("dim"))
	bar.ratio = pos / length if length > 0.0 else 0.0
	bar.queue_redraw()
	now_icon.set_kind("note" if not has else ("pause" if _playing(cur) else "play"), UITheme.c("accent"))

func _playing(i: int) -> bool:
	return i >= 0 and i == cur and player.playing and not player.stream_paused

func _dur(i: int) -> String:
	var st = load(_song_path(SONGS[i]["id"]))
	return _mmss(st.get_length()) if st else ""

# The Library plays the full version of a song (id + "_full.ogg": the real ending) when there is one; the game's
# area music is the loop-trimmed id.ogg.
# Save (Ebain 11/26): copies an unlocked song's .ogg to Downloads/Trio Adventures Soundtrack/<Title>.ogg and opens
# the folder (browser build: a normal browser download). The raw .ogg is only in the builds because export_presets.cfg includes "assets/music/*.ogg".
const SAVE_DIR := "Trio Adventures Soundtrack"

func _save_song(i: int) -> void:
	var s: Dictionary = SONGS[i]
	if not is_heard(s["id"]):
		return
	if OS.has_feature("web"):   # browser build: hand the file to the browser's own download
		var bytes := FileAccess.get_file_as_bytes(_song_path(s["id"]))
		if not bytes.is_empty():
			JavaScriptBridge.download_buffer(bytes, String(s["title"]).validate_filename() + ".ogg", "audio/ogg")
		if is_instance_valid(menu):
			menu.set_note(("Downloading \"%s\"." % s["title"]) if not bytes.is_empty() else "Couldn't save that one. Try again?")
		return
	var r := save_song(s["id"])
	if is_instance_valid(menu):
		menu.set_note(("Saved \"%s\" to Downloads → %s." % [s["title"], SAVE_DIR]) if r != "" else "Couldn't save that one. Try again?")
	if r != "" and not Engine.has_meta("no_shell"):
		OS.shell_show_in_file_manager(r)

# Returns the saved file's path, or "" if it failed.
static func save_song(id: String) -> String:
	var title := id
	for s in SONGS:
		if s["id"] == id:
			title = s["title"]
	var bytes := FileAccess.get_file_as_bytes(_song_path(id))
	if bytes.is_empty():
		return ""
	var base := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if base == "":
		base = OS.get_user_data_dir()
	var dir := base.path_join(SAVE_DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	var out := dir.path_join(title.validate_filename() + ".ogg")
	var f := FileAccess.open(out, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_buffer(bytes)
	f.close()
	return out

static func _song_path(id: String) -> String:
	var full := "res://assets/music/%s_full.ogg" % id
	return full if ResourceLoader.exists(full) else "res://assets/music/%s.ogg" % id

static func _mmss(t: float) -> String:
	var s := int(t)
	return "%d:%02d" % [s / 60, s % 60]

func _toggle(i: int) -> void:
	if not is_heard(SONGS[i]["id"]):
		UITheme.play("back")
		return
	if i == cur and player.stream:
		if player.stream_paused:
			player.stream_paused = false
		elif player.playing:
			player.stream_paused = true
		else:
			player.play()
	else:
		var st: AudioStream = load(_song_path(SONGS[i]["id"]))
		if st is AudioStreamOggVorbis:   # the Library plays each song through once
			st = st.duplicate()
			st.loop = false
		cur = i
		player.stream = st
		player.stream_paused = false
		player.play()
	if _playing(cur):
		_duck_title(true)
	menu.refresh()

func _skip(i: int, d: int) -> void:
	if i == cur and player.playing:
		player.seek(clampf(player.get_playback_position() + d * 10.0, 0.0, player.stream.get_length() - 0.5))

func _duck_title(down: bool) -> void:
	if title_music == null or not is_instance_valid(title_music) or down == _title_ducked:
		return
	_title_ducked = down
	var tw := title_music.create_tween()
	if down:
		_title_db = title_music.volume_db
		tw.tween_property(title_music, "volume_db", -40.0, 0.6)
		tw.tween_callback(func(): title_music.stream_paused = true)
	else:
		title_music.stream_paused = false
		tw.tween_property(title_music, "volume_db", _title_db, 1.2)

func _on_closed() -> void:
	player.stop()
	_duck_title(false)
	closed.emit()
	queue_free()

# ---------------------------------------------------------------- lyrics page (always parchment)
func _lyrics(i: int) -> void:
	if is_instance_valid(page) or not is_heard(SONGS[i]["id"]):
		return
	page = LyricsPage.new()
	_ui.add_child(page)
	page.build(SONGS[i])
	await page.tree_exited
	if is_instance_valid(menu):
		menu.refresh()

class LyricsPage extends Control:
	var scroll: ScrollContainer
	var _at := 0

	func build(s: Dictionary) -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.5)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dim)
		var P := UITheme.PARCHMENT
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UITheme.panel(0.99, P))
		p.anchor_left = 0.5; p.anchor_right = 0.5; p.anchor_top = 0.5; p.anchor_bottom = 0.5
		p.offset_left = -340; p.offset_right = 340; p.offset_top = -300; p.offset_bottom = 300
		add_child(p)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		p.add_child(v)
		var t := UITheme.lbl(s["title"], 30, "accent", UITheme.head_font(), P)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
		var by := UITheme.lbl("by " + s["by"], 16, "dim", null, P)
		by.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(by)
		var dv := Control.new()   # parchment divider (UITheme.Divider follows the menu theme, this page doesn't)
		dv.custom_minimum_size = Vector2(0, 14)
		dv.draw.connect(func():
			var y := dv.size.y * 0.5
			var mid := dv.size.x * 0.5
			var e := UITheme.c("edge", P)
			dv.draw_polyline_colors([Vector2(mid * 0.2, y), Vector2(mid - 10, y)], [Color(e, 0.0), e], 1.5, true)
			dv.draw_polyline_colors([Vector2(mid + 10, y), Vector2(dv.size.x - mid * 0.2, y)], [e, Color(e, 0.0)], 1.5, true)
			dv.draw_colored_polygon([Vector2(mid, y - 5), Vector2(mid + 5, y), Vector2(mid, y + 5), Vector2(mid - 5, y)], UITheme.c("accent", P)))
		v.add_child(dv)
		scroll = ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		v.add_child(scroll)
		var text: String = String(Lyrics.TEXT.get(s["id"], "")).strip_edges()
		var body := UITheme.lbl(text if text != "" else "Lyrics coming soon.", 19, "text" if text != "" else "dim", null, P)
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.autowrap_mode = TextServer.AUTOWRAP_WORD
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(body)
		var hint := UITheme.lbl("W/S or wheel scroll · Esc, B or L close · the song keeps playing", 13, "faint", null, P)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(hint)
		MenuUI.stack.append(self)
		_at = Engine.get_process_frames()
		UITheme.play("page")
		p.size = Vector2(680, 600)
		UITheme.pop_in(p)

	func _input(ev: InputEvent) -> void:
		if MenuUI.stack.is_empty() or MenuUI.stack.back() != self or Engine.get_process_frames() - _at < 2:
			return
		if not (ev is InputEventKey or ev is InputEventJoypadButton or ev is InputEventJoypadMotion):
			return
		var handled := true
		if ev.is_action_pressed("ui_up") or ev.is_action_pressed("move_forward"):
			scroll.scroll_vertical -= 60
		elif ev.is_action_pressed("ui_down") or ev.is_action_pressed("move_back"):
			scroll.scroll_vertical += 60
		elif ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause") \
				or (ev is InputEventKey and ev.pressed and not ev.echo and ev.physical_keycode == KEY_L) \
				or (ev is InputEventJoypadButton and ev.pressed and ev.button_index in [JOY_BUTTON_B, JOY_BUTTON_Y]):
			UITheme.play("back")
			MenuUI.stack.erase(self)
			queue_free()
		else:
			handled = false
		if handled:
			get_viewport().set_input_as_handled()

	func _exit_tree() -> void:
		MenuUI.stack.erase(self)

# The now-playing bar: click or drag to seek.
class SeekBar extends Control:
	signal seek(r: float)
	var ratio := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(0, 16)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		var y := size.y * 0.5
		draw_line(Vector2(0, y), Vector2(size.x, y), UITheme.c("track"), 4.0, true)
		var x := size.x * clampf(ratio, 0.0, 1.0)
		draw_line(Vector2(0, y), Vector2(x, y), UITheme.c("accent"), 4.0, true)
		draw_colored_polygon([Vector2(x, y - 6), Vector2(x + 6, y), Vector2(x, y + 6), Vector2(x - 6, y)], UITheme.c("accent"))

	func _gui_input(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) \
				or (ev is InputEventMouseMotion and ev.button_mask & MOUSE_BUTTON_MASK_LEFT):
			seek.emit(clampf(ev.position.x / maxf(size.x, 1.0), 0.0, 1.0))
			accept_event()
