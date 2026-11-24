# Explorer bot (Asar 11/23): plays Trio Adventures on its own, at random, looking for bugs nobody planned for.
# The screenshot tours follow a fixed route. This bot makes its own choices instead: it wanders, walks up to
# things and presses E, reads every line, picks random dialogue choices, mashes through minigames, auto-plays fights,
# and keeps going area to area. It writes a report with screenshots of anything that went wrong.
#
# Run (with pictures):
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --path godot --rendering-method gl_compatibility \
#     --rendering-driver opengl3 --resolution 960x540 --audio-driver Dummy --script res://tools/explorer_bot.gd
# Run (fast, no pictures): godot --headless --path godot --audio-driver Dummy --script res://tools/explorer_bot.gd
#
# Settings (env vars):
#   BOT_MINUTES=15     how long to play (real time)
#   BOT_SEED=12345     the random seed. Same seed = the bot makes the same picks (timing can still differ a bit)
#   BOT_DIR=path       where report.md + shots/ go (default user://bot)
#   BOT_SHOT_EVERY=30  a screenshot every N seconds of play (plus one per area, fight and problem)
#   BOT_SPEED=1.0      game speed. 10 = ten times as fast (Ebain 11/24). Physics ticks scale with it, so walls and
#                      fights behave the same as at 1x; the only limit is how fast the machine is. The report says
#                      how fast it really ran ("Effective speed"). Headless only (pictures can't keep up)
#   BOT_START=res://summit.tscn   start in that area instead of a New Game (no story flags set, like an old save)
#
# What counts as a problem (makes the run fail, exit code 1):
#   error     a script/engine error (warnings don't count)
#   softlock  nothing on screen to press, nobody can move, for 90 s
#   dialogue  the same dialogue line or choice won't go away for 40 s (minigames don't count)
#   fell      a character ended up below the floor
#   fight     one fight lasted over 8 minutes
#   freeze    one frame took over 8 seconds
# It overwrites the autosave/progress files in user://, so run it in CI or the sandbox, not on your own PC.
extends Node

const SOFTLOCK_S := 90.0
const DIALOGUE_S := 40.0
const FIGHT_S := 480.0
const FREEZE_MS := 8000
const MAX_SHOTS := 150
# Engine noise that isn't a game bug (no sound card / no speech engine on the test machine)
const IGNORE := ["tts", "speech", "alsa", "pulseaudio", "audio driver", "Identifier not found: Game"]

var G: Node                      # the Game autoload
var rng := RandomNumberGenerator.new()
var seed_val := 0
var minutes := 15.0
var asked_speed := 1.0
var out_dir := "user://bot"
var shot_every := 30.0
var pics := true
var start_ms := 0
var play_t := 0.0                # game seconds played
var finished := false

var lv: Node = null              # the current area (a Level), or null
var area := ""
var scene_seen_at := 0.0
var problems: Array = []         # [{kind, msg, area, t, shot, crumbs}]
var problem_count := {}          # same problem again → just counted
var crumbs: Array = []           # [time, text], the bot's diary
var stats := { "areas": [], "fights": 0, "choices": 0, "uses": 0, "lines": 0, "chapters": 0, "shots": 0, "switches": 0 }
var shot_n := 0
var shot_t := 0.0

# walking
var target := {}                 # {pos, it, kind, key}
var target_t := 0.0
var check_pos := Vector3.ZERO
var check_t := 0.0
var dodge_t := 0.0
var dodge_dir := Vector3.ZERO
var fails := 0
var used := {}                   # interactable key → times used / failed
var last_good := Vector3.ZERO
var running := false

# watchdogs + pacing
var press_t := 0.0
var busy_t := 0.0
var busy_pos := Vector3.ZERO
var dlg_key := ""
var dlg_t := 0.0
var battle: Node = null
var battle_t := 0.0
var ui_node: Node = null
var ui_t := 0.0
var ui_presses := 0
var hold_t := 0.0
var last_frame := 0
var title_t := 0.0
var song_t := {}                 # AreaMusic → seconds it has been playing (no-sound-card shim)

# ================================================================ start / end
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	seed_val = int(_env("BOT_SEED", str(randi() % 1000000)))
	minutes = float(_env("BOT_MINUTES", "15"))
	out_dir = _env("BOT_DIR", "user://bot")
	shot_every = float(_env("BOT_SHOT_EVERY", "30"))
	var spd := maxf(0.1, float(_env("BOT_SPEED", "1.0")))
	asked_speed = spd
	Engine.time_scale = spd
	# keep each physics step 1/60 s of game time at any speed (big steps let people walk through walls)
	Engine.physics_ticks_per_second = int(round(60.0 * maxf(1.0, spd)))
	Engine.max_physics_steps_per_frame = maxi(8, int(ceil(8.0 * spd)))
	Engine.max_fps = 0
	pics = DisplayServer.get_name() != "headless"
	seed(seed_val)
	rng.seed = seed_val
	DirAccess.make_dir_recursive_absolute(out_dir + "/shots")
	var logger := BotLogger.new()
	logger.bot = self
	OS.add_logger(logger)
	G = get_tree().root.get_node("Game")
	start_ms = Time.get_ticks_msec()
	last_frame = start_ms
	print("BOT: seed %d, %s min, pictures %s, report in %s" % [seed_val, minutes, "on" if pics else "off", ProjectSettings.globalize_path(out_dir)])
	_new_run.call_deferred()

func _new_run() -> void:
	_settings()
	var start := _env("BOT_START", "")
	if start != "" and stats["chapters"] == 0:
		_crumb("Started in %s" % start)
		G.title_mode = false
		G.goto(start)
		return
	_crumb("Started a new game")
	G.new_game()

func _settings() -> void:
	G.tts_on = false          # no speech engine on test machines
	G.timed_auto = true       # timed hits resolve on their own
	G.quality = 0             # Low graphics: CPU rendering is slow
	G.dev_autowin = false

func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return d if v.is_empty() else v

func _finish() -> void:
	if finished:
		return
	finished = true
	_release_all()
	_crumb("Time's up")
	if pics and lv:
		await _snap("zz_end")
	_write_report()
	print("BOT DONE: %d problem(s), effective speed %.1fx. Report: %s" % [problems.size(), play_t / maxf(0.001, (Time.get_ticks_msec() - start_ms) / 1000.0), ProjectSettings.globalize_path(out_dir + "/report.md")])
	get_tree().quit(1 if not problems.is_empty() else 0)

# ================================================================ main loop
func _process(delta: float) -> void:
	if finished:
		return
	var now := Time.get_ticks_msec()
	if now - last_frame > FREEZE_MS and play_t > 5.0:
		_problem("freeze", "One frame took %.1f s (the game froze)." % ((now - last_frame) / 1000.0))
	last_frame = now
	if now - start_ms > minutes * 60000.0:
		_finish()
		return
	play_t += delta
	if Engine.time_scale == 1.0 and asked_speed != 1.0:   # the summit's slow-mo resets to 1.0: back to bot speed
		Engine.time_scale = asked_speed
	var cur := get_tree().current_scene
	if cur != lv:
		_entered(cur)
	if lv == null or G.changing:
		_title_check(cur, delta)
		return
	_tick(delta)
	return

func _entered(cur: Node) -> void:
	_release_all()
	if lv and is_instance_valid(lv):
		lv.auto_dir = Vector3.ZERO
	lv = null
	song_t = {}
	target = {}
	battle = null
	busy_t = 0.0
	dlg_t = 0.0
	if cur == null or not (cur is Level):
		return
	lv = cur
	_settings()
	area = lv.area_key()
	if not stats["areas"].has(area):
		stats["areas"].append(area)
	_crumb("Entered %s" % area)
	scene_seen_at = play_t
	last_good = lv.leader.global_position
	_snap_later("enter_" + area, 2.5)

# The end card sends you to the title screen: count the chapter and start another run with new picks.
func _title_check(cur: Node, delta: float) -> void:
	if cur == null or G.changing or not cur.scene_file_path.ends_with("title.tscn"):
		title_t = 0.0
		return
	title_t += delta
	if title_t > 3.0:
		title_t = -999.0
		stats["chapters"] += 1
		_crumb("Back at the title screen (Chapter 1 finished). Starting a new run.")
		_new_run()

func _tick(delta: float) -> void:
	_songs(delta)
	shot_t += delta
	if shot_t >= shot_every:
		shot_t = 0.0
		_snap(area)
	press_t -= delta
	var dlg: Dialogue = lv.dialogue
	var bv := _battle_view()
	# ---- fights: BattleView's own auto-play picks every move (same as the tours)
	if bv:
		_stop_walking()
		if bv != battle:
			battle = bv
			battle_t = 0.0
			stats["fights"] += 1
			_crumb("Fight: %s" % str(bv.get("key")))
			_snap_later("fight_" + str(bv.get("key")), 4.0)
		bv.auto_play = true
		battle_t += delta
		if battle_t > FIGHT_S:
			_problem("fight", "The fight '%s' has been going for over %d minutes." % [str(bv.get("key")), int(FIGHT_S / 60)])
			battle_t = -99999.0
		return
	if battle:
		battle = null
		_crumb("Fight over (HP: %s)" % _hp_text())
	# ---- menus (MenuUI: yes/no boxes, pickers)
	if not MenuUI.stack.is_empty():
		_stop_walking()
		_menu(MenuUI.stack[-1], delta)
		return
	# ---- dialogue
	if dlg.active:
		_stop_walking()
		busy_t = 0.0
		_dialogue(dlg, delta)
		return
	dlg_key = ""
	dlg_t = 0.0
	# ---- other screens (shop, job board, inventory, map)
	if lv.busy or ui_node:
		_stop_walking()
		if _other_ui(delta):
			return
	if lv.busy:
		_busy(delta)
		return
	busy_t = 0.0
	_roam(delta)

# Test machines have no sound card (Dummy audio), so a song never plays and never ends. The summit waits for the
# hymn to finish ("Peep the song first folk") and would wait forever. So once a play-once song has been "on" for its
# full length, mark it finished, like it would be on a real PC.
func _songs(delta: float) -> void:
	if AudioServer.get_driver_name() != "Dummy":
		return
	for c in lv.get_children():
		if not (c is AreaMusic) or c.played_once or c.track == null:
			continue
		if c.track is AudioStreamOggVorbis and c.track.loop and not G.music_once:
			continue
		if c.state == "full" or c.state == "ducked":
			song_t[c] = song_t.get(c, 0.0) + delta / maxf(Engine.time_scale, 0.01)   # songs run in real time
			if song_t[c] >= c.track.get_length() + 2.0:
				c.played_once = true
				if c.player:
					c.player.stop()
				_crumb("(no sound card) the song \"%s\" counts as finished now" % c.track.resource_path.get_file().get_basename())

# ================================================================ dialogue, menus, cutscenes
func _dialogue(dlg: Dialogue, delta: float) -> void:
	var choices: Array = dlg._choices
	var text := str(dlg.text_lbl.text) if choices.is_empty() else " / ".join(choices.map(func(c): return str(c["text"])))
	var key := text + "|" + str(choices.size())
	if key != dlg_key:
		if dlg_key == "" and choices.is_empty():   # a new conversation: note its first line in the diary
			_crumb("Dialogue: %s: \"%s\"" % [str(dlg.name_lbl.text), _short(_plain(text))])
		dlg_key = key
		dlg_t = 0.0
		if choices.is_empty():
			stats["lines"] += 1
	if _minigame():   # Snore Sneak / chug-off run inside a dialogue: play them like a minigame, no stuck-timer
		dlg_t = 0.0
		_busy(delta)
		return
	dlg_t += delta
	if dlg_t > 5.0 and choices.is_empty():   # E isn't moving it on: something else is going on, try other keys too
		_busy(delta)
		busy_t = 0.0
		if dlg_t <= DIALOGUE_S:
			return
	if dlg_t > DIALOGUE_S:
		_problem("dialogue", "This dialogue wouldn't go away for %d s: \"%s\"" % [int(DIALOGUE_S), _short(_plain(text))])
		dlg_t = -99999.0
	if press_t > 0.0:
		return
	if not choices.is_empty():
		press_t = rng.randf_range(0.5, 1.0)
		var n := rng.randi_range(0, mini(choices.size(), 9) - 1)
		stats["choices"] += 1
		_crumb("Picked %d. \"%s\"" % [n + 1, _short(str(choices[n]["text"]))])
		_key(KEY_1 + n)
		return
	press_t = rng.randf_range(0.3, 0.55)
	if dlg.can_leave and not dlg.left and rng.randf() < 0.03:
		_crumb("Left a conversation with Esc")
		_action("ui_cancel")
	else:
		_action("interact")

func _menu(m: Node, delta: float) -> void:
	if m != ui_node:
		ui_node = m
		ui_t = 0.0
		_crumb("Menu: %s" % _short(str(m.get("title")) if m.get("title") != null else "menu"))
	ui_t += delta
	if press_t > 0.0:
		return
	press_t = rng.randf_range(0.6, 1.1)
	var rows: Array = m.rows
	var ok := []
	for i in rows.size():
		var txt := str(rows[i].get("text", "")).to_lower()
		if m._enabled(i) and not ("quit" in txt or "title" in txt or "load" in txt or "save" in txt or "delete" in txt):
			ok.append(i)
	if ok.is_empty() or rng.randf() < 0.3 or ui_t > 12.0:
		_crumb("Closed the menu")
		if m.on_back.is_valid():
			m.on_back.call()
		else:
			m.close()
		return
	m.sel = ok[rng.randi() % ok.size()]
	_crumb("Menu pick: \"%s\"" % _short(str(rows[m.sel].get("text", ""))))
	m._pick()

# Shop, job board, inventory, map: poke at it a few times (move, E), then back out.
func _other_ui(delta: float) -> bool:
	if ui_node == null or not is_instance_valid(ui_node) or not ui_node.is_inside_tree():
		ui_node = _find_ui(lv)
		ui_t = 0.0
		ui_presses = 0
		if ui_node:
			_crumb("Opened %s" % ui_node.get_script().get_global_name())
	if ui_node == null:
		return false
	ui_t += delta
	if press_t > 0.0:
		return true
	press_t = rng.randf_range(0.5, 0.9)
	ui_presses += 1
	if ui_t > 10.0:
		_crumb("Closed %s" % ui_node.get_script().get_global_name())
		ui_node.close()
		ui_node = null
	elif ui_presses > rng.randi_range(3, 6):
		_action("ui_cancel")
	else:
		_action(["ui_down", "ui_right", "interact", "ui_down"][rng.randi() % 4])
	return true

func _find_ui(n: Node) -> Node:
	for c in n.get_children():
		if c is ShopUI or c is JobBoardUI or c is InventoryUI or c is MapUI:
			return c
		if c is CanvasLayer or c is Control:
			var f := _find_ui(c)
			if f:
				return f
	return null

# Nobody can move and there's no dialogue: a cutscene, an end card or a minigame (chug = mash E, Snore Sneak = hold
# E, Lore Session = pick with arrows + E). Mix all three so every minigame gets played (badly).
func _minigame() -> bool:
	return lv.get("mini_running") == true or lv.get("chug_running") == true

func _busy(delta: float) -> void:
	busy_t += delta
	if _minigame():
		busy_t = 0.0
	if busy_t < 0.3:
		busy_pos = lv.leader.global_position
	if hold_t > 0.0:
		hold_t -= delta
		if hold_t <= 0.0:
			Input.action_release("interact")
	elif press_t <= 0.0:
		var r := rng.randf()
		if r < 0.6:
			press_t = 0.12
			_action("interact")
		elif r < 0.8:
			press_t = 0.1
			hold_t = rng.randf_range(0.6, 2.0)
			Input.action_press("interact")
		else:
			press_t = 0.3
			_action("ui_down")
	if busy_t > SOFTLOCK_S:
		if lv.leader.global_position.distance_to(busy_pos) < 0.5:
			_problem("softlock", "Stuck for %d s: no dialogue, no menu, nobody can move, and E/Esc do nothing." % int(SOFTLOCK_S))
			_action("ui_cancel")
		busy_t = 0.0

# ================================================================ walking around
func _roam(delta: float) -> void:
	var lp: Vector3 = lv.leader.global_position
	if lp.y < -4.0:
		_problem("fell", "%s fell through the floor at (%.1f, %.1f, %.1f)." % [lv.leader.display_name, lp.x, lp.y, lp.z])
		lv.leader.global_position = last_good + Vector3(0, 0.5, 0)
		target = {}
		return
	if lp.y > -1.0 and lv.leader.is_on_floor():
		last_good = lp
	if dodge_t > 0.0:
		dodge_t -= delta
		_steer(dodge_dir)
		return
	if target.is_empty() or target_t > 30.0:
		if not target.is_empty():
			used[target["key"]] = used.get(target["key"], 0) + 3   # took too long: try something else
		_pick_target()
		return
	target_t += delta
	var to: Vector3 = target["pos"] - lp
	to.y = 0.0
	var dist := to.length()
	var it: Dictionary = target["it"]
	if not it.is_empty():
		var near: Dictionary = lv._nearest_interactable()
		if not near.is_empty() and near.get("label") == it.get("label") and lv.interact_cooldown <= 0.0:
			_stop_walking()
			used[target["key"]] = used.get(target["key"], 0) + 1
			stats["uses"] += 1
			_crumb("%s %s" % [str(it.get("verb", "Used")), _short(str(it.get("label", "?")))])
			_action("interact")
			target = {}
			return
	elif dist < 1.6:
		target = {}
		return
	var want_run := dist > 7.0
	if want_run != running:
		running = want_run
		if running: Input.action_press("run")
		else: Input.action_release("run")
	_steer(to.normalized())
	check_t += delta
	if check_t > 2.5:
		if lp.distance_to(check_pos) < 0.7:   # walking into a wall: sidestep, give up after 3 tries
			fails += 1
			dodge_dir = to.normalized().rotated(Vector3.UP, (PI / 2.0) * (1 if rng.randf() < 0.5 else -1))
			dodge_t = rng.randf_range(0.8, 1.6)
			if fails >= 3:
				used[target["key"]] = used.get(target["key"], 0) + 3
				target = {}
		else:
			fails = 0
		check_pos = lp
		check_t = 0.0

func _pick_target() -> void:
	target_t = 0.0
	fails = 0
	check_t = 0.0
	check_pos = lv.leader.global_position
	if rng.randf() < 0.04 and lv.switch_enabled and lv.party.size() > 1:   # swap leader now and then (room bugs live here)
		stats["switches"] += 1
		_crumb("Switched character")
		_action("switch")
	var its: Array = []
	for it in lv.current_interactables():
		if used.get(_it_key(it), 0) < 2:
			its.append(it)
	var obj: Vector3 = lv.objective_at
	var r := rng.randf()
	var obj_chance := clampf(0.4 + (play_t - scene_seen_at) / 600.0, 0.4, 0.85)   # explore first, then follow the story
	if obj.is_finite() and r < obj_chance:
		var best := {}
		for it in lv.current_interactables():   # the objective is usually something to press E on
			if lv._it_pos(it).distance_to(obj) < 3.0:
				best = it
		target = { "pos": obj, "it": best, "kind": "objective", "key": "obj:" + str(obj.round()) }
	elif not its.is_empty() and r < maxf(0.85, obj_chance + 0.1):
		var lp: Vector3 = lv.leader.global_position
		var pick: Dictionary = its[rng.randi() % its.size()]
		for i in 2:   # lean toward nearby things
			var other: Dictionary = its[rng.randi() % its.size()]
			if lv._it_pos(other).distance_to(lp) < lv._it_pos(pick).distance_to(lp):
				pick = other
		target = { "pos": lv._it_pos(pick), "it": pick, "kind": "thing", "key": _it_key(pick) }
	else:
		var p: Vector3
		var b: Rect2 = lv.bounds
		if b.size != Vector2.ZERO and rng.randf() < 0.7:
			p = Vector3(rng.randf_range(b.position.x, b.end.x), 0, rng.randf_range(b.position.y, b.end.y))
		else:
			p = lv.leader.global_position + Vector3(rng.randf_range(-18, 18), 0, rng.randf_range(-18, 18))
		target = { "pos": p, "it": {}, "kind": "wander", "key": "wander" }

func _it_key(it: Dictionary) -> String:
	return "%s@%s" % [str(it.get("label", "?")), str(lv._it_pos(it).round())]

func _steer(w: Vector3) -> void:
	var b: Basis = lv.cam.global_transform.basis
	var r := Vector3(b.x.x, 0, b.x.z).normalized()
	var f := Vector3(-b.z.x, 0, -b.z.z).normalized()
	lv.auto_dir = Vector3(w.dot(r), 0, w.dot(f))
	if lv.auto_dir == Vector3.ZERO:
		lv.auto_dir = Vector3(0, 0, 0.01)

func _stop_walking() -> void:
	if lv:
		lv.auto_dir = Vector3.ZERO
	if running:
		running = false
		Input.action_release("run")

# ================================================================ input
func _action(a: String) -> void:
	var ev := InputEventAction.new()
	ev.action = a
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = a
	up.pressed = false
	_later(func(): Input.parse_input_event(up), 0.06)

func _key(k: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := ev.duplicate()
	up.pressed = false
	_later(func(): Input.parse_input_event(up), 0.06)

func _release_all() -> void:
	for a in ["interact", "run"]:
		if InputMap.has_action(a):
			Input.action_release(a)
	hold_t = 0.0
	running = false

func _later(f: Callable, s: float) -> void:
	get_tree().create_timer(s, true, false, true).timeout.connect(f)

# ================================================================ problems, diary, pictures
func _on_error(msg: String) -> void:
	var low := msg.to_lower()
	for ig in IGNORE:
		if ig.to_lower() in low:
			return
	_problem("error", msg)

func _problem(kind: String, msg: String) -> void:
	var key := kind + ":" + msg.left(160)
	if problem_count.has(key):
		problem_count[key] += 1
		return
	problem_count[key] = 1
	var shot := ""
	if pics and lv and is_instance_valid(lv):
		shot = _shot_name("PROBLEM_" + kind)
		_snap_named(shot)
	problems.append({ "kind": kind, "msg": msg, "area": area, "t": play_t, "shot": shot, "key": key,
		"crumbs": crumbs.slice(maxi(0, crumbs.size() - 12)) })
	print("BOT PROBLEM [%s] in %s at %s: %s" % [kind, area, _clock(play_t), msg])

func _crumb(text: String) -> void:
	crumbs.append([play_t, text])
	if crumbs.size() > 400:
		crumbs = crumbs.slice(100)
	print("BOT %s %s" % [_clock(play_t), text])

func _snap(label: String) -> void:
	if not pics or stats["shots"] >= MAX_SHOTS:
		return
	await _snap_named(_shot_name(label))

func _snap_later(label: String, s: float) -> void:
	_later(func(): if not finished: _snap(label), s)

func _shot_name(label: String) -> String:
	shot_n += 1
	return "%03d_%s.png" % [shot_n, label.validate_filename()]

func _snap_named(file: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(out_dir + "/shots/" + file)
		stats["shots"] += 1

func _write_report() -> void:
	var L := []
	var ok := problems.is_empty()
	L.append("# Explorer bot report")
	L.append("")
	L.append("**%s**" % ("No problems found." if ok else "Found %d problem(s)." % problems.size()))
	L.append("")
	L.append("- Seed: **%d** (replay the same picks: `BOT_SEED=%d`)" % [seed_val, seed_val])
	L.append("- Played: %s · areas: %s" % [_clock(play_t), " → ".join(stats["areas"]) if not stats["areas"].is_empty() else "none"])
	L.append("- Effective speed: %.1fx (asked for %sx)" % [play_t / maxf(0.001, (Time.get_ticks_msec() - start_ms) / 1000.0), str(asked_speed)])
	L.append("- Fights: %d · choices picked: %d · things used/talked to: %d · lines read: %d · character switches: %d" %
		[stats["fights"], stats["choices"], stats["uses"], stats["lines"], stats["switches"]])
	L.append("- Chapter 1 finished: %d time(s) · level %d · gold %d · story flags set: %d" % [stats["chapters"], G.level, G.gold, G.flags.size()])
	if not pics:
		L.append("- Pictures: off (headless run)")
	L.append("")
	for i in problems.size():
		var p: Dictionary = problems[i]
		var times: int = problem_count.get(p["key"], 1)
		L.append("## %d. %s in %s at %s%s" % [i + 1, _kind_name(p["kind"]), p["area"], _clock(p["t"]), " (happened %d times)" % times if times > 1 else ""])
		L.append("")
		L.append("```")
		L.append(p["msg"])
		L.append("```")
		if p["shot"] != "":
			L.append("Screenshot: `shots/%s`" % p["shot"])
		L.append("")
		L.append("What the bot did just before:")
		for c in p["crumbs"]:
			L.append("- %s %s" % [_clock(c[0]), c[1]])
		L.append("")
	L.append("## The last things the bot did")
	L.append("")
	for c in crumbs.slice(maxi(0, crumbs.size() - 40)):
		L.append("- %s %s" % [_clock(c[0]), c[1]])
	var f := FileAccess.open(out_dir + "/report.md", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(L) + "\n")

func _kind_name(k: String) -> String:
	return { "error": "Script error", "softlock": "Softlock", "dialogue": "Stuck dialogue", "fell": "Fell through the floor",
		"fight": "Endless fight", "freeze": "Freeze" }.get(k, k)

# ================================================================ helpers
func _battle_view() -> Node:
	for c in lv.get_children():
		if c is BattleView:
			return c
	return null

func _hp_text() -> String:
	var out := []
	for f in ["skorn", "lykor", "xylo"]:
		out.append("%s %d/%d" % [f, G.hp(f), G.max_hp(f)])
	return ", ".join(out)

func _clock(s: float) -> String:
	return "%d:%02d" % [int(s) / 60, int(s) % 60]

func _short(s: String) -> String:
	s = s.replace("\n", " ")
	return s if s.length() <= 70 else s.left(67) + "..."

func _plain(s: String) -> String:
	var re := RegEx.create_from_string("\\[[^\\]]*\\]")
	return re.sub(s, "", true)

class BotLogger extends Logger:
	var bot: Object
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, script_backtraces: Array) -> void:
		if error_type == 1:   # warnings don't count
			return
		var msg := rationale if rationale != "" else code
		msg += "\n  at %s (%s:%d)" % [function, file, line]
		if not script_backtraces.is_empty():
			msg += "\n" + str(script_backtraces[0].format()).left(800)
		bot.call_deferred("_on_error", msg)
