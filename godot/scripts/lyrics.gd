# Song lyrics for the Library (library_ui.gd). Key = the song id in LibraryUI.SONGS.
# Ebain sends these: paste them in as-is between the triple quotes (# Ebain, never reworded).
# A song with no entry (or "") shows "Lyrics coming soon" on its page.
class_name Lyrics
extends RefCounted

const TEXT := {
	# Ebain
	"prophecy_of_metocy": """[Intro]
Me... to... cy...

[Verse]
Metocy... Metocy...
Y'all could hear me dough...
Y'all could hear me dough...

[Swell]
Metocy!
On some type shit...
On some type shit...
John's orb... John's orb...

[Outro]
Me... to... cy...""",
	# Ebain
	"the_mogging_elf": """[Instrumental]

The Mogging Elf, the Mogging Elf

[Instrumental]

Metocy, metocy

[Instrumental]

Lie-core is the Mogging Elf. Look at Lie-core all by his god damn self!

[Instrumental]

The Mogging Elf, Metocy, the Mogging Elf

[Instrumental]

On some type shit, you feel me? Hehe.""",
	"the_hymn_of_metocin_mattias": "",
	# Ebain
	"deloye_lore": """[Intro]
(Check it, yeah...)
(Duh-loy...)

[Hook:]
Duh-loy lore— Duh-loy lore—
Dulb-mee-thus, dough, o-pen the door—
Meh-toe-see, Meh-toe-see, pass it to me—
John got an orb, who's John? (John! John!)

[Drop: heavy four-on-the-floor beat, saturated 808 sub-bass, and metallic cowbell lead only, no vocals]

[Verse:]
Duh-loy wrote it, Dulb-mee-thus made it
Meh-toe-see smoke it, John just wai-ted
Duh-loy wrote it, Dulb-mee-thus made it
Meh-toe-see smoke it, John just wai-ted

[Hook:]
Duh-loy lore— Duh-loy lore—
Dulb-mee-thus, dough, o-pen the door—
Meh-toe-see, meh-toe-see pass it to me—
John got an orb, who's John? (John! John!)

[Break: kick and bass cut out abruptly, muffled cowbell and tape hiss only, distant off-mic voice]
(Y'all could hear me, dough?)

[Drop: full beat slams back in, stuttered MPC-style vocal chops]
Duh-loy... Duh-loy... lore, lore, lore—
John— John— John—

[Outro]
(Aight, imma catch y'all...)""",
}
