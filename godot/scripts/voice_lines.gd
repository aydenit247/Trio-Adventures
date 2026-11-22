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
# Narrator: Asar's own recordings (2026-11-22). Narrator lines without a recording were removed (his call).
const LINES := {
	"Caelid. Night. The night before the greatest quest of their lives.": "narrator/caelid_night_the_night_before",
	"The quest for the metocy.": "narrator/the_quest_for",
	"(WASD to walk, E to interact. Get the fire going.)": "narrator/wasd_to_walk",
	"Skorn got: Important-Looking Paper.": "narrator/skorngotimportant",
	"It reads: \"M̷Ꭺ̵Ꮲ̶ ̸Ƭ̷Ө̴ ̵Ƭ̶Ң̸Ɛ̷ ̴M̵Ɛ̶Ƭ̸Ө̷C̴Ɏ̵\" (Skorn cannot read)": "narrator/it_reads_skorn_can_not_read",
	"(Explore the camp. Q switches who you control. Tab opens your inventory.)": "narrator/explorethecampqswitches",
	"The campfire. Burning bright. Suspiciously bright.": "narrator/thecampfireburningbright",
	"The next morning…": "narrator/thenextmorning",
	"Later that morning…": "narrator/laterthatmorning",
	"(You're playing as Lykor now. Folk, head into that village over there.)": "narrator/you_are_playing_as_lykor_now_folk_head_into_that_village_over_there",
	"The goblins seat Lykor on a throne made of spoons, bones, and one (1) wagon wheel.": "narrator/thegoblinsseatlykoronathrone",
	"How does Lykor get out of this?": "narrator/howdoeslykorgetoutofthis",
	"Lykor got: Beezy ×3 (heals)": "narrator/lykorgot3beezys",
	"Lykor passes out.": "narrator/lykorpassesout",
	"Skorn Diddy Slaps the nearest goblin.": "narrator/skorndiddyslaps",
	"East of the goblin village…": "narrator/eastofthegoblin",
	"(You're playing as Xylo now.)": "narrator/you_are_playing_as_xylo_now",
	"The trio takes the metocy.": "narrator/thetriotakes",
	"Got: Midtocy (throwable)": "narrator/got_midtocy_throwable",
	"Dulbers Frint was never seen again.": "narrator/dulbers_frint_was_never_seen_again",
	"Past the giant, the path climbs higher. Somewhere up ahead… the metocy.": "narrator/past_the_giant_the_path_climbs_higher_somewhere_up_ahead_the_metocy",
	"The mountain pass. Hot. Ashy. And OD as a mufucka.": "narrator/the_mountain_pass_hot_ashy_and_od_as_a_mufucka",
	"How do you get past Diddy Chud Giant?": "narrator/how_do_you_get_past_diddy_chud_giant",
	"The trio makes it across. Diddy Chud never wakes up.": "narrator/the_trio_makes_it_across_diddy_chud_never_wakes_up",
	"Diddy Chud Giant smiles in his sleep… and rolls over. The path is clear.": "narrator/diddy_chud_giant_smiles_in_his_sleep",
	"Skorn Diddy Slaps the giant across the face.": "narrator/skorn_diddy_slaps_the_giant_across",
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
