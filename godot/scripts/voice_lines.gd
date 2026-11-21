# Recorded voice lines: a line in the scripts with a recording plays that file instead of the robot TTS.
# Lines are matched by their text (case, punctuation and spacing ignored), so the same recording works
# wherever that line is used. If someone rewords a line, it falls back to TTS until it's re-recorded.
#
# To add a recording: drop the mp3 in res://assets/voices/<group>/ and add  "line text": "<group>/<file>"  below.
# Lines still needing a recording: VOICE_LINES.md (repo root).
class_name VoiceLines

const DIR := "res://assets/voices/"

# Goblins + Chief Bogdrinker, recorded by Asar (2026-11-21)
const LINES := {
	"Yay.. you are allowed to mog that hard, right? Cool dude, that's fucking fair.": "goblins/goblin_yay_mog_that_hard",
	"THE MOGGING ELF!!": "goblins/goblins_the_mogging_elf",
	"For a thousand years we have waited for the Mogging Elf. Golden hair. Pointy ears. Smells like expensive conditioner.": "goblins/chief_thousand_years",
	"*gasp* The Mogging Elf seeks the metocy… We know where it is.": "goblins/chief_elf_seeks_metocy",
	"We will tell the Mogging Elf… once he is crowned. Come. Your throne awaits.": "goblins/chief_once_crowned",
	"For all yo metocy needs.": "goblins/chief_metocy_needs",
	"*sobbing* BYE!! COME BACK HARDER!!": "goblins/goblins_bye_come_back_harder",
	"Oh, we'll tell you… as long as you stay our king. FOREVER.": "goblins/chief_stay_our_king",
	"FOREVER! FOREVER! FOREVER!": "goblins/goblins_forever",
	"Bet dat.": "goblins/chief_bet_dat",
	"Aight, so if you could keep walking doe, over there, on some east shit. As far as I know, that's the best metocy a goblin like me could get his hands on.": "goblins/chief_on_some_east_shit",
	"Here go some beezy, folk. Take it for the road.": "goblins/chief_beezy_for_the_road",
	"*gasp* Nobody has out-drunk Bogdrinker in 400 years.": "goblins/chief_400_years",
	"…The Mogging Elf… out-drank… BOGDRINKER?": "goblins/chief_elf_out_drank",
	"LEGEND! LEGEND! LEGEND!": "goblins/goblins_legend",
	"*hic* The Metocy Mart. East. Go before I cry.": "goblins/chief_go_before_i_cry",
	"…A purple king…": "goblins/chief_a_purple_king",
	"PURPLE KING! PURPLE KING!": "goblins/goblins_purple_king",
	"The Metocy Mart is east. Now leave, Mogging Elf. We have a new god.": "goblins/chief_new_god",
	"We go where the Mogging Elf goes.": "goblins/goblin_we_go_where_elf_goes",
	"The Mogging Elf seeks the metocy? Then the goblins will take him there OURSELVES. To the Metocy Mart!": "goblins/chief_take_him_ourselves",
	"FIELD TRIP! FIELD TRIP! FIELD TRIP!": "goblins/goblins_field_trip",
	"…The purple one hits so hard. So beautifully.": "goblins/chief_purple_one_hits",
	"WE WORSHIP THE PURPLE ONE NOW!": "goblins/goblins_worship_purple_one",
	"The Mogging Elf is… dethroned. Give the beezy to the purple one.": "goblins/chief_elf_dethroned",
	"The Metocy Mart is east. Purple one, come back anytime. Elf… don't.": "goblins/chief_elf_dont",
	"Ooooh. A STORE.": "goblins/goblin_a_store",
	"Bogdrinker has heard of this place. Very legit.": "goblins/chief_very_legit",
	"On some field trip shiiiiii.": "goblins/goblins_field_trip_shi",
	"Goblins: one. Demon: zero.": "goblins/chief_goblins_one_demon_zero",
	"An honor.": "goblins/chief_an_honor",
	"THIS AIN'T METOCY. THIS MIDTOCY. BOGDRINKER KNOWS HIS DRUGS.": "goblins/chief_this_midtocy",
	"GET HIMMMM!": "goblins/goblins_get_him",
	"Bogdrinker handled it. Do not ask questions.": "goblins/chief_handled_it",
	"The real metocy is past the giant. Field trip is over. Goblins — HOME.": "goblins/chief_goblins_home",
	"…Cousin Chud?": "goblins/chief_cousin_chud",
	"On my mama's side. Chud, MOVE. These my people.": "goblins/chief_mamas_side",
}

static var _index: Dictionary = {}

static func key(line: String) -> String:
	var re := RegEx.create_from_string("[^a-z0-9]")
	return re.sub(line.to_lower(), "", true)

# Returns the AudioStream for this line, or null if it has no recording.
static func stream_for(line: String) -> AudioStream:
	if _index.is_empty():
		for l in LINES:
			_index[key(l)] = DIR + LINES[l] + ".mp3"
	var p: String = _index.get(key(line), "")
	if p == "" or not ResourceLoader.exists(p):
		return null
	return load(p)
