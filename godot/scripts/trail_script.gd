# Lines for the Goblin Woods Trail (camp → trail → village). Asar's troll line and choices are used verbatim (# Asar).
# Everything else is # DRAFT (Ebain has the final say). No narrator lines here: only recorded narrator lines stay in the game.
extends RefCounted

const TROLL := "Bridge Troll"   # one-off speaker name (portrait: assets/portraits/troll.png)

const INTRO := [
	{ "who": "skorn", "mood": "confused", "line": "Who drew this map? Why is the village an inch away?" }, # DRAFT
	{ "who": "xylo", "mood": "unimpressed", "line": "You burned the map, Skorn." }, # DRAFT
]

const TROLL_MEET := [
	{ "who": "goblin", "name": TROLL, "portrait": "troll", "line": "Y'all had said i could get some bussy?" }, # Asar
	{ "choice": [
		{ "text": "It's good", "steps": [ # Asar
			{ "do": "troll_good" },
			{ "do": "xylo_back" },
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

const HUT_DOOR_GOOD := [
	{ "who": "xylo", "mood": "unimpressed", "line": "We are not knocking on that door." }, # DRAFT
]

const HUT_SEARCH := [
	{ "do": "hut_loot" },
]

const CHEST := [
	{ "do": "chest_loot" },
]
