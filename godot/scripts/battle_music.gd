# Fight music (Ebain's soundtrack, 11/27). Every fight plays "General Combat"; a boss with its own theme plays that
# instead, and crossfades to its phase-2 track the moment he goes HYPED at 30% HP (battle.gd sets e["last_stand"]).
# The in-game files are loop cuts (<id>.ogg: loop=true, loop_offset in the .import skips the intro on repeats, with
# a 40 ms crossfade baked into the seam); the Library plays the untouched songs (<id>_full.ogg).
# To give another boss a theme: add its fight key to BOSS with [phase 1 id, phase 2 id] (phase 2 can repeat phase 1).
class_name BattleMusic
extends Node

const GENERAL := "battle_general"
const BOSS := {
	"giant": ["boss_diddy_chud_1", "boss_diddy_chud_2"],
	"mattias": ["boss_mattias_1", "boss_mattias_2"],
}
const FADE_IN := 0.8
const FADE_OUT := 1.4
const SWAP := 1.6   # phase-2 crossfade

var tracks: Array = []
var player: AudioStreamPlayer
var phase := 1

func start(fight_key: String) -> void:
	tracks = BOSS.get(fight_key, [GENERAL, GENERAL])
	player = _play(tracks[0])

func _play(id: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = &"Music"
	p.stream = load("res://assets/music/%s.ogg" % id)
	p.volume_db = -30.0
	add_child(p)
	p.play()
	create_tween().tween_property(p, "volume_db", 0.0, FADE_IN)
	LibraryUI.mark_heard(id)   # unlocks it in the Library (no toast mid-fight)
	return p

# called every turn: a boss in his last stand flips the music to phase 2 (once)
func watch(b) -> void:
	if phase == 2 or tracks[1] == tracks[0]:
		return
	for e in b.enemies:
		if e.get("boss", false) and e.get("last_stand", false):
			phase = 2
			var old := player
			player = _play(tracks[1])
			player.volume_db = -20.0
			create_tween().tween_property(player, "volume_db", 0.0, SWAP * 0.5)
			var tw := create_tween()
			tw.tween_property(old, "volume_db", -60.0, SWAP)
			tw.tween_callback(old.queue_free)
			return

func stop() -> void:
	if player == null or not is_instance_valid(player):
		return
	var tw := create_tween()
	tw.tween_property(player, "volume_db", -60.0, FADE_OUT)
	tw.tween_callback(player.stop)
