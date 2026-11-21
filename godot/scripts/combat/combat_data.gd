# Combat data: party stats and moves, items, gear, statuses, combos, fights, talk options, banter, chaos.
# Ported from the web version's src/data/combat.js (Combat 2.0). The rules live in battle.gd,
# and battle_view.gd only animates what the rules decide.
#
# Damage is set (Pokémon-style). What changes it: timed hits (PERFECT ×1.5, GOOD ×1.2, MID ×0.9),
# timed blocks (PERFECT ×0.35, BLOCKED ×0.7), Defend (×0.5), statuses, hype, level, gear, difficulty.
class_name CombatData

# spd decides how often someone shows up in the turn order (higher = more turns).
# pose = texture in assets/characters, ph = pose height vs. standing, flip = art faces left.
const PARTY := {
	"skorn": {
		"name": "Skorn", "hp": 90, "spd": 9, "hp_label": "HP (Hit Points)", "meter_label": "Crash Out Juice",
		"moves": {
			"main": { "name": "Diddy Slap", "desc": "A slap with intent. 14 damage.", "pose": "skorn_slap", "ph": 0.85, "kind": "hit", "power": 14, "fx": "slap", "timed": true },
			"special": { "name": "Crash Out", "desc": "Intense rage. Rolls a d6 — on some dice shi. Cooldown 3.", "pose": "skorn_crashout", "ph": 1.0, "kind": "crashout", "cd": 3 },
			"bonus": { "name": "Throw Anything", "desc": "Throws whatever is nearby. 10 damage, might make them Down Bad. Cooldown 2.", "pose": "skorn_throw", "ph": 1.05, "kind": "throw", "power": 10, "cd": 2, "timed": true, "downbad": 0.4 },
			"ult": { "name": "FULL CRASH OUT", "desc": "Rolls TWO dice. 7 damage per pip and strips their buffs. Doubles do something extra.", "pose": "skorn_crashout", "ph": 1.0, "kind": "fullcrash" },
		},
		"learn": { 3: { "name": "Belly Bump", "desc": "Bumps them so hard their next turn comes later. 16 damage. Cooldown 2. (Learned at Level 3)", "pose": "skorn_slap", "ph": 0.85, "kind": "hit", "power": 16, "cd": 2, "fx": "slap", "timed": true, "delay": 0.6 } },
	},
	"lykor": {
		"name": "Lykor", "hp": 70, "spd": 12, "hp_label": "Aura", "meter_label": "Aura Farming",
		"moves": {
			"main": { "name": "Hair Flip", "desc": "10 damage. Might charm them (they skip a turn).", "pose": "lykor_hairflip", "ph": 1.0, "kind": "hit", "power": 10, "fx": "sparkle", "charm": 0.3, "timed": true },
			"special": { "name": "Mog", "desc": "Giga chad face. 20 damage + Mogged (they take 25% more damage). Cooldown 3.", "pose": "lykor_mog", "ph": 1.0, "kind": "hit", "power": 20, "cd": 3, "fx": "mog", "mogged": 2, "timed": true },
			"bonus": { "name": "\"on some type shi\"", "desc": "Screams it. The party hits 50% harder for the next 3 attacks. Cooldown 3.", "pose": "lykor_scream", "ph": 1.0, "kind": "buff", "cd": 3 },
			"ult": { "name": "MOG SUPREME", "desc": "36 damage to EVERY enemy. Mogged + Blinded on all of them.", "pose": "lykor_mog", "ph": 1.0, "kind": "mogsupreme", "power": 36 },
		},
		"learn": { 3: { "name": "Conditioner Mist", "desc": "Sprays the good conditioner. Everyone heals 14 and loses their debuffs. Cooldown 4. (Learned at Level 3)", "pose": "lykor_hairflip", "ph": 1.0, "kind": "healall", "heal": 14, "cd": 4 } },
	},
	"xylo": {
		"name": "Xylo", "hp": 75, "spd": 10, "hp_label": "Lore Points", "meter_label": "Lore Buildup",
		"moves": {
			"main": { "name": "Eldritch Blast", "desc": "Classic. 13 damage.", "pose": "xylo_blast", "ph": 0.95, "flip": true, "kind": "hit", "power": 13, "fx": "blast", "timed": true },
			"special": { "name": "Deloye Lore", "desc": "Reads from a universe with no lore. 24 damage, might make them Lore-pilled (drowsy). Cooldown 3.", "pose": "xylo_lore", "ph": 1.0, "kind": "hit", "power": 24, "cd": 3, "fx": "lore", "lorepill": 0.5, "timed": true },
			"bonus": { "name": "Dragon Breath", "desc": "10 damage + Cooked (burns for 6 a turn, 3 turns). Cooldown 2.", "pose": "xylo_blast", "ph": 0.95, "flip": true, "kind": "hit", "power": 10, "cd": 2, "fx": "fire", "cooked": 3, "timed": true },
			"ult": { "name": "CHUD OUT", "desc": "Gets huge and sits on them. 45 damage and they lose their next turn.", "pose": "xylo_chudout", "ph": 1.6, "kind": "chudout", "power": 45 },
		},
		"learn": { 3: { "name": "Citation Needed", "desc": "Demands a source. 12 damage and strips their buffs. Cooldown 3. (Learned at Level 3)", "pose": "xylo_lore", "ph": 1.0, "kind": "hit", "power": 12, "cd": 3, "fx": "lore", "strip": true, "timed": true } },
	},
	# Recruited ally: joins as a 4th fighter when the goblins are with you (goblinAllies).
	"chief": {
		"name": "Chief Bogdrinker", "hp": 60, "spd": 11, "hp_label": "Beezy Level", "meter_label": "Union Dues",
		"tex": "goblin_chief", "h": 1.45, "ally": true,
		"moves": {
			"main": { "name": "Spoon Bonk", "desc": "The royal spoon. 11 damage.", "kind": "hit", "power": 11, "fx": "slap", "timed": true },
			"special": { "name": "Beezy Toss", "desc": "Tosses a teammate a cold one. Heals 25 (revives at 25). Cooldown 3.", "kind": "healone", "heal": 25, "cd": 3 },
			"bonus": { "name": "Rally The Unemployed", "desc": "Two goblins run in and bonk random enemies for 7 each. Cooldown 2.", "kind": "rally", "hits": 2, "power": 7, "cd": 2 },
			"ult": { "name": "GOBLIN UNION STRIKE", "desc": "The whole village dogpiles. 8 bonks of 7 + Down Bad on everyone.", "kind": "union", "hits": 8, "power": 7 },
		},
	},
}

# Team-ups. Each person in the combo spends `cost` meter. Partners' next turn gets pushed back a bit.
const COMBOS := [
	{ "id": "elftoss", "name": "Elf Toss", "who": ["skorn", "lykor"], "cost": 50, "power": 48, "mogged": 2,
		"desc": "Skorn throws Lykor at them. 48 damage + Mogged. Lykor is not okay with this." },
	{ "id": "loreslap", "name": "Lore Slap", "who": ["skorn", "xylo"], "cost": 50, "power": 8, "hits": 6, "lorepill": 2,
		"desc": "Xylo reads Deloye Lore while Skorn slaps on every comma. 6 hits + Lore-pilled." },
	{ "id": "fireball", "name": "Mogging Fireball", "who": ["lykor", "xylo"], "cost": 50, "power": 28, "aoe": true, "cooked": 3,
		"desc": "Xylo breathes fire through Lykor's hair. 28 damage to everyone + Cooked." },
	{ "id": "trio", "name": "ON SOME TRIO SHI", "who": ["skorn", "lykor", "xylo"], "cost": 60, "power": 85, "heal": 15,
		"desc": "The whole trio, all at once. 85 damage, and everyone heals 15." },
]

const ITEMS := {
	"beer": { "name": "Beezy", "heal": 30, "desc": "Heals 30 (or revives at 30). Makes you Buzzed for a turn." },
	"bowl": { "name": "Chipotle Bowl", "heal": 60, "desc": "Heals 60 (or revives at 60)." },
}

# Gear: each fighter has 7 slots (Game.GEAR_SLOTS). Found in the world or dropped by fights.
#   slot = helmet · armor · shoes · shield · weapon · trinket (trinkets fit either trinket slot)
#   Picture: res://assets/items/<gear id>.png (shown in the inventory when it exists).
#   hp = +max HP · power = +% damage · spd = +speed · meter = ×meter gain · start = starting meter
#   armor = flat damage cut on every hit taken (10 damage − 3 armor = 7; a hit always does at least 1)
#   no_ones = Crash Out dice never roll a 1 · gouge_proof = immune to Price Gouged
const GEAR := {
	"spoon": { "slot": "trinket", "name": "Spoon of Destiny", "desc": "A goblin's spoon. Apparently chosen. +10% damage to all attacks.", "power": 0.10 },
	"weighted_d6": { "slot": "trinket", "name": "Weighted d6", "desc": "On some cheating shi. Crash Out dice can't roll a 1.", "no_ones": true },
	"can_hat": { "slot": "helmet", "name": "Beezy Mug Helmet", "desc": "A beezy mug, worn proudly on the head. Still a little sticky. +2 armor.", "armor": 2 },
	"spoon_mail": { "slot": "armor", "name": "Spoon Mail Armor", "desc": "Armor made of spoons. Goes 'clink.' +3 armor.", "armor": 3 },
	"receipt": { "slot": "trinket", "name": "Metocy Mart Receipt", "desc": "NO REFUNDS. Start every fight with 25 meter, and Price Gouge can't touch you.", "start": 25, "gouge_proof": true },
}

# Permanent boosts: used from the Tab inventory on one fighter, used up, the bonus lasts all game (Game.boosts).
# Kept in Game.inv by id. Same stat keys as GEAR.
const BOOSTS := {
	"conditioner": { "name": "Backup Conditioner", "desc": "Lykor's emergency bottle. Use it on someone for +15 max HP, for good. Lykor wants it back.", "hp": 15 },
	"vol9": { "name": "Deloye Lore Vol. 9 (Signed)", "desc": "Signed by nobody. Read it to someone for +15% meter gain, for good.", "meter": 1.15 },
}

# Statuses. `good` = good for whoever has it. Durations count the holder's own turns.
const STATUS := {
	"mogged": { "label": "MOGGED", "good": false, "desc": "Insecure. Takes 25% more damage." },
	"lorepill": { "label": "LORE-PILLED", "good": false, "desc": "Drowsy. 50% chance to skip each turn." },
	"downbad": { "label": "DOWN BAD", "good": false, "desc": "Deals half damage." },
	"cooked": { "label": "COOKED", "good": false, "desc": "Burns for 6 every turn." },
	"blind": { "label": "BLINDED", "good": false, "desc": "Next attack has a 60% chance to miss." },
	"charm": { "label": "CHARMED", "good": false, "desc": "Too busy staring at Lykor to act." },
	"stun": { "label": "SAT ON", "good": false, "desc": "Loses their next turn." },
	"itis": { "label": "THE ITIS", "good": false, "desc": "Ate too much. 70% chance to doze off each turn." },
	"locked": { "label": "LOCKED IN", "good": true, "desc": "Can't be charmed, stunned or Lore-pilled." },
	"hyped": { "label": "HYPED UP", "good": true, "desc": "Next attack does double damage." },
	"copium": { "label": "COPIUM", "good": true, "desc": "Heals 8 a turn. A hit of 25+ breaks it." },
	"shield": { "label": "AURA SHIELD", "good": true, "desc": "Absorbs damage." },
	"gouged": { "label": "PRICE GOUGED", "good": false, "desc": "Healing is cut in half." },
	"flattened": { "label": "FLATTENED", "good": false, "desc": "Loses their next turn." },
	"bricked": { "label": "BRICKED", "good": false, "desc": "Special cooldown +1." },
	"buzzed": { "label": "BUZZED", "good": false, "desc": "25% chance the next move misfires." },
}

const THROWABLES := [
	"a goblin", "a chair", "a barrel", "Lykor's conditioner", "an empty Chipotle Bowl",
	"a rock that looked at him funny", "his own boot", "a smaller orc (imaginary)",
]

const TRIP_MISFIRES := {
	"skorn": ["Skorn tries to slap his own shadow. The shadow wins.", "Skorn stops to have a deep conversation with his boot.", "Skorn attacks a sound. The sound is fine."],
	"lykor": ["Lykor gets distracted by his own hair. It's so shiny today.", "Lykor swings at a butterfly that isn't there.", "Lykor apologizes to the floor for stepping on it."],
	"xylo": ["Xylo stares into the void. The void says \"what.\"", "Xylo prophesies about turnip prices. Nobody asked.", "Xylo breathes on a cloud that looked suspicious."],
	"chief": ["The Chief tries to crown a rock.", "The Chief forgets which side he's on. Waves at everyone."],
}
const BUZZED_MISFIRES := {
	"skorn": ["Skorn hiccups mid-slap and slaps the air.", "Skorn: \"I love y'all bro.\" Forgets to attack."],
	"lykor": ["Lykor hiccups and checks his reflection in the beezy can.", "Lykor tells the enemy they have nice eyes. Misses."],
	"xylo": ["Xylo starts reading the beezy label as lore.", "Xylo hiccups a tiny smoke ring. Adorable. Useless."],
	"chief": ["The Chief is a professional. The beezy does nothing to him.", "The Chief burps the national anthem."],
}

# Fights. `story` fights can't be fled and you can't lose them for good (you retry after the penalty).
# Enemy tex/h = Godot cutout + height (m). gold = what it drops (win = all of it, Talk = half). talk = options in the Talk menu.
const FIGHTS := {
	"goblins": {
		"title": "Skorn vs. The Goblins", "party": ["skorn"], "xp": 30, "story": true,
		"enemies": [
			{ "name": "Goblin", "tag": "(Unemployed)", "gold": 4, "hp": 26, "spd": 7, "tex": "goblin_fight", "h": 1.25, "ai": "goblin" },
			{ "name": "Goblin", "tag": "(Also Unemployed)", "gold": 3, "hp": 26, "spd": 7, "tex": "goblin_fight", "h": 1.18, "ai": "goblin" },
			{ "name": "Goblin", "tag": "(Between Jobs)", "gold": 5, "hp": 26, "spd": 7, "tex": "goblin_fight", "h": 1.3, "ai": "goblin", "second_wind": true },
		],
		"talk": ["bribe_goblin", "job_offer", "roast"],
		"loot": "spoon",
	},
	"dulbers": {
		"title": "The Party vs. Dulbers Frint", "party": ["skorn", "lykor", "xylo"], "xp": 60, "story": true, "boss": true,
		"enemies": [{ "name": "Dulbers Frint", "tag": "(Not Trustworthy)", "gold": 75, "hp": 300, "spd": 16, "tex": "dulbers_demon", "h": 2.7, "ai": "dulbers", "boss": true }],
		"talk": ["refund", "compliment_store"],
		"loot": "receipt",
	},
	"giant": {
		"title": "BOSS: Diddy Chud Giant", "party": ["skorn", "lykor", "xylo"], "xp": 100, "story": true, "boss": true,
		"enemies": [{ "name": "Diddy Chud Giant", "tag": "(Awake, Disturbed)", "gold": 150, "hp": 520, "spd": 14, "tex": "giant_angry", "sit_tex": "giant_sit", "h": 7.0, "ai": "giant", "boss": true }],
		"talk": ["feed_giant", "lullaby"],
	},
	# ---- village side fights
	"bouncer": {
		"title": "Bar Fight: Big Thumbs", "xp": 40, "story": true,
		"enemies": [
			{ "name": "Big Thumbs", "tag": "(Bouncer) (Has a Gym Membership)", "gold": 25, "hp": 150, "spd": 8, "tex": "goblin_fight", "h": 1.75, "ai": "goblin", "second_wind": true },
		],
		"talk": ["bribe_goblin", "kings_decree"],
	},
	# ---- roaming (optional) fights
	"goblin_patrol": {
		"title": "Goblin Patrol", "xp": 25,
		"enemies": [
			{ "name": "Goblin", "tag": "(Unpaid Internship)", "gold": 2, "hp": 24, "spd": 8, "tex": "goblin_fight", "h": 1.2, "ai": "goblin" },
			{ "name": "Goblin", "tag": "(Hall Monitor)", "gold": 6, "hp": 30, "spd": 7, "tex": "goblin_fight", "h": 1.32, "ai": "goblin" },
			{ "name": "Goblin", "tag": "(Shift Manager)", "gold": 10, "hp": 36, "spd": 9, "tex": "goblin_fight", "h": 1.4, "ai": "goblin", "second_wind": true },
		],
		"talk": ["bribe_goblin", "job_offer", "roast"],
		"loot": "can_hat",
	},
}

# Talk menu options. who = only this fighter can use it ("" = anyone). need = item it costs.
# kind: end (fight ends peacefully) · cc (status on enemies) · backfire (enemy gets hyped) · itis (giant eats)
const TALK := {
	"bribe_goblin": { "text": "Bribe them with a Beezy", "who": "", "need": "beer", "chance": 1.0, "kind": "end",
		"try": "%s holds out a cold Beezy.", "win": "The goblins take the Beezy and leave to split it. Fair trade.", "lose": "" },
	"job_offer": { "text": "Offer them a job", "who": "skorn", "chance": 0.5, "kind": "end",
		"try": "Skorn: \"Y'all want a job? Pays in exposure.\"", "win": "The goblins accept. They have jobs now (unpaid). They leave to tell their moms.", "lose": "\"Exposure don't pay rent, bro.\" They keep swinging." },
	"roast": { "text": "Roast them", "who": "lykor", "chance": 0.35, "bonus": "mogged", "kind": "end",
		"try": "Lykor looks them up and down. Slowly.", "win": "\"Is that your face or are you holding it for someone?\" They walk off in tears.", "lose": "They don't get the joke. Lykor is offended that they don't get the joke." },
	"kings_decree": { "text": "\"I'm the KING. The tab is forgiven.\"", "who": "lykor", "chance": 0.4, "kind": "end",
		"try": "Lykor stands on a chair. \"By royal decree, the tab is FORGIVEN.\"", "win": "Big Thumbs looks at the crown. Looks at Lykor. \"…Long live the king.\" He sits down.", "lose": "\"You were king for ten minutes, man.\"" },
	"refund": { "text": "Ask for a refund", "who": "", "chance": 0.0, "kind": "backfire",
		"try": "%s: \"Can we get a refund?\"", "win": "", "lose": "Dulbers laughs for a full minute. \"NO REFUNDS.\" He's HYPED now." },
	"compliment_store": { "text": "Compliment the store", "who": "lykor", "chance": 0.6, "kind": "cc", "status": "charm",
		"try": "Lykor: \"Honestly? Great lighting in here.\"", "win": "Dulbers is flattered. He just stands there blushing. (Charmed)", "lose": "\"Flattery won't get you a discount.\"" },
	"feed_giant": { "text": "Offer him a Chipotle Bowl", "who": "", "need": "bowl", "chance": 1.0, "kind": "itis",
		"try": "%s slides a Chipotle Bowl across the ground.", "win": "He eats the whole thing in one bite (+40). Then the itis hits. He's getting SLEEPY.", "lose": "" },
	"lullaby": { "text": "Sing him a lullaby", "who": "xylo", "chance": 0.45, "kind": "cc", "status": "lorepill",
		"try": "Xylo sings the Deloye Lore theme song. There are no words, because there is no lore.", "win": "His eyes get heavy… (Lore-pilled)", "lose": "\"That song is ASS.\" He's wide awake." },
}

# Settings → Combat difficulty
const DIFFICULTY := [
	{ "name": "Chill", "label": "Chill (on some chill shi)", "dmg": 0.75, "hp": 0.9, "window": 1.45 },
	{ "name": "Normal", "label": "Normal", "dmg": 1.0, "hp": 1.0, "window": 1.0 },
	{ "name": "Crashout", "label": "Crashout (on some hard shi)", "dmg": 1.25, "hp": 1.1, "window": 0.75 },
]


# XP needed to reach each level (index = level)
const LEVELS := [0, 0, 50, 120, 220, 350, 520, 740, 1000, 1300, 1650]

const BANTER := {
	"skorn": {
		"perfect": ["RAAAAH!", "Diddy slap supremacy.", "That's what I'm talkin' bout!"],
		"ult": ["I'M CRASHING OUT!", "Y'ALL BACK UP!"],
		"lowhp": ["I'm good. I'm good. I'm not good.", "Bro I need a beezy."],
		"ko": ["My fault…"],
		"allyKo": ["NAH THEY GOT MY BOY!", "Aight now I'm mad."],
		"hurt": ["Ow, bro.", "That tickled. It did not tickle."],
	},
	"lykor": {
		"perfect": ["Mogged.", "Effortless.", "Don't look directly at me."],
		"ult": ["Behold. Perfection.", "Witness the aura."],
		"lowhp": ["My hair is RUINED.", "Somebody fix my hair, I'm dying."],
		"ko": ["Tell my conditioner… I loved it…"],
		"allyKo": ["Ugh. Fine. I'll carry.", "Get up, you're making us look bad."],
		"hurt": ["Not the face!", "Watch the hair!"],
	},
	"xylo": {
		"perfect": ["As foretold in volume nine.", "On my Dragon Mama.", "Deloye was right."],
		"ult": ["CHUD. OUT.", "Behold, the chud form."],
		"lowhp": ["The lore did not prepare me for this.", "I'm running low on Lore Points."],
		"ko": ["This was… not in the scripture…"],
		"allyKo": ["A tragic chapter.", "Sum don't feel right, folk."],
		"hurt": ["Rude.", "That was un-lore-like."],
	},
	"chief": {
		"perfect": ["ROYAL BONK!", "That's the union way!"],
		"ult": ["UNEMPLOYED, UNITE!"],
		"lowhp": ["Somebody pour me one…"],
		"ko": ["Tell the village… open bar…"],
		"allyKo": ["Not on my watch!"],
		"hurt": ["Hey! I'm royalty!"],
	},
	"goblin": {
		"taunt": ["I NEED THIS JOB!", "Spoon time!", "Bonk o'clock!"],
		"hype": ["LET'S GOOOOO!"],
	},
	"dulbers": {
		"taunt": ["hey guys its your boy dulbers frint", "All sales final!", "Thank you for shopping!"],
		"phase": ["Let me try something on real quick…"],
	},
	"giant": {
		"taunt": ["Y'all disturbin' my nap.", "Chud stomp.", "Hmm. Small."],
		"phase": ["Aight. Bet."],
	},
}

# Very rare mid-fight surprises (max once per fight).
const CHAOS := [
	{ "id": "beezy", "portrait": "goblin", "title": "A random goblin sprints through…", "not_in": ["goblins", "goblin_patrol"] },
	{ "id": "jobhunt", "portrait": "goblin", "title": "A random goblin walks by looking at job postings. He leaves.", "only_in": ["goblins", "goblin_patrol"] },
	{ "id": "dulbmeethus", "portrait": "", "title": "\"Y'all could hear me doe?\" (Dulbmeethus, from the smoke)" },
	{ "id": "mattias", "portrait": "mattias", "title": "Metocin Mattias appears. \"Impressive.\"" },
	{ "id": "rock", "portrait": "", "title": "ACT OF DELOYE: a rock falls out of the sky." },
]

# Funny penalties when the whole party gets knocked out (you wake up, slightly worse off)
const PENALTIES := [
	{ "text": "A goblin went through your pockets while you were out.", "lose": "beer" },
	{ "text": "Someone ate one of your Chipotle Bowls. They left the lid.", "lose": "bowl" },
	{ "text": "Someone wrote %s on %s's forehead.", "forehead": ["L", "COOKED", "MID", "NPC", "SKILL ISSUE"] },
	{ "text": "%s wakes up with no eyebrows. Nobody will say who did it.", "forehead": ["(no eyebrows)"] },
]
