# The secret Deloye Lore library (DELOYE_PLAN.md). Every line here is # DRAFT: Ebain writes the real ones.
# Deloye (Ebain's art: messy black hair, grey zip hoodie, wired earbuds) floats and twirls in the middle of the
# library. Vibe (Ebain 11/24): chill, earbuds in, barely looks up, surprised anyone actually read it.
extends RefCounted

# Landing in a heap after the flush
const ARRIVE := [
	{ "who": "skorn", "line": "Bro. We just got FLUSHED." }, # DRAFT
	{ "who": "lykor", "line": "My hair touched outhouse water. Somebody is paying for this." }, # DRAFT
	{ "who": "xylo", "mood": "smug", "line": "Shelves. Endless shelves. Gentlemen... this is the Deloye Lore library." }, # DRAFT
	{ "who": "skorn", "line": "Why is there a dude spinning in the middle of it." }, # DRAFT
]

# First talk: he takes ONE earbud out
const MEET := [
	{ "do": "earbud_out" },
	{ "who": "deloye", "line": "Oh. Hey." }, # DRAFT
	{ "who": "xylo", "line": "You're... Deloye. THE Deloye. I've read every chapter. Twice." }, # DRAFT
	{ "who": "deloye", "line": "Wait, fr? Like all of it?" }, # DRAFT
	{ "who": "xylo", "mood": "smug", "line": "Chapter 8,784, section B12. True metocy is never moist." }, # DRAFT
	{ "who": "deloye", "line": "Yeah... I kinda just wrote that. Didn't think anybody would actually read it, ngl." }, # DRAFT
	{ "who": "skorn", "line": "Why are you spinning." }, # DRAFT
	{ "who": "deloye", "line": "Idk. It's a vibe. I've been up here a while." }, # DRAFT
	{ "who": "lykor", "line": "How did you get up there?" }, # DRAFT
	{ "who": "deloye", "line": "Same way you got down here, bro." }, # DRAFT
	{ "who": "deloye", "line": "Anyway. You found all my pages. That's crazy. Here, dragon guy." }, # DRAFT
	{ "do": "gift" },
	{ "who": "deloye", "line": "Deloye Lore Neuralink. Plug it in and you just... know what's about to happen. Mostly." }, # DRAFT
	{ "who": "xylo", "line": "I can hear the lore. I can SEE the next move. Is this what it feels like to be you?" }, # DRAFT
	{ "who": "deloye", "line": "Kinda. Aight, I'm putting my earbud back in. Exit's that way. Don't tell anybody about this place." }, # DRAFT
	{ "do": "earbud_in" },
]

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

# Things to look at
const TABLE := [
	{ "who": "lykor", "line": "Somebody left a magnifying glass. For reading lore this small, you'd need it." }, # DRAFT
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
