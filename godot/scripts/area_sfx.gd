# Random one-shots per area + bush rustles + the "new area" sting (Ebain 11/27, sound batch 4; mixed from CC0 packs,
# see credits.gd). Level._ready adds one of these to every area.
#   Day outdoors (trail, village, ruins, camp after sleeping): birds, now and then a woodpecker
#   Night outdoors (camp at night, the Mart street): an owl
#   Cave: echoing drips · Summit: wind gusts · Pass / library: nothing (lava and books)
# Each one-shot plays in 3D somewhere around the leader, every 9-22 s, quiet. Paused during fights.
# Bushes: Level.card() remembers where every "bush_*" card is (Level.bush_spots); walking through one rustles it.
extends Node
class_name AreaSfx

const SETS := {
	"day": [["amb_bird_1", -17.0], ["amb_bird_2", -17.0], ["amb_bird_4", -19.0], ["amb_bird_1", -18.0], ["amb_bird_2", -18.0], ["amb_woodpecker", -16.0]],
	"night": [["amb_owl", -21.0]],
	"cave": [["amb_drip_1", -13.0], ["amb_drip_2", -13.0], ["amb_drip_3", -13.0]],
	"summit": [["amb_gust_1", -12.0], ["amb_gust_2", -12.0]],
}
const GAP := { "day": [9.0, 20.0], "night": [16.0, 32.0], "cave": [5.0, 12.0], "summit": [10.0, 22.0] }
const RUSTLES := ["bush_rustle_1", "bush_rustle_2", "bush_rustle_3", "bush_rustle_4", "bush_rustle_5"]

var lv: Level
var _wait := 6.0
var _bush_cd := {}   # bush index -> seconds until it can rustle again

func setup(level: Level, first_visit: bool) -> void:
	lv = level
	_wait = randf_range(4.0, 9.0)
	if first_visit and not lv.shots_mode and not Game.title_mode:
		get_tree().create_timer(1.2).timeout.connect(func(): if is_instance_valid(lv): _play_flat("sting_area", -6.0))

func _which() -> String:
	match lv.area_key():
		"cave": return "cave"
		"summit": return "summit"
		"pass", "library": return ""
	return "night" if lv.night else "day"

func _fighting() -> bool:
	for c in lv.get_children():
		if c is BattleView:
			return true
	return false

func _process(d: float) -> void:
	if lv == null or Game.title_mode or lv.leader == null:
		return
	_wait -= d
	if _wait <= 0.0:
		var s := _which()
		_wait = 12.0
		if s != "" and not _fighting():
			var pick: Array = SETS[s][randi() % SETS[s].size()]
			var ang := randf() * TAU
			var dist := randf_range(5.0, 11.0) if s != "summit" else 3.0
			var pos := lv.leader.global_position + Vector3(cos(ang) * dist, 2.5 if s == "day" or s == "night" else 1.0, sin(ang) * dist)
			lv.play_sound_at(pick[0], pos, pick[1], randf_range(0.93, 1.07), 8.0)
			_wait = randf_range(GAP[s][0], GAP[s][1])
	_bushes(d)

func _bushes(d: float) -> void:
	for k in _bush_cd.keys():
		_bush_cd[k] -= d
		if _bush_cd[k] <= 0.0:
			_bush_cd.erase(k)
	if lv.bush_spots.is_empty() or not lv.leader.moving:
		return
	var at := lv.leader.global_position
	for i in lv.bush_spots.size():
		var b: Array = lv.bush_spots[i]   # [pos, radius]
		if _bush_cd.has(i):
			continue
		var pos: Vector3 = b[0]
		if Vector2(at.x - pos.x, at.z - pos.z).length() < b[1]:
			_bush_cd[i] = 1.2
			lv.play_sound_at(RUSTLES[randi() % RUSTLES.size()], pos + Vector3(0, 0.5, 0), -8.0, randf_range(0.9, 1.1), 5.0)

func _play_flat(id: String, db: float) -> void:
	lv.play_sound(id, db)   # frees itself
