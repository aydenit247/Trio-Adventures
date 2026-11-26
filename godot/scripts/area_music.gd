# AreaMusic: background music for an area's free roam.
# Add it to an area's .tscn as a child of the root node and set the exports. It watches its parent (the Level)
# instead of being called, so the area's script doesn't need to change:
#  - plays while the parent's `stage` is one of `stages` (and you're not inside a village building)
#  - ducks under dialogue boxes, goes quiet for fights / building interiors, fades out on scene changes
#  - keeps running silently while it's out, so walking back outside picks the song up where it was (no restart)
# Loop points live in the track's .import file (loop=true, loop_offset = where the loop starts after the intro).
class_name AreaMusic
extends Node

@export var track: AudioStream
@export var stages: PackedStringArray = ["after"]
@export var volume_db := -9.0          # full volume (title song is -3; this sits under voices + ambience)
@export var duck_db := -20.0           # while a dialogue box is open (about 30% loudness)
@export var fade_in_db_per_s := 10.0   # first start and coming back: a slow swell
@export var fade_out_db_per_s := 40.0
@export var duck_release_s := 0.7      # wait this long after a box closes before swelling back (no pumping between lines)

const SILENT := -60.0
var player: AudioStreamPlayer
var lv: Node
var state := "silent"                  # silent / full / ducked / out: what it's aiming for (tests + dev)
var gain_db := 0.0                     # extra volume set by the area each frame (village: 0 while the goblin band plays, -60 when it's gone)
var _since_dialogue := 99.0
var _heard := false                    # already sent to the Library this visit
var played_once := false               # Settings → Music: Play once, and the song has finished: stay quiet
var paused := false                    # the area holds the song where it is (summit: while Dulbers ambushes); false = carry on
var force_once := false                # set before adding: always play it through once, whatever the setting (summit hymn)

func _ready() -> void:
	lv = get_parent()
	player = AudioStreamPlayer.new()
	player.stream = track
	player.volume_db = SILENT
	player.bus = &"Music"   # Settings → Audio → Music (Game._make_buses)
	add_child(player)
	player.finished.connect(func(): played_once = true)
	if (Game.music_once or force_once) and track is AudioStreamOggVorbis:   # play it through once, no loop
		var full := track.resource_path.replace(".ogg", "_full.ogg")   # the full version has the song's real ending
		var once: AudioStreamOggVorbis = (load(full) if ResourceLoader.exists(full) else track).duplicate()
		once.loop = false
		player.stream = once

func _process(delta: float) -> void:
	if track == null:
		return
	player.stream_paused = paused
	if paused:
		return
	if _dialogue_open():
		_since_dialogue = 0.0
	else:
		_since_dialogue += delta
	state = _wanted()
	var target := SILENT
	match state:
		"full": target = maxf(SILENT, volume_db + gain_db)
		"ducked": target = maxf(SILENT, duck_db + gain_db)
	# the song starts the first time it's wanted (so it begins at the top when free roam opens), then never stops
	if not player.playing:
		if played_once:   # Music: Play once, and it's done
			state = "done"
			return
		if state == "full" or state == "ducked":
			player.play()
		else:
			return
	if not _heard and player.volume_db > -24.0 and track:   # audible: unlock it in the Library (title → Library)
		_heard = true
		if LibraryUI.mark_heard(track.resource_path) and lv and lv.has_method("show_toast"):
			lv.show_toast("New song in the Library: " + LibraryUI.song(track.resource_path.get_file().get_basename())["title"], 2.6)
	if state == "out":   # leaving the area: drop fast, like the title song does
		player.volume_db = max(SILENT, player.volume_db - delta * 140.0)
	elif target > player.volume_db:
		player.volume_db = min(target, player.volume_db + delta * fade_in_db_per_s)
	else:
		player.volume_db = max(target, player.volume_db - delta * fade_out_db_per_s)

func _wanted() -> String:
	if Game.changing:
		return "out"
	if lv == null or not (str(lv.get("stage")) in stages):
		return "silent"
	var vb = lv.get("vb")   # village buildings: interiors are separate rooms
	if vb != null and str(vb.get("room")) != "":
		return "silent"
	for c in lv.get_children():
		if c is BattleView:
			return "silent"
	if not get_tree().get_nodes_in_group("library_open").is_empty():   # the Library from the pause menu plays its own songs
		return "silent"
	if _since_dialogue < duck_release_s:
		return "ducked"
	return "full"

func _dialogue_open() -> bool:
	if lv == null:
		return false
	var d = lv.get("dialogue")
	return d != null and d.panel != null and d.panel.visible
