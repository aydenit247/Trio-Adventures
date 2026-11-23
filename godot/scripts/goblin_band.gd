# The goblin band: a drummer, a horn player and a lute player who show up when the village song starts and follow
# the trio around playing it. The village song (AreaMusic) only plays while the band is with you.
#   "Dat bih fire mud"       → they keep playing     (Ebain's lines, used verbatim)
#   "Y'all could get lost?"  → they walk off into the bar and the song fades out with them.
#                              They're back the next time you enter the village (new visit or a loaded save).
# Going into a building: they wait outside the door and keep following when you come out.
# Village.gd adds this node when free roam starts (_leave) and routes "band_*" actions + interactables here.
class_name GoblinBand
extends Node

const MEMBERS := [
	{ "id": "band_drummer", "name": "Goblin Drummer (Unpaid)", "tex": "band_drummer" },   # DRAFT labels
	{ "id": "band_horn", "name": "Goblin Horn Guy (Self-Taught)", "tex": "band_horn" },
	{ "id": "band_lute", "name": "Goblin Lute (Knows 1 Song)", "tex": "band_lute" },
]
const BOB_HZ := 2.0        # head-bob to the beat while standing still

var lv: Node                # the village Level
var bar_door: Vector3       # where they come from and go back to (set by village.gd)
var units: Array = []       # the three band Units
var state := "gone"         # gone / playing / leaving (tests + dev)
var gain_db := 0.0          # fed to the village AreaMusic: 0 = full song, -60 = silent
var _t := 0.0
var _leave_t := 0.0
var _note_t := 0.0

# Free roam started (first time, or entering the village again from a save): the band runs in from the bar.
func arrive() -> void:
	if not units.is_empty():
		return
	var door := bar_door
	var first_slot := 3 if Game.flag("goblinAllies") else 0   # march behind the goblin allies, if they're coming
	for i in MEMBERS.size():
		var m: Dictionary = MEMBERS[i]
		var u: Unit = lv.spawn_npc(m["id"], m["name"], m["tex"], 1.2, door + Vector3(1.2 + i * 0.7, 0, 1.6 + (i % 2) * 0.5))
		u.set_meta("band", true)
		u.set_meta("follow", true)
		u.set_meta("follow_i", first_slot + i)
		units.append(u)
	lv.char_label(units[1], "The Goblin Band (Nobody Asked)", 3.5, 1.65)   # DRAFT; one label, not three stacked
	state = "playing"
	gain_db = 0.0
	if not lv.shots_mode:
		lv.show_toast("The goblin band has entered the chat.", 2.4)   # DRAFT

# Talk to any band member.
func talk_steps(u: Unit) -> Array:
	var me: String = lv.leader.id
	# (Asar 11/22) Lykor and Xylo only say lines Asar recorded. These two aren't recorded, so with them leading the
	# choice text stands in for what they said and the band just answers.
	var says := func(line: String) -> Array:
		return [] if me in ["lykor", "xylo"] else [{ "who": me, "line": line }]   # Ebain
	return [
		{ "who": "goblin", "name": u.display_name, "portrait": "goblin", "line": "We take requests. We know one song." }, # DRAFT
		{ "choice": [
			{ "text": "Dat bih fire mud", "steps": says.call("Dat bih fire mud") + [   # Ebain
				{ "who": "goblins", "name": "Goblin Band", "line": "WE STAY JAMMIN'." }, # DRAFT
				{ "do": "band_keep" },
			] },
			{ "text": "Y'all could get lost?", "steps": says.call("Y'all could get lost?") + [   # Ebain
				{ "who": "goblins", "name": "Goblin Band", "line": "…Tough crowd. We'll be at the bar. Don't come looking." }, # DRAFT
				{ "do": "band_leave" },
			] },
		] },
	]

func interactables() -> Array:
	var out: Array = []
	if state != "playing":
		return out
	for u in units:
		out.append({ "id": "band", "label": u.display_name, "verb": "Talk to", "node": u, "h": 1.6, "r": 1.7, "steps": talk_steps(u) })
	return out

func on_action(n: String) -> void:
	match n:
		"band_keep":
			for u in units:
				lv.hop(u, 0.35)
		"band_leave":
			leave()

func leave() -> void:
	if state != "playing":
		return
	state = "leaving"
	_leave_t = 0.0
	var door := bar_door
	for i in units.size():
		var u: Unit = units[i]
		u.set_meta("follow", false)
		u.set_meta("goal", door + Vector3(0.5 * (i - 1), 0, 0.4))
		u.set_meta("goal_speed", 0.8)

func _process(delta: float) -> void:
	_t += delta
	if state == "leaving":
		_leave_t += delta
		_process_leaving(delta)
	elif state == "playing":
		_process_playing(delta)

func _process_playing(delta: float) -> void:
	gain_db = move_toward(gain_db, 0.0, delta * 30.0)
	var room: String = str(lv.vb.room) if lv.vb else ""
	for i in units.size():
		var u: Unit = units[i]
		# wait at the door while you're inside a building (the follow code would try to walk to the room)
		u.set_meta("follow", room == "")
		if room != "":   # walk over and hang out by the door you went in
			if not u.has_meta("goal"):
				var b: Dictionary = lv.VB.BUILDINGS[room]
				var out: Vector3 = (b["door"] - b["pos"]).normalized()
				var side := out.cross(Vector3.UP)
				u.set_meta("goal", b["door"] + out * (2.2 + (i % 2) * 0.5) + side * (i - 1) * 0.9)
				u.set_meta("goal_speed", 1.0)
			continue
		if u.has_meta("goal"):
			u.remove_meta("goal")
		if u.velocity.length() < 0.3:   # standing: bob to the beat (walking already bobs)
			var ph := _t * TAU * BOB_HZ + i * 1.3
			u.sprite.position.y = maxf(0.0, sin(ph)) * 0.07
	_note_t -= delta
	if room == "" and _note_t <= 0.0 and not units.is_empty():
		_note_t = 0.55
		_note(units[randi() % units.size()])

# Walking off to the bar: the song fades as they get farther away (and over ~4 s at most, so it never just cuts
# out); they disappear through the door.
func _process_leaving(delta: float) -> void:
	var far := 0.0
	var done := true
	for u in units:
		far = maxf(far, u.global_position.distance_to(lv.leader.global_position))
		if u.global_position.distance_to(u.get_meta("goal")) > 0.6:
			done = false
	var by_distance := remap(clampf(far, 4.0, 18.0), 4.0, 18.0, 0.0, -60.0)
	var by_time := -60.0 * clampf((_leave_t - 0.5) / 3.5, 0.0, 1.0)
	gain_db = minf(gain_db, minf(by_distance, by_time))
	if not units.is_empty() and (done or _leave_t > 9.0):
		for u in units:
			lv.npcs.erase(u)
			var tw: Tween = u.create_tween()
			tw.tween_property(u.sprite, "modulate:a", 0.0, 0.4)
			tw.tween_callback(u.queue_free)
		units = []
	if units.is_empty() and gain_db <= -59.9:
		gain_db = -60.0
		state = "gone"

# A floating music note over a player.
func _note(u: Unit) -> void:
	var l := Label3D.new()
	l.text = ["♪", "♫"][randi() % 2]
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 64
	l.pixel_size = 0.006
	l.outline_size = 8
	l.modulate = Color("#ffe27a")
	l.position = Vector3(randf_range(-0.3, 0.3), 1.35, 0)
	u.add_child(l)
	var tw: Tween = l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", 2.1, 1.3)
	tw.tween_property(l, "position:x", l.position.x + randf_range(-0.3, 0.3), 1.3)
	tw.tween_property(l, "modulate:a", 0.0, 1.3).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)
