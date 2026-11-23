# Night ambience: synthesized campfire crackle (3D, at the fire) + a real cricket recording (assets/sounds/crickets.ogg,
# a seamless 61 s loop cut from Ebain's crickets mp3, low hum filtered out).
extends Node3D
class_name Ambience

const RATE := 22050.0
var fire_player: AudioStreamPlayer3D
var cricket_player: AudioStreamPlayer
var _fire_pb: AudioStreamGeneratorPlayback
var _crackles: Array = []   # [samples_left, amp, lp_state]
var _rumble := 0.0

func setup(fire_pos: Vector3) -> void:
	fire_player = AudioStreamPlayer3D.new()
	fire_player.stream = _gen()
	fire_player.position = fire_pos + Vector3(0, 0.5, 0)
	fire_player.unit_size = 4.0
	fire_player.max_distance = 40.0
	fire_player.volume_db = -4.0
	fire_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM   # generators need stream mode (web defaults to samples)
	add_child(fire_player)
	fire_player.play()
	_fire_pb = fire_player.get_stream_playback()

	cricket_player = AudioStreamPlayer.new()
	var crk: AudioStreamOggVorbis = load("res://assets/sounds/crickets.ogg")
	crk.loop = true
	cricket_player.stream = crk
	cricket_player.volume_db = -17.0   # (Asar 11/22: was -9, too loud at the campfire)
	add_child(cricket_player)
	cricket_player.play(randf() * 50.0)   # start somewhere random in the loop

func _gen() -> AudioStreamGenerator:
	var g := AudioStreamGenerator.new()
	g.mix_rate = RATE
	g.buffer_length = 0.25
	return g

func _process(_d: float) -> void:
	if _fire_pb:
		_fill_fire()

func _fill_fire() -> void:
	var n := _fire_pb.get_frames_available()
	for i in n:
		# low steady roar
		_rumble += ((randf() * 2.0 - 1.0) - _rumble) * 0.02
		var v := _rumble * 0.5
		# random pops and snaps
		if randf() < 0.0009:
			_crackles.append([int(RATE * randf_range(0.004, 0.03)), randf_range(0.2, 0.7), 0.0])
		var k := _crackles.size() - 1
		while k >= 0:
			var c: Array = _crackles[k]
			c[2] += ((randf() * 2.0 - 1.0) - c[2]) * 0.6
			v += c[2] * c[1] * (float(c[0]) / (RATE * 0.03))
			c[0] -= 1
			if c[0] <= 0:
				_crackles.remove_at(k)
			k -= 1
		_fire_pb.push_frame(Vector2(v, v))
