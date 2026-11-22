# Headless test for the dialogue voice queue (no real TTS in the sandbox, so a fake robot voice "speaks" each piece
# for 8 ms per character).  godot --headless --path godot res://tools/test_skip_voice.tscn
extends Node

class FakeDialogue extends Dialogue:
	var spoken: Array = []
	var busy_until := 0
	func _tts_busy() -> bool:
		return Time.get_ticks_msec() < busy_until
	func _tts_say(q: Dictionary) -> void:
		spoken.append(q["text"])
		busy_until = Time.get_ticks_msec() + int(q["text"].length() * 8)

var fails := 0

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _ready() -> void:
	Game.voice_vol = 1.0
	var d := FakeDialogue.new()
	add_child(d)
	await get_tree().process_frame
	d._voices = PackedStringArray(["fake"])
	d.tts_on = true

	check(Dialogue.sentences("Aight. Bet.") == PackedStringArray(["Aight. Bet."]), "tiny sentences are glued together")
	check(Dialogue.sentences("Okay, okay, okay, my fault. I ain't know y'all was some crashouts.").size() == 2, "two sentences → two pieces")
	check(Dialogue.sentences(", ").is_empty(), "empty line → nothing to say")

	# 1. Line A is long. Skip it right away → line B must still be heard (the old bug: B was silent).
	d._speak("skorn", "This is a very long first sentence that keeps going and going. And a second one that should never be spoken.", false)
	await wait(0.05)
	d._speak("lykor", "Line B is the one you skipped to.", false)
	await wait(2.5)
	check(d.spoken.has("Line B is the one you skipped to."), "line after a skip is spoken (not silent)")
	check(not d.spoken.has("And a second one that should never be spoken."), "skipped line stops after its current sentence")

	# 2. Mash skip through 4 lines → only the last one plays after the current sentence.
	d.spoken.clear()
	d._speak("xylo", "First line here, long enough to keep the robot busy for a bit.", false)
	await wait(0.05)
	for t in ["Second line, skipped.", "Third line, skipped.", "Fourth line is the one we land on."]:
		d._speak("xylo", t, false)
		await wait(0.02)
	await wait(2.0)
	check(d.spoken == ["First line here, long enough to keep the robot busy for a bit.", "Fourth line is the one we land on."], "mashing skip queues only the newest line: %s" % [d.spoken])

	# 3. Recorded line arriving while the robot is mid-sentence waits, then plays.
	d.spoken.clear()
	d._speak("skorn", "A robot sentence that is still being read out loud.", false)
	await wait(0.05)
	d._speak("giant", "Aight. Bet.", false)
	check(not d._vo.playing and d._pending_rec != null, "recording waits for the robot's sentence")
	await wait(1.0)
	check(d._vo.playing or d._vo.stream != null and d._pending_rec == null, "recording plays once the robot is done")

	# 4. Recording → next line: recording is cut instantly and the new one starts (safe to stop).
	d._speak("giant", "Y'all disturbin' my nap.", false)
	await get_tree().process_frame
	check(d._vo.stream != null and d._vo.stream.resource_path.ends_with("giant_y_all_disturbin_my_nap.ogg"), "recording replaces recording right away")

	# 5. Dialogue closes → queue is cleared.
	d._speak("skorn", "One sentence here for the robot. Another that should be dropped when the box closes.", false)
	await wait(0.05)
	d.stop_voice()
	await wait(1.5)
	check(not d.spoken.has("Another that should be dropped when the box closes."), "closing the dialogue drops the rest")

	print("RESULT: %s" % ("ALL PASS" if fails == 0 else "%d FAILED" % fails))
	get_tree().quit(1 if fails else 0)
