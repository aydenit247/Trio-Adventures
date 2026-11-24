# Lines for the side path off the Metocy Mart road: the Old Ruins → the trap → the Rat Cave → the Three Seals →
# the Rat Colony (RUINS_PLAN.md), plus Charis's house on the Mart street.
# EVERYTHING here is # DRAFT: placeholders until Ebain writes the real lines (his always win, tag them # Ebain).
# Names are DRAFT too: King Nibbsworth III (Rat King), Scrounge (rat trader), Lil Nibbs (the pet rat).
extends RefCounted

const KING := "King Nibbsworth III"
const TRADER := "Scrounge"

# ---------------------------------------------------------------- the Old Ruins
const INTRO := [
	{ "who": "skorn", "mood": "smug", "line": "Old ruins. You know what that mean." }, # DRAFT
	{ "who": "xylo", "line": "History. Culture. The echoes of a forgotten civiliza—" }, # DRAFT
	{ "who": "skorn", "line": "Loot." }, # DRAFT
	{ "who": "lykor", "mood": "angry", "line": "Don't touch nothing that looks like a trap." }, # DRAFT
]

const BIG_CHEST := [
	{ "who": "skorn", "mood": "smug", "line": "Biggest, shiniest chest I ever seen. Middle of the floor. Nobody guarding it." }, # DRAFT
	{ "who": "xylo", "mood": "unimpressed", "line": "That is the most obvious trap in the history of Deloye Lore." }, # DRAFT
	{ "who": "skorn", "mood": "confused", "line": "Then why it's so shiny, mud?" }, # DRAFT
	{ "choice": [
		{ "text": "Open it (it's fine)", "steps": [{ "do": "trap" }] }, # DRAFT
		{ "text": "Leave it (for now)", "steps": [
			{ "who": "skorn", "mood": "angry", "line": "Fine. But it's calling my name." }, # DRAFT
		] },
	] },
]

const HOLE := [
	{ "who": "skorn", "line": "Again? Bet." }, # DRAFT
	{ "do": "jump_hole" },
]

const BACK_FROM_CAVE := [
	{ "who": "lykor", "mood": "angry", "line": "Sunlight. Finally. My hair needs sunlight." }, # DRAFT
]

# ---------------------------------------------------------------- the cave
const LANDED := [
	{ "who": "skorn", "mood": "confused", "line": "…My fault." }, # DRAFT
	{ "who": "lykor", "mood": "angry", "line": "Bro. BRO. What did I literally just say." }, # DRAFT
	{ "who": "skorn", "line": "The chest was empty anyway." }, # DRAFT
	{ "who": "xylo", "mood": "shocked", "line": "We are in a cave. A cave full of… are those rats? With spears?" }, # DRAFT
]

const HOLE_AGAIN := [
	{ "who": "skorn", "mood": "smug", "line": "Nailed the landing that time." }, # DRAFT
]

const ROPE_UP := [   # the dangling rope under the hole: too high to reach
	{ "who": "lykor", "line": "The hole's way up there. We ain't climbing that." }, # DRAFT
	{ "who": "xylo", "line": "There must be another way out. Rats always have another way out." }, # DRAFT
]

# ---- the Three Seals
const DOOR_LOOK := [
	{ "who": "lykor", "line": "A door with no handle. Three round stones on the floor. Three boulders. Great." }, # DRAFT
	{ "who": "xylo", "mood": "smug", "line": "And carvings on the wall. A puzzle. My favorite genre." }, # DRAFT
]

const BIG_NO := {   # trying to push the big boulder as someone who isn't Skorn
	"lykor": [{ "who": "lykor", "mood": "angry", "line": "It won't budge. And I'm NOT breaking a nail for a rock." }], # DRAFT
	"xylo": [{ "who": "xylo", "mood": "unimpressed", "line": "It does not move. I am a lore guy, not a moving guy." }], # DRAFT
}

const CRACK_NO := {   # the crack in the wall: only Lykor fits
	"skorn": [{ "who": "skorn", "mood": "angry", "line": "I ain't fittin' in there, mud. I'm big boned." }], # DRAFT
	"xylo": [{ "who": "xylo", "mood": "unimpressed", "line": "Dragon. Wings. No." }], # DRAFT
}
const CRACK_LYKOR := [
	{ "who": "lykor", "mood": "smug", "line": "Small, slick, and moisturized. Watch this." }, # DRAFT
	{ "do": "crack_in" },
]
const LEVER := [
	{ "who": "lykor", "line": "A lever. In a secret room. Obviously I'm pulling it." }, # DRAFT
	{ "do": "pull_lever" },
]
const LEVER_DONE := [
	{ "who": "skorn", "mood": "shocked", "line": "A whole boulder just rolled out the wall!" }, # DRAFT
	{ "who": "lykor", "mood": "smug", "line": "You're welcome." }, # DRAFT
]

const CARVING := {   # the wall carving: only Xylo can read it (the plates' symbols are worn off until he does)
	"xylo": [
		{ "who": "xylo", "mood": "vision", "line": "Ancient rat runes. 'The SPOON sleeps beside the first pillar. The BOOK hides by the west wall. The BOWL rests in the corner of the sun.'" }, # DRAFT
		{ "do": "read_carving" },
		{ "who": "xylo", "mood": "unimpressed", "line": "Also somebody carved 'Nibbsworth is mid' under it." }, # DRAFT
	],
	"skorn": [
		{ "who": "skorn", "mood": "confused", "line": "More squiggly ass lines. Anybody got a lighter?" }, # DRAFT
		{ "who": "lykor", "mood": "angry", "line": "DON'T." }, # DRAFT
	],
	"lykor": [
		{ "who": "lykor", "mood": "smug", "line": "I don't read. I get read ABOUT." }, # DRAFT
	],
}
const CARVING_AGAIN := [
	{ "who": "xylo", "line": "Spoon by the first pillar. Book by the west wall. Bowl in the corner of the sun. The plates are glowing now." }, # DRAFT
]

const RESET := [
	{ "do": "reset" },
	{ "who": "rat", "line": "skill issue." }, # DRAFT (a rat pops out of a hole)
]

const HINT := {   # after 90 s without progress, whoever's leading says one
	"skorn": [{ "who": "skorn", "mood": "confused", "line": "Man, these rocks don't stop till they hit somethin'. So… make 'em hit somethin'." }], # DRAFT
	"lykor": [{ "who": "lykor", "line": "They slide till they hit something, folk. Use the pillars. And the big one's Skorn's job." }], # DRAFT
	"xylo": [{ "who": "xylo", "line": "A boulder only stops when something stops it. The pillars are the key. Also: there's a crack in the east wall only a slim man could fit through." }], # DRAFT
}

const NOT_READ := [
	{ "who": "lykor", "line": "The plates clicked. Then… nothing. The carving's glowing." }, # DRAFT
	{ "who": "skorn", "line": "Somebody gotta READ it. Not it." }, # DRAFT
]

const SOLVED := [
	{ "do": "door_open" },
	{ "who": "skorn", "mood": "smug", "line": "WE DID THAT." }, # DRAFT
	{ "who": "lykor", "mood": "smug", "line": "I did the lever." }, # DRAFT
	{ "who": "xylo", "mood": "smug", "line": "I read the wall." }, # DRAFT
	{ "who": "skorn", "line": "I pushed the big one. So I did most of it." }, # DRAFT
]

# ---- the Rat Colony: the 5-way choice (outcome ids rats_*)
const COLONY := [
	{ "who": "rats", "line": "INTRUDERS! SQUEAK!" }, # DRAFT
	{ "who": "rat_king", "line": "Who dares enter the court of King Nibbsworth the Third? Lord of the Crust. Keeper of the Corn." }, # DRAFT
	{ "who": "skorn", "mood": "confused", "line": "We fell in a hole." }, # DRAFT
	{ "who": "rat_king", "line": "Everybody falls in the hole. The hole is how we get customers." }, # DRAFT
	{ "who": "rat_trader", "line": "Customers! I got deals, I got steals, I got a sock with only ONE hole in it." }, # DRAFT
	{ "who": "rat_king", "line": "Silence, Scrounge. Strangers, you stand in my kingdom. Explain yourselves." }, # DRAFT
	{ "choice": [
		{ "text": "Fight the whole colony", "outcome": "rats_fight", "steps": [ # DRAFT
			{ "who": "skorn", "mood": "angry", "line": "We explain with our hands." }, # DRAFT
			{ "who": "rat_king", "line": "GUARDS. NIBBLE THEM." }, # DRAFT
			{ "do": "colony_fight" },
		] },
		{ "text": "\"Skorn is your new king.\"", "outcome": "rats_king", "steps": [ # DRAFT
			{ "who": "lykor", "mood": "smug", "line": "Actually? This is your new king." }, # DRAFT
			{ "who": "skorn", "mood": "shocked", "line": "I am?" }, # DRAFT
			{ "who": "rat_king", "line": "Hmm. He IS big. He IS dirty. He DOES smell like the dumpster behind the Metocy Mart." }, # DRAFT
			{ "do": "crown_skorn" },
			{ "who": "rats", "line": "ALL HAIL KING SKORN!" }, # DRAFT
			{ "who": "skorn", "mood": "smug", "line": "Second throne this week. I'm on a roll." }, # DRAFT
			{ "who": "rat_trader", "line": "Royal discount for the new king! Half off! Please don't eat me." }, # DRAFT
		] },
		{ "text": "\"We're here to do business.\"", "outcome": "rats_trade", "steps": [ # DRAFT
			{ "who": "xylo", "line": "We are simply here to do business." }, # DRAFT
			{ "who": "rat_trader", "line": "FINALLY. Men of commerce." }, # DRAFT
			{ "who": "rat_king", "line": "Fine. Scrounge, open the good shelf. The one behind the other shelf." }, # DRAFT
			{ "do": "trade_deal" },
		] },
		{ "text": "Xylo out-lores the Rat King", "outcome": "rats_lore", "steps": [ # DRAFT
			{ "who": "xylo", "mood": "smug", "line": "Your Majesty. Name the seventh moon of Deloye." }, # DRAFT
			{ "who": "rat_king", "line": "…The… cheese moon?" }, # DRAFT
			{ "who": "xylo", "mood": "smug", "line": "There is no seventh moon. There is barely a first one. Deloye Lore volume twelve, page nothing." }, # DRAFT
			{ "who": "rat_king", "line": "…He knows the deep texts. Show him the secret way out." }, # DRAFT
			{ "do": "lore_win" },
		] },
		{ "text": "Lykor mogs them", "outcome": "rats_mog", "steps": [ # DRAFT
			{ "who": "lykor", "mood": "mog", "line": "Allow me." }, # DRAFT
			{ "do": "mog_rats" },
			{ "who": "rats", "line": "…He's so beautiful." }, # DRAFT
			{ "who": "rat_king", "line": "I have never felt so ugly. And I am a rat." }, # DRAFT
			{ "who": "rat", "name": "Tiny Rat", "line": "I will follow you forever." }, # DRAFT
			{ "who": "lykor", "mood": "flattered", "line": "Obviously." }, # DRAFT
			{ "do": "pet_joins" },
		] },
	] },
	{ "do": "colony_after" },
]

const KING_TALK := {   # talking to the king again, by outcome
	"king": [{ "who": "rat_king", "line": "Former king, current advisor. Long live King Skorn." }], # DRAFT
	"trade": [{ "who": "rat_king", "line": "Business is good. Buy something. Scrounge has a family. Of four hundred." }], # DRAFT
	"lore": [{ "who": "rat_king", "line": "The secret way is behind the junk pile, lore master. Go in peace." }], # DRAFT
	"mog": [{ "who": "rat_king", "line": "Please stop looking at me. I'm insecure now." }], # DRAFT
}
const TRADER_GONE := [
	{ "who": "skorn", "line": "Shop's closed. Guess beating up the landlord was bad for business." }, # DRAFT
]
const RAT_CHATTER := [   # talking to a colony rat
	[{ "who": "rat", "line": "Ever eaten a crumb so good you cried? Me neither. Still looking." }], # DRAFT
	[{ "who": "rat", "line": "The hole upstairs? That's marketing." }], # DRAFT
	[{ "who": "rat", "line": "I'm not a rat. I'm a mouse with a big back." }], # DRAFT
	[{ "who": "rat", "line": "Don't tell the King, but the corn is fake." }], # DRAFT
]
const PET_CHATTER := [
	[{ "who": "rat", "name": "Lil Nibbs", "portrait": "rat", "line": "Lykor is so pretty. I have never seen a pretty before." }], # DRAFT
]

const TUNNEL_OUT := [
	{ "who": "xylo", "line": "A tunnel going up. Daylight at the end." }, # DRAFT
	{ "do": "tunnel_out" },
]
const SHORTCUT := [
	{ "who": "xylo", "mood": "smug", "line": "The secret lore tunnel. Straight back to the Metocy Mart road." }, # DRAFT
	{ "do": "shortcut_out" },
]

# ---------------------------------------------------------------- Charis's house (Metocy Mart street)
const CHARIS_HI := [
	{ "who": "charis", "line": "Oh, y'all actually found my house. Come in. Don't touch nothing." }, # DRAFT (Ebain writes Charis's dialogue)
]
const CHARIS_AGAIN := [
	{ "who": "charis", "line": "Still here. Still don't touch nothing." }, # DRAFT
]
