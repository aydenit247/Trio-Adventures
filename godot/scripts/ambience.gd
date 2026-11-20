# Synthesized night ambience (no audio files needed): campfire crackle (3D, at the fire) and crickets.
# Swap for real recordings later by replacing these players' streams with .ogg/.mp3 files.
extends Node3D
class_name Ambience

const RATE := 22050.0
var fire_player: AudioStreamPlayer3D
var cricket_player: AudioStreamPlayer
var _fire_pb: AudioStreamGeneratorPlayback
var _crk_pb: AudioStreamGeneratorPlayback
var _crackles: Array = []   # [samples_left, amp, lp_state]
var _rumble := 0.0
var _t := 0.0

func setup(fire_pos: Vector3) -> void:
	fire_player = AudioStreamPlayer3D.new()
	fire_player.stream = _gen()
	fire_player.position = fire_pos + Vector3(0, 0.5, 0)
	fire_player.unit_size = 4.0
	fire_player.max_distance = 40.0
	fire_player.volume_db = -4.0
	add_child(fire_player)
	fire_player.play()
	_fire_pb = fire_player.get_stream_playback()

	cricket_player = AudioStreamPlayer.new()
	cricket_player.stream = _gen()
	cricket_player.volume_db = -20.0
	add_child(cricket_player)
	cricket_player.play()
	_crk_pb = cricket_player.get_stream_playback()

func _gen() -> AudioStreamGenerator:
	var g := AudioStreamGenerator.new()
	g.mix_rate = RATE
	g.buffer_length = 0.25
	return g

func _process(_d: float) -> void:
	if _fire_pb:
		_fill_fire()
	if _crk_pb:
		_fill_crickets()

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

func _fill_crickets() -> void:
	var n := _crk_pb.get_frames_available()
	for i in n:
		_t += 1.0 / RATE
		var v := 0.0
		for c in [[4300.0, 0.0, 1.0], [4700.0, 0.37, 0.7], [3900.0, 0.71, 0.5]]:
			var ph := fmod(_t + c[1], 1.1)
			var env := 0.0
			for p in 3:  # three quick chirps
				var s := ph - p * 0.07
				if s > 0.0 and s < 0.045:
					env = sin(PI * s / 0.045)
			v += sin(TAU * c[0] * _t) * env * c[2]
		_crk_pb.push_frame(Vector2(v, v) * 0.3)
