# The secret Deloye Lore library (DELOYE_PLAN.md). Every line here is # DRAFT: Ebain writes the real ones.
# Deloye (Ebain's art: messy black hair, grey zip hoodie, wired earbuds) floats and twirls in the middle of the
# rotunda at the far end of the library. Vibe (Ebain 11/24): chill, earbuds in, barely looks up, surprised anyone
# actually read it.
# The walk (11/24, Ebain: "make it a much bigger place you have to walk around in, Deloye at the end"): you land in the
# Atrium, walk the Grand Stacks, and the Reading Room (Deloye's rotunda) is closed until you return 3 overdue volumes
# found in the Hall of Wind, the Restricted Section and the Rock Room.
extends RefCounted

# Landing in a heap after the flush (in the Atrium)
const ARRIVE := [
	{ "who": "skorn", "line": "Bro. We just got FLUSHED." }, # DRAFT
	{ "who": "lykor", "line": "My hair touched outhouse water. Somebody is paying for this." }, # DRAFT
	{ "who": "xylo", "mood": "smug", "line": "Shelves. Endless shelves. Gentlemen... this is the Deloye Lore library." }, # DRAFT
	{ "who": "skorn", "line": "It's hella big. How many books does one dude need to write about nothing." }, # DRAFT
	{ "who": "xylo", "mood": "smug", "line": "All of them, Skorn. All of them." }, # DRAFT
]

# ---------------------------------------------------------------- the Atrium
const DIRECTORY := [
	{ "who": "xylo", "line": "\"Hall of Wind: west. The Rock Room: east. Restricted Section: past the wind. Reading Room: straight ahead.\"" }, # DRAFT
	{ "who": "xylo", "line": "\"Reading Room closed until all overdue books are returned.\"" }, # DRAFT
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
	{ "who": "xylo", "line": "\"READING ROOM. Overdue books must be returned before entry. — Management\"" }, # DRAFT
	{ "who": "skorn", "line": "We don't even got a library card." }, # DRAFT
	{ "who": "xylo", "line": "Three volumes are overdue. The Wind, the Rock, and... a blank one. We find them, we get in." }, # DRAFT
]
const RETURN_SHORT := [   # at the book return with fewer than 3 (the count is shown in the objective)
	{ "who": "xylo", "line": "We still don't have all three. The slot is judging us." }, # DRAFT
]
const GATE_OPEN := [
	{ "do": "return_books" },
	{ "who": "xylo", "mood": "smug", "line": "Returned. All three. Only a few hundred years late." }, # DRAFT
	{ "do": "gate_open" },
	{ "who": "skorn", "line": "The wall is melting. That's normal." }, # DRAFT
	{ "who": "lykor", "line": "Something's in there. Spinning." }, # DRAFT
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
const BOOK_WIND := [
	{ "who": "xylo", "line": "Volume 4,019: The Wind. Forty years overdue. Smells like a breeze." }, # DRAFT
	{ "do": "take:wind" },
]

# ---------------------------------------------------------------- the Restricted Section (past the wind)
const ROPE := [
	{ "who": "skorn", "line": "\"RESTRICTED SECTION. Lore too lore.\"" }, # DRAFT
	{ "who": "lykor", "line": "A velvet rope. Classy. I'm stepping over it." }, # DRAFT
]
const BOOK_BLANK := [
	{ "who": "xylo", "line": "Volume 0. Completely blank." }, # DRAFT
	{ "who": "lykor", "line": "So it's the same as the other ones." }, # DRAFT
	{ "who": "xylo", "mood": "angry", "line": "...How DARE you." }, # DRAFT
	{ "do": "take:blank" },
]

# ---------------------------------------------------------------- the Rock Room (east)
const ROCK := [
	{ "who": "skorn", "line": "\"THE ROCK. As described in Chapter 10,000.\" ...It's a rock." }, # DRAFT
	{ "who": "xylo", "mood": "smug", "line": "It's THE rock." }, # DRAFT
]
const BOOK_ROCK := [
	{ "who": "xylo", "line": "Volume 10,000. The whole book is just the word \"rock.\" I've read it eleven times." }, # DRAFT
	{ "do": "take:rock" },
]

# ---------------------------------------------------------------- the Reading Corner (past the rock)
const TABLE := [
	{ "who": "lykor", "line": "Somebody left a magnifying glass. For reading lore this small, you'd need it." }, # DRAFT
]
const SAVED_SEAT := [
	{ "who": "lykor", "line": "\"SAVED SEAT.\" The bookmark in this chair is older than me." }, # DRAFT
	{ "who": "skorn", "line": "I'm sitting in it." }, # DRAFT
	{ "who": "xylo", "line": "Don't." }, # DRAFT
]

# ---------------------------------------------------------------- the Reading Room (rotunda, the end)
# Walking in the first time
const ROTUNDA := [
	{ "who": "skorn", "line": "Why is there a dude spinning in the middle of it." }, # DRAFT
	{ "who": "lykor", "line": "...Is he okay?" }, # DRAFT
	{ "who": "xylo", "line": "No. It can't be. It's HIM." }, # DRAFT
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
	{ "who": "deloye", "line": "Anyway. You found all my pages. And you returned my books? That's crazy. Here, dragon guy." }, # DRAFT
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
