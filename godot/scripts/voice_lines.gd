# Voice lines: a line in the scripts with a voice file plays it instead of the robot TTS.
# Lines are matched by their text (case, punctuation and spacing ignored), so the same file works
# wherever that line is used. If someone rewords a line, it falls back to TTS until it's regenerated.
#
# AI voices from the Emberstage studio are listed in voice_index.gd (made by tools/import_voices.py).
# For a one-off file by hand: drop it in res://assets/voices/<group>/ and add  "line text": "<group>/<file>"  below
# (no extension = .mp3). How voices get made: VOICE_LINES.md (repo root).
class_name VoiceLines

const DIR := "res://assets/voices/"

# Voice lines generated with the Emberstage studio (github.com/aydenit247/Voice-actor-generation) go here.
# Asar's 37 goblin/Chief recordings were removed on 2026-11-21 (Ebain's call: every voice will be AI-generated).
const LINES := {
}

static var _index: Dictionary = {}

static func key(line: String) -> String:
	var re := RegEx.create_from_string("[^a-z0-9]")
	return re.sub(line.to_lower(), "", true)

# Returns the AudioStream for this line, or null if it has no recording.
static func stream_for(line: String) -> AudioStream:
	if _index.is_empty():
		for k in VoiceIndex.LINES:
			_index[k] = DIR + VoiceIndex.LINES[k]
		for l in LINES:   # hand-added lines win
			var f: String = LINES[l]
			_index[key(l)] = DIR + (f if f.get_extension() != "" else f + ".mp3")
	var p: String = _index.get(key(line), "")
	if p == "" or not ResourceLoader.exists(p):
		return null
	return load(p)
