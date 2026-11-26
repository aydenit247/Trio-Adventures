extends Control
class_name VideoCutscene
# A full-screen video cutscene that any area can play (Ebain 11/26, first used for the pipe ride from the village
# outhouse into the Deloye library). Godot only plays Ogg Theora (.ogv), so convert mp4s first:
#   ffmpeg -i in.mp4 -c:v libtheora -q:v 8 -c:a libvorbis -q:a 5 out.ogv
# Usage:  await VideoCutscene.play(hud, "res://assets/video/pipe_ride.ogv", Color.WHITE)
# The screen behind it is covered while it plays; E / Esc / Enter / click skips after half a second. Music ducks out
# and comes back. When it's done the cover becomes `end_color` and is returned, so the caller can fade it or change
# scene behind it (free it yourself). Returns null (and plays nothing) headless, under NO_CUTSCENE or if the file is missing.

var _vp: VideoStreamPlayer
var _skip := false
var _t0 := 0

static func play(parent: Node, path: String, end_color := Color.BLACK, max_secs := 30.0) -> ColorRect:
	if DisplayServer.get_name() == "headless" or OS.get_environment("NO_CUTSCENE") != "" or not ResourceLoader.exists(path):
		return null
	var stream = load(path)
	if stream == null:
		return null
	var vc := VideoCutscene.new()
	vc.set_anchors_preset(Control.PRESET_FULL_RECT)
	vc.mouse_filter = Control.MOUSE_FILTER_STOP
	vc.process_mode = Node.PROCESS_MODE_ALWAYS
	var cover := ColorRect.new()
	cover.color = Color.BLACK
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(cover)
	cover.add_child(vc)
	await vc._run(stream, max_secs)
	vc.queue_free()
	cover.color = end_color
	return cover

func _run(stream: VideoStream, max_secs: float) -> void:
	var frame := AspectRatioContainer.new()
	frame.ratio = 16.0 / 9.0
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	_vp = VideoStreamPlayer.new()
	_vp.stream = stream
	_vp.expand = true
	_vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if AudioServer.get_bus_index("SFX") != -1:
		_vp.bus = &"SFX"
	frame.add_child(_vp)
	var skip_lbl := Label.new()
	skip_lbl.text = "E / Esc: skip"
	skip_lbl.modulate = Color(1, 1, 1, 0.0)
	skip_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_lbl.offset_left = -170; skip_lbl.offset_top = -40; skip_lbl.offset_right = -16; skip_lbl.offset_bottom = -12
	skip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(skip_lbl)
	var mus := AudioServer.get_bus_index("Music")
	var mus_db := AudioServer.get_bus_volume_db(mus) if mus != -1 else 0.0
	if mus != -1:
		AudioServer.set_bus_volume_db(mus, -60.0)
	_vp.play()
	_t0 = Time.get_ticks_msec()
	while _vp.is_playing() and not _skip and Time.get_ticks_msec() - _t0 < int(max_secs * 1000.0):   # watchdog
		if Time.get_ticks_msec() - _t0 > 1200 and skip_lbl.modulate.a == 0.0:
			create_tween().tween_property(skip_lbl, "modulate:a", 0.6, 0.4)
		await get_tree().process_frame
	_vp.stop()
	if mus != -1:
		AudioServer.set_bus_volume_db(mus, mus_db)

func _input(ev: InputEvent) -> void:
	if _vp == null or Time.get_ticks_msec() - _t0 < 500:
		return
	var hit: bool = (ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode in [KEY_E, KEY_ESCAPE, KEY_ENTER, KEY_SPACE]) \
		or (ev is InputEventMouseButton and ev.pressed) \
		or (ev is InputEventJoypadButton and ev.pressed)
	if hit:
		_skip = true
		get_viewport().set_input_as_handled()
