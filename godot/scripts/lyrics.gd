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
	# Ebain
	"the_hymn_of_metocin_mattias": """[Intro]
From Caelid's dust shall three arise
To seek the holy pill;
One purple, full of fury's fire,
Who cannot read, nor will.
One golden-haired, whose face is law,
Whom kingdoms bow to see;
One red, who reads the endless lore
And talks eternally.

[Verse 1]
Upon the night before the quest
He found the only map;
He fed it to the campfire's flame,
Then settled for a nap.
'Bags is for maps!' the golden cried,
The fire answered, 'snap.'

[Verse 2]
The goblins bowed to golden hair,
They crowned him with a spoon;
They poured him bee-zee, cold and fair,
He passed out before noon.
A shop where no shop ought to be,
A grin behind the till;
'The first one's free,' said Dull-Burz Frint.
It was a bootleg pill.

[Pre-Chorus]
The giant slept across the pass,
His snoring shook the stone;
By slap, by lore, by sneaking feet,
The three went on alone.

[Chorus]
Meh-Toe-Sin Muh-Tie-Us!
(You had called? You had called?)
We climbed your mountain high!
(Come closer, my beloved three)
True Meh-Toe-See is never moist,
It's dry as bone and blue as sky!
On my Dragon Mama,
The trio does not die!

[Verse 3]
Upon the night before the quest
He found the only map;
He fed it to the campfire's flame,
Then settled for a nap.
'Bags is for maps!' the golden cried,
The fire answered, 'snap.'

[Verse 4]
The goblins bowed to golden hair,
They crowned him with a spoon;
They poured him bee-zee, cold and fair,
He passed out before noon.
A shop where no shop ought to be,
A grin behind the till;
'The first one's free,' said Dull-Burz Frint.
It was a bootleg pill.

[Chorus]
Meh-Toe-Sin Muh-Tie-Us!
(You had called? You had called?)
We climbed your mountain high!
(Come closer, my beloved three)
True Meh-Toe-See is never moist,
It's dry as bone and blue as sky!
On my Dragon Mama,
The trio does not die!

[Outro]
From Caelid's dust shall three arise
To seek the holy pill.""",
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
