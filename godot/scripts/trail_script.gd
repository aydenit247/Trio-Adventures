# Lines for the Goblin Woods Trail (camp → trail → village). Asar's troll line and choices are used verbatim (# Asar).
# Everything else is # DRAFT (Ebain has the final say). No narrator lines here: only recorded narrator lines stay in the game.
extends RefCounted

const TROLL := "Bridge Troll"   # one-off speaker name (portrait: assets/portraits/troll.png)

const TROLL_MEET := [
	{ "who": "troll", "name": TROLL, "portrait": "troll", "line": "Y'all had said i could get some bussy?" }, # Asar
	{ "choice": [
		{ "text": "It's good", "outcome": "troll_good", "steps": [ # Asar
			{ "who": "troll", "name": TROLL, "portrait": "troll", "line": "Aight bet", "voice": "none" }, # Asar (not the giant's "Aight. Bet." take)
			{ "do": "troll_walk" },   # the troll goes in, Xylo waits on the doorstep...
			{ "who": "lykor", "line": "I always knew you were on that type timing" }, # Ebain
			{ "who": "xylo", "line": "Shut up Lykor" }, # Ebain
			{ "do": "troll_enter" },   # ...then Xylo goes in and stays in the hut until you knock (Asar 11/25)
		] },
		{ "text": "Bad.", "outcome": "troll_bad", "steps": [ # Asar
			{ "who": "troll", "name": TROLL, "portrait": "troll", "line": "BAD?!" }, # DRAFT
			{ "do": "troll_fight" },
		] },
	] },
]

# talking to him again after you ran from the fight
const TROLL_AGAIN := TROLL_MEET


# knocking on the troll's hut after "It's good": Xylo comes back out (Asar 11/25)
const XYLO_OUT := [
	{ "do": "knock" },
	{ "who": "xylo", "line": "Damn he was digging in me, folk" }, # Asar
	{ "do": "xylo_rejoin" },
]

const HUT_SEARCH := [
	{ "do": "hut_loot" },
]

const CHEST := [
	{ "do": "chest_loot" },
]
