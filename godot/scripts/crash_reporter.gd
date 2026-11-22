# Crash + freeze reports. Started by the Game autoload, runs the whole time, costs almost nothing.
#
# Writes an in-depth Markdown report into a "Crash Reports" folder next to TrioAdventures.exe
# (user://Crash Reports when running from the editor/sandbox, or if the game folder isn't writable) when:
#   • the game FREEZES: a watchdog thread notices no frame has run for FREEZE_SECS seconds. If the game
#     comes back, the report gets a "recovered after N s" note (a long stall, not a hard freeze).
#   • the game CRASHES or is FORCE-CLOSED (Task Manager, power loss): every session leaves a marker file
#     that a normal quit deletes. If the marker is still there on the next launch, the last session died,
#     and the report is built from what was saved to disk every 2 s (recent events, game state) plus the
#     end of Godot's own log from that session (which holds the engine backtrace if it really crashed).
#
# A report says what probably happened, what the player was doing (scene, dialogue line, fight, menu),
# the last ~80 things that happened, every engine/script error, and the PC's specs.
# Nothing here is sent anywhere: players hand the file over (Crash Reports/README.md in the repo explains).
#
# Other scripts can add their own breadcrumbs:  CrashReporter.note("Started the chug-off")
extends Node
class_name CrashReporter

const FREEZE_SECS := 12.0
const RING_MAX := 300
const CRASH_DIR := "user://crash"            # marker + the rolling copies of events/state
const MARKER := CRASH_DIR + "/session_running.txt"
const EVENTS_FILE := CRASH_DIR + "/last_session_events.txt"
const STATE_FILE := CRASH_DIR + "/last_session_state.txt"

static var instance: CrashReporter

var mutex := Mutex.new()
var ring: PackedStringArray = []      # "[mm:ss.s] text"
var errors: PackedStringArray = []    # last errors, newest last
var state_text := ""                  # snapshot of what the player is doing (refreshed on the main thread)
var system_text := ""
var heartbeat_ms := 0
var started_ms := 0
var started_at := ""
var running := true
var thread: Thread
var freeze_report_path := ""          # set while a freeze is "open" (not recovered yet)
var freeze_started_ms := 0
var _last_seen := {}                  # what _poll saw last (to log changes only)
var _poll_t := 0.0
var _save_due_ms := 0
var _logger: _CrashLogger

# ---------------------------------------------------------------- public

static func note(text: String) -> void:
	if instance:
		instance._crumb(text)

# ---------------------------------------------------------------- startup / shutdown

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	name = "CrashReporter"
	started_ms = Time.get_ticks_msec()
	heartbeat_ms = started_ms
	started_at = Time.get_datetime_string_from_system(false, true)
	DirAccess.make_dir_recursive_absolute(CRASH_DIR)
	system_text = _system_info()
	# did the last session die?
	if FileAccess.file_exists(MARKER):
		_report_previous_session()
	_write_file(MARKER, "started=%s\nfreeze_report=\n" % started_at)
	_logger = _CrashLogger.new()
	_logger.reporter = weakref(self)
	OS.add_logger(_logger)
	_crumb("Game started (%s)" % started_at)
	thread = Thread.new()
	thread.start(_watchdog)

func _exit_tree() -> void:
	_shutdown()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_shutdown()

func _shutdown() -> void:
	if not running:
		return
	running = false
	if thread and thread.is_started():
		thread.wait_to_finish()
	if _logger:
		OS.remove_logger(_logger)
	DirAccess.remove_absolute(MARKER)   # normal quit: no report next time

# ---------------------------------------------------------------- main thread: heartbeat + watching what happens

func _process(delta: float) -> void:
	mutex.lock()
	heartbeat_ms = Time.get_ticks_msec()
	mutex.unlock()
	_poll_t -= delta
	if _poll_t <= 0.0:
		_poll_t = 0.25
		_poll()

# Look at the game (scene, dialogue, fights, menus) and log what changed. Reads other scripts' vars with get(),
# so nobody has to call us.
func _poll() -> void:
	var tree := get_tree()
	var sc: Node = tree.current_scene
	var scene := sc.scene_file_path if sc else "(none)"
	_changed("scene", scene, "Scene: %s" % scene)
	if sc == null:
		return
	var game: Node = get_node_or_null("/root/Game")
	if game and game.get("changing") != null:
		_changed("loading", str(game.get("changing")), "Loading a new area…" if game.get("changing") else "")
	var d = sc.get("dialogue")
	var line := ""
	if d and d.get("active") and d.get("panel") and d.panel.visible:
		var who: String = d.name_lbl.text if d.get("name_lbl") else ""
		var txt: String = d.text_lbl.get_parsed_text() if d.get("text_lbl") else ""
		line = ("%s: \"%s\"" % [who, txt]) if who != "" else "\"%s\"" % txt
		if d.get("_choices") and d._choices.size() > 0:
			line = "Choice on screen (%d options)" % d._choices.size()
	_changed("dialogue", line, ("Dialogue — " + line.left(160)) if line != "" else "Dialogue closed")
	var fight := ""
	var fight_msg := ""
	for ch in sc.get_children():
		if ch.get_class() != "" and ch.get_script() and str(ch.get_script().resource_path).ends_with("battle_view.gd"):
			fight = str(ch.get("key"))
			var ll = ch.get("log_lbl")   # the fight's message line ("Lykor uses Hair Flip…", "Big Thumbs is down!")
			if ll:
				fight_msg = ll.text
	_changed("fight", fight, ("Fight started: %s" % fight) if fight != "" else "Fight ended")
	_changed("fight_msg", fight_msg, ("Fight — " + fight_msg.left(200)) if fight_msg != "" else "")
	var menu = sc.get("_menu_kind")
	_changed("menu", str(menu) if menu != null else "", ("Menu open: %s" % menu) if menu else "Menu closed")
	# snapshot for the reports (cheap, every 0.25 s)
	var st := _state_snapshot(sc, game, line, fight)
	mutex.lock()
	state_text = st
	mutex.unlock()

func _changed(k: String, v: String, msg: String) -> void:
	if _last_seen.get(k, null) == v:
		return
	var first := not _last_seen.has(k)
	_last_seen[k] = v
	if msg != "" and not (first and v == ""):
		_crumb(msg)

func _state_snapshot(sc: Node, game: Node, line: String, fight: String) -> String:
	var o := PackedStringArray()
	o.append("- **Area:** %s" % sc.scene_file_path)
	var leader = sc.get("leader")
	if leader:
		o.append("- **Controlling:** %s at %s" % [leader.get("display_name"), str(leader.global_position).replace(" ", "")])
	if sc.get("busy") != null:
		o.append("- **Player input locked (cutscene/menu/dialogue):** %s" % sc.get("busy"))
	o.append("- **Dialogue on screen:** %s" % (line if line != "" else "no"))
	o.append("- **In a fight:** %s" % (fight if fight != "" else "no"))
	var menu = sc.get("_menu_kind")
	o.append("- **Menu open:** %s" % (menu if menu else "no"))
	if game:
		o.append("- **Party:** level %s, %s XP, %s gold" % [game.get("level"), game.get("xp"), game.get("gold")])
		o.append("- **Bags:** %s" % str(game.get("bags")))
		o.append("- **Equipped:** %s" % str(game.get("equipped")))
		var fl: Dictionary = game.get("flags") if game.get("flags") is Dictionary else {}
		var on := []
		for f in fl:
			if fl[f]:
				on.append(f)
		o.append("- **Story flags on:** %s" % (", ".join(on) if not on.is_empty() else "none"))
		o.append("- **Settings:** voices %s · graphics %s · difficulty %s" % ["on" if game.get("tts_on") else "off", ["Low", "Medium", "High"][clampi(int(game.get("quality") if game.get("quality") != null else 2), 0, 2)], game.get("difficulty")])
	o.append("- **FPS:** %d · **objects:** %d · **memory used:** %.0f MB · **triangles drawn:** %d" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.OBJECT_COUNT), OS.get_static_memory_usage() / 1048576.0, Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	o.append("- **Time since the game started:** %s" % _dur(Time.get_ticks_msec() - started_ms))
	return "\n".join(o)

# ---------------------------------------------------------------- breadcrumbs (any thread)

func _crumb(text: String) -> void:
	var t := (Time.get_ticks_msec() - started_ms) / 1000.0
	var s := "[%02d:%04.1f] %s" % [int(t / 60), fmod(t, 60.0), text.replace("\n", " ").strip_edges().left(400)]
	mutex.lock()
	ring.append(s)
	if ring.size() > RING_MAX:
		ring = ring.slice(ring.size() - RING_MAX)
	mutex.unlock()

func _error(text: String) -> void:
	_crumb(text)
	mutex.lock()
	errors.append("[%s] %s" % [_dur(Time.get_ticks_msec() - started_ms), text.left(1200)])
	if errors.size() > 60:
		errors = errors.slice(errors.size() - 60)
	mutex.unlock()

# ---------------------------------------------------------------- watchdog thread

func _watchdog() -> void:
	while running:
		OS.delay_msec(500)
		var now := Time.get_ticks_msec()
		mutex.lock()
		var hb := heartbeat_ms
		mutex.unlock()
		var stalled := now - hb
		if freeze_report_path == "" and stalled > FREEZE_SECS * 1000.0:
			freeze_started_ms = hb
			freeze_report_path = _write_report("Freeze", "The game stopped responding: no frame has been drawn for %d seconds." % int(stalled / 1000.0), "")
			_write_file(MARKER, "started=%s\nfreeze_report=%s\n" % [started_at, freeze_report_path])
		elif freeze_report_path != "" and stalled < 1500:
			_append(freeze_report_path, "\n## Update: it came back\nThe game started responding again after **%.1f seconds**, so this was a long stall, not a permanent freeze. (Common causes: loading an area or compiling shaders on a slow PC.)\n" % ((hb - freeze_started_ms) / 1000.0))
			_crumb("Recovered from a %.1f s stall" % ((hb - freeze_started_ms) / 1000.0))
			freeze_report_path = ""
			_write_file(MARKER, "started=%s\nfreeze_report=\n" % started_at)
		if now >= _save_due_ms:   # keep a copy on disk in case the whole game dies
			_save_due_ms = now + 2000
			mutex.lock()
			var ev := "\n".join(ring)
			var st := state_text
			var er := "\n".join(errors)
			mutex.unlock()
			_write_file(EVENTS_FILE, ev)
			_write_file(STATE_FILE, "%s\n%s\n%s" % [st, "@@ERRORS@@", er])

# ---------------------------------------------------------------- reports

# kind = "Freeze" / "Crash". Returns the file path.
func _write_report(kind: String, headline: String, prev_log: String, prev := {}) -> String:
	mutex.lock()
	var ev: PackedStringArray = prev.get("events", ring.duplicate())
	var st: String = prev.get("state", state_text)
	var er: PackedStringArray = prev.get("errors", errors.duplicate())
	mutex.unlock()
	var when := Time.get_datetime_string_from_system(false, true)
	var md := PackedStringArray()
	md.append("# Trio Adventures — %s Report" % kind)
	md.append("")
	md.append("**What happened:** %s  " % headline)
	md.append("**Report written:** %s  " % when)
	if prev.has("started"):
		md.append("**That session started:** %s  " % prev["started"])
	md.append("")
	md.append("## What probably caused it")
	for c in _likely_causes(kind, ev, er, st, prev_log):
		md.append("- " + c)
	md.append("")
	md.append("## What the player was doing")
	md.append(st if st != "" else "_(no snapshot yet: it happened right at startup)_")
	md.append("")
	md.append("## Last things that happened (newest at the bottom)")
	md.append("```")
	md.append("\n".join(ev.slice(maxi(0, ev.size() - 80))))
	md.append("```")
	md.append("")
	md.append("## Engine / script errors this session")
	if er.is_empty():
		md.append("None logged.")
	else:
		md.append("```")
		md.append("\n".join(er))
		md.append("```")
	md.append("")
	md.append("## PC")
	md.append(system_text)
	if prev_log != "":
		md.append("")
		md.append("## End of Godot's log from that session")
		md.append("```")
		md.append(prev_log)
		md.append("```")
	md.append("")
	md.append("---")
	md.append("_For the Claude reading this: check TIPS.md (known gotchas like the Windows TTS deadlock) and COLLAB.md, then log what you find._")
	var stamp := when.replace(":", "-").replace("T", " ")
	var path := report_dir().path_join("%s %s.md" % [kind, stamp])
	_write_file(path, "\n".join(md))
	_crumb("%s report written: %s" % [kind, path])
	return path

func _report_previous_session() -> void:
	var marker := FileAccess.get_file_as_string(MARKER)
	var prev := { "started": "", "events": PackedStringArray(), "state": "", "errors": PackedStringArray() }
	var freeze_path := ""
	for l in marker.split("\n"):
		if l.begins_with("started="):
			prev["started"] = l.substr(8)
		elif l.begins_with("freeze_report="):
			freeze_path = l.substr(14).strip_edges()
	if FileAccess.file_exists(EVENTS_FILE):
		prev["events"] = FileAccess.get_file_as_string(EVENTS_FILE).split("\n", false)
	if FileAccess.file_exists(STATE_FILE):
		var parts := FileAccess.get_file_as_string(STATE_FILE).split("\n@@ERRORS@@\n")
		prev["state"] = parts[0]
		if parts.size() > 1:
			prev["errors"] = parts[1].split("\n", false)
	var log_tail := _previous_log_tail(80)
	if freeze_path != "" and FileAccess.file_exists(freeze_path):
		# we already wrote a freeze report for that session; it never recovered, so it was force-closed
		_append(freeze_path, "\n## Update: it never came back\nThe game was closed without quitting normally after this freeze (probably Task Manager), so it was a **hard freeze**.\n\n## End of Godot's log from that session\n```\n%s\n```\n" % log_tail)
		_show_notice("The game froze last time. The freeze report was saved to:\n" + freeze_path)
		return
	var crashed := log_tail.find("Program crashed") >= 0 or log_tail.find("CrashHandler") >= 0 or (log_tail.find("signal ") >= 0 and log_tail.find("backtrace") >= 0)
	var headline := "The game **crashed** (the engine itself died; its backtrace is at the bottom)." if crashed else "The game closed without quitting normally (a crash, Task Manager, or the PC shutting off)."
	var path := _write_report("Crash", headline, log_tail, prev)
	_show_notice("The game didn't close properly last time. A crash report was saved to:\n" + path)

func _likely_causes(kind: String, ev: PackedStringArray, er: PackedStringArray, st: String, log_tail: String) -> PackedStringArray:
	var out := PackedStringArray()
	var last := "\n".join(ev.slice(maxi(0, ev.size() - 12)))
	var recent_err := ""
	for i in range(ev.size() - 1, maxi(-1, ev.size() - 15), -1):
		if ev[i].find("ERROR:") >= 0 or ev[i].find("ERROR ") >= 0:
			recent_err = ev[i]
			break
	if log_tail.find("Program crashed") >= 0 or log_tail.find("CrashHandler") >= 0:
		out.append("**The Godot engine crashed** (native crash, not a script problem). The backtrace in the log section shows where.")
	if "\n".join(er).to_lower().find("out of memory") >= 0 or log_tail.to_lower().find("out of memory") >= 0:
		out.append("**Ran out of memory.**")
	if recent_err != "":
		out.append("An error was logged right before it happened: `%s`" % recent_err.get_slice("GDScript backtrace", 0).strip_edges().left(300))
	if st.find("**Dialogue on screen:** no") < 0 and st.find("**Dialogue on screen:**") >= 0:
		out.append("A **dialogue line was on screen**. On Windows the robot voice (TTS) has caused hard freezes before (TIPS.md: never call `tts_stop()` or speak with `interrupt=true`). If this is a freeze during dialogue, start there.")
	if st.find("**In a fight:** no") < 0 and st.find("**In a fight:**") >= 0:
		out.append("It happened **during a fight** (see the fight key above). Check battle_view.gd / battle.gd for the last action in the event list.")
	if last.find("Loading a new area") >= 0:
		out.append("It happened **while loading an area**. If it recovered, it was just slow (first launch compiles shaders). If not, the scene being loaded is the suspect.")
	if st.find("**Menu open:** no") < 0 and st.find("**Menu open:**") >= 0:
		out.append("A **menu was open** at the time.")
	if out.is_empty():
		out.append("Nothing obvious was logged right before it. Read the last events from the bottom up: the last thing that happened is the best clue.")
	if kind == "Crash" and log_tail == "":
		out.append("(Godot's log from that session was empty, which usually means the game was killed hard, e.g. from Task Manager.)")
	return out

# ---------------------------------------------------------------- helpers

# Where reports go: "Crash Reports" next to the exe in the real game; user:// otherwise or if that's not writable.
func report_dir() -> String:
	var tried := []
	if OS.get_environment("CRASH_REPORT_DIR") != "":
		tried.append(OS.get_environment("CRASH_REPORT_DIR"))
	if OS.has_feature("template"):
		tried.append(OS.get_executable_path().get_base_dir().path_join("Crash Reports"))
	tried.append(ProjectSettings.globalize_path("user://Crash Reports"))
	for d in tried:
		if DirAccess.make_dir_recursive_absolute(d) == OK or DirAccess.dir_exists_absolute(d):
			var probe := FileAccess.open(d.path_join(".write_test"), FileAccess.WRITE)
			if probe:
				probe.close()
				DirAccess.remove_absolute(d.path_join(".write_test"))
				return d
	return ProjectSettings.globalize_path("user://")

func _previous_log_tail(n: int) -> String:
	# Godot renames the last session's godot.log to godot<date>.log when a new session starts.
	var d := DirAccess.open("user://logs")
	if d == null:
		return ""
	var newest := ""
	var newest_t := 0
	for f in d.get_files():
		if f.begins_with("godot") and f.ends_with(".log") and f != "godot.log":
			var t := FileAccess.get_modified_time("user://logs/" + f)
			if t > newest_t:
				newest_t = t
				newest = f
	if newest == "":
		return ""
	var lines := FileAccess.get_file_as_string("user://logs/" + newest).split("\n")
	return "\n".join(lines.slice(maxi(0, lines.size() - n))).strip_edges()

func _system_info() -> String:
	var o := PackedStringArray()
	var v := Engine.get_version_info()
	o.append("- **OS:** %s %s" % [OS.get_name(), OS.get_version()])
	o.append("- **CPU:** %s (%d threads)" % [OS.get_processor_name(), OS.get_processor_count()])
	var mem := OS.get_memory_info()
	o.append("- **RAM:** %.1f GB total, %.1f GB free at startup" % [mem.get("physical", 0) / 1073741824.0, mem.get("free", 0) / 1073741824.0])
	o.append("- **GPU:** %s (%s) · %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor(), RenderingServer.get_video_adapter_api_version()])
	o.append("- **Renderer:** %s" % RenderingServer.get_current_rendering_method())
	o.append("- **Screen:** %s · window %s" % [str(DisplayServer.screen_get_size()), str(DisplayServer.window_get_size())])
	o.append("- **Godot:** %s" % v.get("string", ""))
	var pck := OS.get_executable_path().get_basename() + ".pck"
	if FileAccess.file_exists(pck):
		o.append("- **Game data (.pck) built:** %s" % Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(pck), true))
	return "\n".join(o)

func _dur(ms: int) -> String:
	var s := ms / 1000
	return "%d:%02d" % [s / 60, s % 60]

func _write_file(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()

func _append(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_string(text)
		f.close()

func _show_notice(text: String) -> void:
	_crumb("Showed notice: " + text.replace("\n", " "))
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child.call_deferred(layer)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color("#ffd27a"))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.position = Vector2(140, 14)
	l.size = Vector2(1000, 60)
	layer.add_child(l)
	get_tree().create_timer(12.0).timeout.connect(func(): layer.queue_free())

# Catches every print, warning and error from the engine and scripts (any thread).
class _CrashLogger extends Logger:
	var reporter: WeakRef
	const TYPES := ["ERROR", "WARNING", "SCRIPT ERROR", "SHADER ERROR"]
	func _log_message(message: String, error: bool) -> void:
		var r = reporter.get_ref() if reporter else null
		if r and not message.strip_edges().is_empty():
			r._crumb(("stderr: " if error else "print: ") + message)
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, script_backtraces: Array) -> void:
		var r = reporter.get_ref() if reporter else null
		if r == null:
			return
		if error_type == 1:   # warnings: breadcrumb only
			r._crumb("WARNING: %s (%s:%d)" % [rationale if rationale != "" else code, file.get_file(), line])
			return
		var t: String = TYPES[clampi(error_type, 0, TYPES.size() - 1)]
		var msg := "%s: %s — %s:%d in %s()" % [t, rationale if rationale != "" else code, file, line, function]
		for bt in script_backtraces:
			msg += "\n    " + str(bt).replace("\n", "\n    ")
		r._error(msg)
