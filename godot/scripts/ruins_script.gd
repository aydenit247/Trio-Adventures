# Lines for the side path off the Metocy Mart road: the Old Ruins → the trap → the Rat Cave → the Three Seals →
# the Grand Cheese Casino (the old rat colony, RUINS_PLAN.md + Asar's "Rat Casino: Script & Plan" doc), plus
# Charis's house on the Mart street.
# Asar wrote the ruins/cave/casino script (11/27): his lines are verbatim (# Asar). Ebain's always win (# Ebain).
# Everything else is # DRAFT. Names: King Nibsworth III ("the Third" in dialogue), Scrounge, Lil Nibbs (the pet rat).
extends RefCounted

const KING := "King Nibsworth III"
const TRADER := "Scrounge"

# ---------------------------------------------------------------- the Old Ruins
const INTRO := [
	{ "who": "skorn", "line": "Yep, just some old ahh ruins." }, # Asar
	{ "who": "xylo", "line": "Wonder what kind of ancient lore we can find here." }, # Asar
	{ "who": "skorn", "mood": "smug", "line": "Fuck the lore, I'm tryna get some loot mud." }, # Asar
]

const BIG_CHEST := [
	{ "who": "skorn", "mood": "smug", "line": "Ayyyy this what im TALM BOUT." }, # Asar
	{ "who": "xylo", "mood": "unimpressed", "line": "Don't touch that shit bro, it's obviously a trap." }, # Asar
	{ "who": "skorn", "mood": "angry", "line": "Shut yo overgrown lizard ass up." }, # Asar
	{ "choice": [
		{ "text": "Open it (it's fine)", "steps": [{ "do": "trap" }] }, # DRAFT (choice text)
		{ "text": "Leave it (for now)", "steps": [] }, # DRAFT (choice text). Asar: leaving says nothing
	] },
]

const HOLE := [
	{ "who": "skorn", "line": "Bro.. no shot" }, # Ebain (11/25 reword)
	{ "do": "jump_hole" },
]

const BACK_FROM_CAVE := [
	{ "who": "lykor", "mood": "angry", "line": "Sunlight. Finally. My hair needs sunlight." }, # DRAFT
]

# ---------------------------------------------------------------- the cave
const LANDED := [
	{ "who": "skorn", "mood": "confused", "line": "Mah fault." }, # Asar
	{ "who": "lykor", "mood": "angry", "line": "You bout dumb as a muhfucka." }, # Asar
	{ "who": "skorn", "line": "You woulda done the same, shit was mad shiny." }, # Asar
	{ "who": "xylo", "mood": "smug", "line": "We chillin' these mfs don't know I got ties with Dulbmeethus" }, # Asar
]

const HOLE_AGAIN := [
	{ "who": "skorn", "mood": "smug", "line": "Nailed the landing that time." }, # DRAFT
]

const ROPE_UP := {   # the dangling rope under the hole: too high to climb (whoever looks at it)
	"skorn": [{ "who": "skorn", "line": "My fat ahh can't climb up there." }], # Asar
	"xylo": [{ "who": "xylo", "line": "Wish I had some fuckin' wings." }], # Asar
	"lykor": [{ "who": "lykor", "line": "I ain't risking my hair getting stuck on this rope." }], # Asar
}

# ---- the Three Seals. Boulders: BIG (Skorn only), BOOK (Xylo only), LOTION (Lykor only).
#   (internal keys stay "spoon" = big and "bowl" = lotion so old saves keep working)
const DOOR_LOOK := {   # the sealed rock door, whoever looks
	"skorn": [{ "who": "skorn", "mood": "angry", "line": "Man this puzzle shit OD." }], # Asar
	"xylo": [{ "who": "xylo", "mood": "angry", "line": "Man this puzzle shit OD." }], # Asar
	"lykor": [{ "who": "lykor", "mood": "angry", "line": "Man this puzzle shit OD." }], # Asar
}

const BIG_NO := {   # trying to push the big boulder as someone who isn't Skorn
	"lykor": [{ "who": "lykor", "mood": "angry", "line": "It won't budge. And I'm NOT breaking a nail for a rock." }], # DRAFT
	"xylo": [{ "who": "xylo", "mood": "unimpressed", "line": "It does not move. I am a lore guy, not a moving guy." }], # DRAFT
}
const BOOK_NO := {   # the book boulder: Xylo only
	"skorn": [{ "who": "skorn", "mood": "confused", "line": "It got a book on it. That's Xylo's rock, I don't touch books." }], # DRAFT
	"lykor": [{ "who": "lykor", "line": "A rock with homework on it. Xylo. Your rock." }], # DRAFT
}
const LOTION_NO := {   # the lotion boulder: Lykor only
	"skorn": [{ "who": "skorn", "mood": "confused", "line": "My hands too greasy now. That's Lykor's rock." }], # DRAFT
	"xylo": [{ "who": "xylo", "mood": "unimpressed", "line": "That is the moisturized rock. Lykor's department." }], # DRAFT
}

const CRACK_NO := {   # the crack in the wall: only Lykor fits
	"skorn": [{ "who": "skorn", "mood": "angry", "line": "I aint fitting in there mud, im big boned." }], # Asar
	"xylo": [{ "who": "xylo", "mood": "confused", "line": "Crack in the wall? Yall had said I could crack sum?" }], # Asar
	"xylo_troll": [{ "who": "xylo", "mood": "unimpressed", "line": "Crack in the wall? I did enough crackin' for one day." }], # Asar (if he gave the troll what he wanted)
}
const CRACK_LYKOR := [
	{ "who": "lykor", "mood": "smug", "line": "Out the way fat fucks, lemme show you how a moisturized mf does it." }, # Asar
	{ "do": "crack_in" },
]
const LEVER := [
	{ "who": "lykor", "line": "Lemme peep what this lever talm bout." }, # Asar
	{ "do": "pull_lever" },
]
const LEVER_DONE := [
	{ "who": "skorn", "mood": "unimpressed", "line": "Yep, we just get another rock.." }, # Asar
	{ "who": "xylo", "line": "Chapter 5609, Page 63, Section 8, The lever shall be pulled and out will come another boulder.. Classic Deloye." }, # Asar
	{ "who": "lykor", "mood": "smug", "line": "Yall welcome." }, # Asar
]

const CARVING := {   # the painting/carving: only Xylo can read it (the plates' symbols are worn off until he does)
	"xylo": [
		{ "who": "xylo", "mood": "vision", "line": "Ah.. ancient rat scripture." }, # Asar
		{ "do": "read_carving" },
		{ "who": "xylo", "line": "It had said to place the lore book west, by the rat scripture. The one only moveable by an orc shall reside in the middle of the arena. The item that makes all shiny and smooth belongs in a corner." }, # Asar
	],
	"skorn": [
		{ "who": "skorn", "mood": "confused", "line": "Great.. more squiggly ass lines. Anybody got a light?" }, # Asar
	],
	"lykor": [
		{ "who": "lykor", "mood": "smug", "line": "I don't read. I get read about." }, # Asar
	],
}
const CARVING_AGAIN := [
	{ "who": "xylo", "line": "Book goes west by the scripture. The orc rock in the middle. The lotion in a corner. And the plates are glowing now." }, # DRAFT
]

const RESET := {   # pulling the reset rope, by whoever pulls it
	"skorn": [{ "who": "skorn", "mood": "angry", "line": "This shit OD as hell, im restarting." }, { "do": "reset" }], # Asar
	"lykor": [{ "who": "lykor", "mood": "smug", "line": "I'm giving the puzzle a second chance to appreciate my jawline." }, { "do": "reset" }], # Asar
	"xylo": [{ "who": "xylo", "line": "I need to read up on my lore. Restart this shit." }, { "do": "reset" }], # Asar
}

const HINT := {   # after 30 s without progress, whoever's leading says one (then cave.gd gives exact next moves)
	"skorn": [{ "who": "skorn", "mood": "confused", "line": "Man, these rocks don't stop till they hit somethin'. So… make 'em hit somethin'." }], # DRAFT
	"lykor": [{ "who": "lykor", "line": "They slide till they hit something, folk. Use the pillars. Each of us got our own rock." }], # DRAFT
	"xylo": [{ "who": "xylo", "line": "A boulder only stops when something stops it. The pillars are the key. Also: there's a crack in the east wall only a slim man could fit through." }], # DRAFT
}

const NOT_READ := [
	{ "who": "lykor", "line": "The plates clicked. Then… nothing. The carving's glowing." }, # DRAFT
	{ "who": "skorn", "line": "Somebody gotta READ it. Not it." }, # DRAFT
]

const SOLVED := [
	{ "do": "door_open" },
	{ "who": "skorn", "mood": "smug", "line": "I did the heavy lifting.. that was pretty much all me." }, # Asar
	{ "who": "lykor", "mood": "unimpressed", "line": "Pipe down chud." }, # Asar
	{ "who": "xylo", "mood": "unimpressed", "line": "The bipedal eggplant spitting non-sense." }, # Asar
]

# ---- the Grand Cheese Casino: the 5-way choice (outcome ids rats_*)
const COLONY := [
	{ "who": "rats", "line": "Intruders *squeak*" }, # Asar
	{ "who": "rat_king", "line": "Who dares enter the court of King Nibsworth the Third? This is a Rodent only club.." }, # Asar
	{ "who": "skorn", "mood": "confused", "line": "We had fell in a hole mud." }, # Asar
	{ "who": "rat_king", "line": "Yo dumbahh fell for the chest shi, aint you?" }, # Asar
	{ "who": "skorn", "mood": "unimpressed", "line": "I don't wanna talk about it." }, # Asar
	{ "who": "rat_trader", "line": "Yall had said pull up n buy some shi? I got a wife and kidz I need to feed." }, # Asar
	{ "who": "rat_king", "line": "Strangers.. you stand in my kingdom. Explain yourselves." }, # Asar
	{ "choice": [
		{ "text": "Fight the whole casino", "outcome": "rats_fight", "steps": [ # DRAFT (choice text)
			{ "who": "skorn", "mood": "angry", "line": "We bouta explain with these hands folk." }, # Asar
			{ "who": "rat_king", "line": "GUARDS. NIBBLE THEM." }, # Asar
			{ "do": "colony_fight" },
			{ "who": "rat_king", "line": "Aight, aight! Y'all can stay. Just stop hitting the staff and go lose some money like everybody else." }, # DRAFT
		] },
		{ "text": "Steal the Cracker Rat's cracker", "outcome": "rats_cracker", "steps": [ # DRAFT (choice text)
			{ "do": "steal_cracker" },
			{ "who": "skorn", "mood": "smug", "line": "Stole that shit." }, # Asar
			{ "who": "rat", "name": "Rat (Has a Cracker)", "portrait": "casino_staff_cracker", "line": "Your holy nibbleness.. Great-Value Thanos just stole my cracker." }, # Asar
			{ "who": "rat_king", "line": "GUARDS. GET THAT CRACKER!!!" }, # Asar
			{ "do": "cracker_fight" },
			{ "who": "rat", "name": "Rat (Had a Cracker)", "portrait": "casino_staff_cracker", "line": "…Can I at least get my cracker back?" }, # DRAFT
			{ "who": "skorn", "mood": "smug", "line": "No." }, # DRAFT
		] },
		{ "text": "\"We're here to do business.\"", "outcome": "rats_trade", "steps": [ # DRAFT (choice text)
			{ "who": "xylo", "line": "We are simply here to conduct business." }, # Asar
			{ "who": "rat_trader", "line": "FINALLY. Men of commerce." }, # Asar
			{ "who": "rat_king", "line": "Fine. Scrounge, show em' around, they look loaded." }, # Asar
			{ "do": "trade_deal" },
		] },
		{ "text": "Xylo out-lores the King", "outcome": "rats_lore", "steps": [ # DRAFT (choice text)
			{ "who": "xylo", "mood": "smug", "line": "Yo nibbles, simple question. What does the almighty Deloye smoke on?" }, # Asar
			{ "who": "rat_king", "line": "Uh.... Cheese? Wait no.. uh... Ion even know folk." }, # Asar
			{ "who": "xylo", "mood": "smug", "line": "Neuralink Nugs. Loads the whole lore straight into your brain. Everybody knows that mud." }, # Asar
			{ "who": "rat_king", "line": "Not even gon' hold you.. I been shmokin' straight crackers n lint for years." }, # Asar
			{ "who": "xylo", "mood": "unimpressed", "line": "It shows." }, # Asar
			{ "who": "rat_king", "line": "Yall.. He knows the deep texts. Dis mf got aura, don't do nun stupid." }, # Asar
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

const KING_TALK := {   # talking to the King again, by outcome
	"fight": [{ "who": "rat_king", "line": "Y'all still here? Go lose some money. Quietly." }], # DRAFT
	"cracker": [{ "who": "rat_king", "line": "That was his only cracker. Y'all are monsters. Welcome to the casino." }], # DRAFT
	"king": [{ "who": "rat_king", "line": "Former king, current advisor. Long live King Skorn." }], # DRAFT (old saves)
	"trade": [{ "who": "rat_king", "line": "Business is good. Lose something. Scrounge has a wife and kidz." }], # DRAFT
	"lore": [{ "who": "rat_king", "line": "The secret way's in the back, lore master. Neuralink Nugs… I gotta find me some." }], # DRAFT
	"mog": [{ "who": "rat_king", "line": "Please stop looking at me. I'm insecure now." }], # DRAFT
}
const TRADER_GONE := [
	{ "who": "skorn", "line": "Shop's closed. Guess beating up the landlord was bad for business." }, # DRAFT
]

# the casino staff (cave.gd builds them; one line each, all DRAFT from the plan doc as Asar edited it)
const STAFF := {
	"cracker": [{ "who": "rat", "name": "Rat (Has a Cracker)", "portrait": "casino_staff_cracker", "line": "This my cracker. Don't look at it." }], # DRAFT
	"cracker_gone": [{ "who": "rat", "name": "Rat (Had a Cracker)", "portrait": "casino_staff_cracker", "line": "I'm not over it." }], # DRAFT
	"dealer": [{ "who": "rat", "name": "Rat (Dealer)", "portrait": "casino_staff_dealer", "line": "Place your bets. No sniffing the cards." }], # DRAFT
	"croupier": [{ "who": "rat", "name": "Rat (Croupier)", "portrait": "casino_staff_croupier", "line": "Place your bets. No sniffing the cards." }], # DRAFT (baccarat dealer)
	"cashier": [{ "who": "rat", "name": "Rat (Cashier)", "portrait": "casino_staff_cashier", "line": "Gold in, chips out…" }], # DRAFT
	"bouncer": [{ "who": "rat", "name": "Rat (Bouncer)", "portrait": "casino_staff_bouncer", "line": "No outside cheese." }], # DRAFT
	"high_roller": [{ "who": "rat", "name": "Rat (High Roller)", "portrait": "casino_staff_high_roller", "line": "I put my whole tail on black once." }], # DRAFT
	"cocktail": [{ "who": "rat", "name": "Rat (Cocktail Waiter)", "portrait": "casino_staff_cocktail", "line": "Free bottle-cap drink?" }], # DRAFT
	"lost_it_all": [{ "who": "rat", "name": "Rat (Lost It All)", "portrait": "casino_staff_lost_it_all", "line": "One more spin. ONE more." }], # DRAFT
	"podcast": [{ "who": "rat", "name": "Rat (Has a Podcast)", "portrait": "casino_staff_podcast", "line": "Yo, y'all tryna record a podcast?" }], # DRAFT
	"wheel_host": [{ "who": "rat", "name": "Rat (Wheel Host)", "portrait": "casino_staff_wheel_host", "line": "Spin the Cheese Wheel! Opening soon." }], # DRAFT
	"announcer": [{ "who": "rat", "name": "Rat (Announcer)", "portrait": "casino_fighter_announcer", "line": "LADIES, GENTLEMEN AND RODENTS!" }], # DRAFT
	"wheel_rat": [{ "do": "lights_out" }, { "who": "rat", "name": "Rat (Runs the Power)", "portrait": "casino_staff_wheel_rat", "line": "My bad." }, { "do": "lights_on" }], # DRAFT
	"guard": [{ "who": "rat", "name": "Rat (Royal Guard)", "line": "VIP balcony. Royals only." }], # DRAFT
}
const RAT_CHATTER := [   # (old colony chatter, kept for anything still using it)
	[{ "who": "rat", "line": "Ever eaten a crumb so good you cried? Me neither. Still looking." }], # DRAFT
	[{ "who": "rat", "line": "The hole upstairs? That's marketing." }], # DRAFT
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
const CHARIS_PC := [   # her gaming setup (Ebain 11/24). All DRAFT until Ebain writes them
	{ "who": "charis", "line": "Don't touch my setup. I'm mid-match." }, # DRAFT
]
const CHARIS_AGAIN := [
	{ "who": "charis", "line": "Still here. Still don't touch nothing." }, # DRAFT
]
