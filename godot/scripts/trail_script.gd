# Lines for the Goblin Woods Trail (camp → trail → village). Asar's troll line and choices are used verbatim (# Asar).
# Everything else is # DRAFT (Ebain has the final say).
extends RefCounted

const TROLL := "Bridge Troll"   # one-off speaker name (portrait: assets/portraits/troll.png)

const INTRO := [
	{ "who": "narrator", "line": "The trail to the goblin village. It's a lot longer than it looked on the map." }, # DRAFT
	{ "who": "skorn", "mood": "confused", "line": "Who drew this map? Why is the village an inch away?" }, # DRAFT
	{ "who": "xylo", "mood": "unimpressed", "line": "You burned the map, Skorn." }, # DRAFT
]

const TROLL_MEET := [
	{ "who": "goblin", "name": TROLL, "portrait": "troll", "line": "Y'all had said i could get some bussy?" }, # Asar
	{ "choice": [
		{ "text": "It's good", "steps": [ # Asar
			{ "who": "narrator", "line": "Xylo follows the troll into his hut." }, # DRAFT
			{ "do": "troll_good" },
			{ "who": "narrator", "line": "Some time passes." }, # DRAFT
			{ "do": "xylo_back" },
			{ "who": "narrator", "line": "Xylo comes back out. He does not elaborate. Nobody asks." }, # DRAFT
			{ "who": "xylo", "mood": "unimpressed", "line": "The bridge is open. Let us go." }, # DRAFT
		] },
		{ "text": "Bad.", "steps": [ # Asar
			{ "who": "goblin", "name": TROLL, "portrait": "troll", "line": "BAD?!" }, # DRAFT
			{ "do": "troll_fight" },
		] },
	] },
]

# talking to him again after you ran from the fight
const TROLL_AGAIN := TROLL_MEET

const TROLL_BEATEN := [
	{ "who": "narrator", "line": "The troll is out cold. His hut is wide open." }, # DRAFT
]

const HUT_DOOR_GOOD := [
	{ "who": "narrator", "line": "A sign on the door: \"DO NOT DISTURB.\" Xylo will not look at it." }, # DRAFT
]

const HUT_SEARCH := [
	{ "who": "narrator", "line": "You search the troll's hut. Mostly spoons. One sock. Some gold." }, # DRAFT
	{ "do": "hut_loot" },
]

const CHEST := [
	{ "who": "narrator", "line": "The troll's chest. It's full of gold. Trolls don't believe in banks." }, # DRAFT
	{ "do": "chest_loot" },
]

# searchable spots along the trail: [what it is, the line]
const LOOT_LINES := {
	"bush": "You rummage through the bush. Something shiny was in there.", # DRAFT
	"log": "A hollow log. Somebody hid their stuff in here. Finders keepers.", # DRAFT
	"stump": "There's a little hole in the stump. Coins. Squirrels are getting rich out here.", # DRAFT
	"rocks": "Under the rocks: a coin pouch. And a very surprised bug.", # DRAFT
}
