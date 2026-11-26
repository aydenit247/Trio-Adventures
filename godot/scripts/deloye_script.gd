# The secret Deloye Lore library (DELOYE_PLAN.md). Every line here is # DRAFT: Ebain writes the real ones.
# Deloye (Ebain's art: messy black hair, grey zip hoodie, wired earbuds) floats and twirls in the middle of the
# rotunda at the far end of the library. Vibe (Ebain 11/24): chill, earbuds in, barely looks up, surprised anyone
# actually read it.
# The walk (11/24, Ebain: "make it a much bigger place you have to walk around in, Deloye at the end"): you land in the
# Atrium, walk the Grand Stacks, and the Reading Room (Deloye's rotunda) stays shut until you find the 3 joint pieces.
# Ebain's script (11/25): Metocin Mattias teleports in, guides you to the first piece (the cannabis plant, the RAW papers,
# the lighter), "You could help me?" → he guides you to the rest and to Deloye's room. Deloye: "You could pass that shit?"
# A give it (Neuralink) · B puff puff pass (Faded for 3 fights + Neuralink) · C "Bad." (keep the joint, Xylo's lore
# fizzles half the time). Then "Alright I'm gonna catch y'all later" → everyone back to the goblin village.
extends RefCounted

# Landing in a heap after the flush (in the Atrium). Mattias teleports in mid-way.
const ARRIVE := [
	{ "who": "lykor", "line": "What the fuck folk? T S is massive like the low taper fade meme" }, # Ebain
	{ "who": "xylo", "line": "On dulbmeethus" }, # Ebain
	{ "do": "mattias_appears" },
	{ "who": "mattias", "line": "Y'all had said Deloye Lore easter egg? I ain't gon hold u I gotta peep T S with y'all" }, # Ebain
	{ "who": "lykor", "line": "It's good folk, let's take a look around." }, # Ebain
]

# While walking (speech bubbles over their heads, the game keeps going). The last line starts Mattias guiding you.
const WALK_BANTER := [
	{ "who": "skorn", "line": "Are all of these books Deloye Lore scripture?" }, # Ebain
	{ "who": "xylo", "line": "Yes. The depth of this lore is too deep for one human to be able to learn or ingest it all" }, # Ebain
	{ "who": "mattias", "line": "Except me, i've been around for almost 500 years learning about Deloye Lore and taking metocy with Dulbmeethus n shi, but i fear one day I will succumb to the inevitable power of Death, himself." }, # Ebain
	{ "who": "skorn", "line": "Damn bro, you ain't gonna make it sad in de bih" }, # Ebain
	{ "who": "mattias", "line": "My fault folk, Look over here. Follow me." }, # Ebain
]

# Picking up the first joint piece (Mattias led you to it)
const PIECE_FIRST := [
	{ "who": "mattias", "line": "I think we need to find all the materials for T S. Let me know if you need more help." }, # Ebain
	{ "who": "lykor", "line": "Shlooks folk." }, # Ebain
]

# Talking to Mattias after that
const MATTIAS_HELP := [
	{ "choice": [
		{ "text": "You could help me?", "steps": [ # Ebain
			{ "who": "mattias", "line": "Bet." }, # Ebain
			{ "do": "guide_all" },
		] },
		{ "text": "Leave", "steps": [] }, # DRAFT (Ebain: "just the ability to leave the convo")
	] },
]
const MATTIAS_GUIDING := [   # talking to him while he's already showing you the way
	{ "who": "mattias", "line": "Follow me folk." }, # DRAFT
]

# All 3 pieces: Deloye, from his room, right away
const DELOYE_CALL := [
	{ "do": "deloye_far" },
	{ "who": "deloye", "line": "You had let's burn it? Pull up my trio." }, # Ebain
	{ "do": "gate_open" },
]

# In Deloye's room
const PASS := [
	{ "do": "deloye_faces" },
	{ "who": "deloye", "line": "You could pass that shit?" }, # Ebain
	{ "choice": [
		{ "text": "Here you go folk.", "steps": [ # Ebain
			{ "do": "give_joint" },
			{ "who": "deloye", "line": "Thank you. Here you go, mud." }, # Ebain
			{ "do": "gift" },
		] },
		{ "text": "You had said puff puff pass?", "steps": [ # Ebain
			{ "do": "smoke" },   # placeholder scene (Ebain may make a real cutscene)
			{ "do": "faded" },
			{ "do": "gift" },    # Ebain 11/25: A and B both get the Neuralink
		] },
		{ "text": "Bad.", "steps": [ # Ebain
			{ "who": "deloye", "line": "Aight. Im not trippin i got da plug on the way" }, # Ebain
			{ "do": "keep_joint" },
		] },
	] },
	{ "who": "deloye", "line": "Alright I'm gonna catch y'all later" }, # Ebain
	{ "do": "teleport_out" },
]

# ---------------------------------------------------------------- the Atrium
const DIRECTORY := [
	{ "who": "xylo", "line": "\"Hall of Wind: west. The Rock Room: east. Restricted Section: past the wind. Reading Room: straight ahead.\"" }, # DRAFT
	{ "who": "xylo", "line": "\"Reading Room: closed.\"" }, # DRAFT
	{ "who": "lykor", "line": "Closed? We came in through a TOILET." }, # DRAFT
]
const RETURN_DESK := [
	{ "who": "skorn", "line": "\"BOOK RETURN. Please do not return Deloye Lore. Nobody has ever finished one.\"" }, # DRAFT
	{ "who": "xylo", "mood": "smug", "line": "I've finished several." }, # DRAFT
]
const CHUTE := [
	{ "who": "lykor", "line": "That's the pipe we fell out of. We could climb back up." }, # DRAFT
	{ "choice": [
		{ "text": "Climb back up the pipe", "steps": [{ "do": "leave_pipe" }] }, # DRAFT
		{ "text": "Not yet", "steps": [{ "who": "xylo", "line": "Good. I'm not done smelling these books." }] }, # DRAFT
	] },
]

# ---------------------------------------------------------------- the Grand Stacks
const CATALOG := [
	{ "who": "xylo", "line": "The card catalog. Every single drawer says \"Deloye Lore.\"" }, # DRAFT
	{ "who": "skorn", "line": "Even the one that says Z?" }, # DRAFT
	{ "who": "xylo", "line": "Especially that one." }, # DRAFT
]
const STAFF_PICKS := [
	{ "who": "lykor", "line": "\"Staff Picks.\" It's one book. Picked by Deloye. Written by Deloye." }, # DRAFT
]
const GATE_SIGN := [
	{ "who": "xylo", "line": "\"READING ROOM. Do not disturb. Unless you're bringing something.\"" }, # DRAFT
	{ "who": "skorn", "line": "Bringing what?" }, # DRAFT
]

# ---------------------------------------------------------------- the Hall of Wind (west)
const WINDOW := [
	{ "who": "lykor", "mood": "angry", "line": "Who opens a window in an underground library? My HAIR." }, # DRAFT
	{ "who": "xylo", "line": "It's lore accurate. In Volume 4,019 the wind just... happens." }, # DRAFT
]
const PAGES := [
	{ "who": "skorn", "line": "Loose pages everywhere. I ain't reading those." }, # DRAFT
	{ "who": "xylo", "line": "They're all page one. He kept starting over." }, # DRAFT
]

# ---------------------------------------------------------------- the Restricted Section (past the wind)
const ROPE := [
	{ "who": "skorn", "line": "\"RESTRICTED SECTION. Lore too lore.\"" }, # DRAFT
	{ "who": "lykor", "line": "A velvet rope. Classy. I'm stepping over it." }, # DRAFT
]

# ---------------------------------------------------------------- the Rock Room (east)
const ROCK := [
	{ "who": "skorn", "line": "\"THE ROCK. As described in Chapter 10,000.\" ...It's a rock." }, # DRAFT
	{ "who": "xylo", "mood": "smug", "line": "It's THE rock." }, # DRAFT
]

# ---------------------------------------------------------------- the Reading Corner (past the rock)
const TABLE := [
	{ "who": "lykor", "line": "Somebody left a magnifying glass. For reading lore this small, you'd need it." }, # DRAFT
]
const RADIO := [   # Ebain 11/25: a radio for his Deloye song (assets/music/deloye_lore.ogg, coming)
	{ "do": "radio" },
]
const RADIO_STATIC := [   # until the song is in
	{ "who": "skorn", "line": "It's just static." }, # DRAFT
	{ "who": "xylo", "line": "The Deloye Lore theme song isn't out yet. Patience." }, # DRAFT
]
const SAVED_SEAT := [
	{ "who": "lykor", "line": "\"SAVED SEAT.\" The bookmark in this chair is older than me." }, # DRAFT
	{ "who": "skorn", "line": "I'm sitting in it." }, # DRAFT
	{ "who": "xylo", "line": "Don't." }, # DRAFT
]

# ---------------------------------------------------------------- the Reading Room (rotunda, the end)
# Talking to him again (one of these at random)
const AGAIN := [
	[{ "who": "deloye", "line": "*nods to the music. Still spinning.*" }], # DRAFT
	[{ "who": "deloye", "line": "Chapter ten thousand is just the word \"rock.\" I'm proud of it." }], # DRAFT
	[{ "who": "deloye", "line": "You good? ...Cool." }], # DRAFT
	[{ "who": "skorn", "line": "Bro is NOT coming down." }, { "who": "deloye", "line": "Nope." }], # DRAFT
]

# The giant book that floats above him
const BOOK := [
	{ "do": "book_swell" },
	{ "who": "xylo", "line": "The original Deloye Lore manuscript. Every page..." }, # DRAFT
	{ "who": "xylo", "line": "...is mostly blank." }, # DRAFT
	{ "who": "deloye", "line": "Still working on it." }, # DRAFT
]

const SHELF := [
	{ "who": "skorn", "line": "\"Deloye Lore, Volume 4,019: The Wind.\" Bro wrote four thousand books about wind." }, # DRAFT
]
const EXIT_DOOR := [
	{ "who": "skorn", "line": "Aight, back up to the village. Hopefully NOT through the toilet." }, # DRAFT
	{ "do": "leave" },
]

const TALK := {   # talking to your own party here
	"skorn": [{ "who": "skorn", "line": "I'm not touching any of these books. They look like homework." }], # DRAFT
	"lykor": [{ "who": "lykor", "line": "Earbuds in, spinning, no hair product. Respect, honestly." }], # DRAFT
	"xylo": [{ "who": "xylo", "mood": "smug", "line": "I'm never leaving. ...Okay, I'm leaving. But spiritually, never." }], # DRAFT
}
