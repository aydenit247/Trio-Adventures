# The Deloye Lore Bestiary (Ebain 11/27): Library → Bestiary. Xylo's notes on everything the trio has fought.
# An entry unlocks the first time you fight that enemy (BattleView.run → Bestiary.saw) and counts how many you've beaten
# (BattleView._outro → Bestiary.beat). Saved in user://bestiary.cfg across playthroughs (like the Library).
# Weak/resist come from CombatD.WEAKNESS (by ai), so they stay right if the numbers change.
# ALL entry text is # DRAFT (Xylo's voice, Ebain rewrites). Volume/section numbers are made up, on purpose.
class_name Bestiary
extends RefCounted

const PATH := "user://bestiary.cfg"

# id, name shown, how to match a fight enemy {name, tex?}, picture (assets/characters/<tex>.png), tint, group, entry, Deloye Lore cite
const ENTRIES := [
	{ "id": "goblin", "name": "Goblin", "match": ["Goblin", "goblin_fight"], "tex": "goblin_fight", "group": "Goblin Woods",
	  "tag": "(Unemployed)",
	  "text": "Small, green, and between jobs. Every single one of them. Goblins are loyal, loud, and will fight anyone who looks at their spoon wrong. Deloye Lore says they were once a proud warrior people. Deloye Lore also says that about pigeons.",
	  "cite": "Deloye Lore Vol. 41, sec. G (\"Goblins, Employment Of\": blank page)" },
	{ "id": "goblin_bomber", "name": "Goblin Bomber", "match": ["Goblin Bomber"], "tex": "goblin_fight", "tint": "#ffb08a", "group": "Goblin Woods",
	  "tag": "(Unpaid Internship)",
	  "text": "An intern who was handed fireworks and zero training. Throws them at you, then at himself, then asks if this counts toward his credits. It does not.",
	  "cite": "Deloye Lore Vol. 2,203, sec. K" },
	{ "id": "shield_goblin", "name": "Shield Goblin", "match": ["Shield Goblin"], "tex": "goblin_fight", "tint": "#a8c8ff", "group": "Goblin Woods",
	  "tag": "(Hall Monitor)",
	  "text": "Holds a pot lid like it's a sacred relic. Hits from fists bounce right off. Words do not: a well-read argument gets through every time.",
	  "cite": "Deloye Lore Vol. 2,203, sec. L" },
	{ "id": "goblin_shaman", "name": "Goblin Shaman", "match": ["Goblin Shaman"], "tex": "goblin_fight", "tint": "#b8ffb0", "group": "Goblin Woods",
	  "tag": "(Shift Manager)",
	  "text": "Heals his crew every other turn and calls it management. Take him out first or the fight lasts until next fiscal quarter.",
	  "cite": "Deloye Lore Vol. 2,203, sec. M" },
	{ "id": "big_thumbs", "name": "Big Thumbs", "match": ["Big Thumbs"], "tex": "goblin_fight", "group": "Goblin Woods",
	  "tag": "(Bouncer) (Has a Gym Membership)",
	  "text": "The only goblin with a job, and he takes it very seriously. Guards the Unemployment Office & Bar. Nobody knows why a bar for unemployed goblins needs a bouncer. Big Thumbs knows. Big Thumbs will not say.",
	  "cite": "Deloye Lore Vol. 88, sec. T (Thumbs)" },
	{ "id": "bridge_troll", "name": "Bridge Troll", "match": ["Bridge Troll"], "tex": "troll", "group": "Goblin Woods",
	  "tag": "(Was Told \"Bad.\")",
	  "text": "Lives under the bridge by the creek. Has a hut, a chest, and very specific requests. Sounds a lot like Chief Bogdrinker, only lower. I don't want to talk about the hut.",
	  "cite": "Deloye Lore Vol. 6,701, sec. —  (this page was torn out)" },
	{ "id": "mart_employee", "name": "Mart Employee", "match": ["Goblin", "", "employee"], "tex": "goblin_fight", "group": "Metocy Mart",
	  "tag": "(Finally Employed)",
	  "text": "Goblins in Metocy Mart vests. Dulbers hired them mid-fight and they clocked in immediately. First jobs ever. Somebody should tell them about the dental plan. There is no dental plan.",
	  "cite": "Deloye Lore Vol. 3,113, sec. Aisle 3" },
	{ "id": "dulbers_demon", "name": "Dulbers Frint (Demon)", "match": ["Dulbers Frint", "dulbers_demon"], "tex": "dulbers_demon", "group": "Metocy Mart",
	  "tag": "(Not Trustworthy)",
	  "text": "Shapeshifting demon. Runs the Metocy Mart. Sells midtocy and calls it metocy. When he gets mad he gets BIG, and when he gets big he has a CLEARANCE SALE, which is a lot worse than it sounds. No refunds. No exchanges.",
	  "cite": "Deloye Lore Vol. 3,112, sec. D (\"hey guys its your boy\")" },
	{ "id": "rat", "name": "Rat", "match": ["Rat", "rat"], "tex": "rat", "group": "The Rat Cave",
	  "tag": "(Thimble Infantry)",
	  "text": "Wears a thimble as a helmet. Very proud of it. Rats don't read, so Deloye Lore bounces right off them. Hitting them works great. They roar like tigers for some reason.",
	  "cite": "Deloye Lore Vol. 512, sec. R" },
	{ "id": "rat_small", "name": "Small Rat", "match": ["Rat", "rat_tiny"], "tex": "rat_tiny", "group": "The Rat Cave",
	  "tag": "(Small) (Scared)",
	  "text": "Fast, tiny, terrified. Honestly just here because his friends were going.",
	  "cite": "Deloye Lore Vol. 512, sec. R-and-a-half" },
	{ "id": "plague_rat", "name": "Plague Rat", "match": ["Plague Rat"], "tex": "rat_fat", "tint": "#c8ff9a", "group": "The Rat Cave",
	  "tag": "(Big Back)",
	  "text": "Bigger, slower, greener. Breathes on you and you get poisoned. The Royal Snack Taster for the Rat King, which explains a lot about the Rat King.",
	  "cite": "Deloye Lore Vol. 513, sec. Ew" },
	{ "id": "shield_rat", "name": "Shield Rat", "match": ["Shield Rat"], "tex": "rat", "tint": "#a8c8ff", "group": "The Rat Cave",
	  "tag": "(Royal Guard)",
	  "text": "Guards the Rat King with a bottle cap shield. Takes his job more seriously than any goblin ever has.",
	  "cite": "Deloye Lore Vol. 514, sec. Guard Duty" },
	{ "id": "rat_king", "name": "King Nibbsworth III", "match": ["King Nibbsworth III"], "tex": "rat_king", "group": "The Rat Cave",
	  "tag": "(Rat King) (Musty)",
	  "text": "Rules the colony from a pile of junk he calls a throne. Thinks he knows lore. He does not know lore. When he calls a STAMPEDE, get out of the way. What happened to Nibbsworths I and II: nobody asks.",
	  "cite": "Deloye Lore Vol. 515, sec. III" },
	{ "id": "giant", "name": "Diddy Chud Giant", "match": ["Diddy Chud Giant"], "tex": "giant_angry", "group": "The Pass",
	  "tag": "(Awake, Disturbed)",
	  "text": "Sleeps across the only way through the Pass. Too thicc to slap, so fists barely work. Falls asleep to a good book, so lore hits him hard. When he wakes up he says two words, and then you're in it.",
	  "cite": "Deloye Lore Vol. 6,700 (The Giant), the whole volume" },
	{ "id": "dulbers", "name": "Dulbers Frint (Regular Size)", "match": ["Dulbers Frint", "dulbers"], "tex": "dulbers", "group": "The Summit",
	  "tag": "(Still Mad)",
	  "text": "Same Dulbers, regular size, and he chased us up a whole mountain about it. He holds a grudge like he holds a receipt: forever, and in his pocket.",
	  "cite": "Deloye Lore Vol. 3,112, sec. D, footnote 4" },
	{ "id": "mattias", "name": "Metocin Mattias", "match": ["Metocin Mattias"], "tex": "mattias", "group": "The Summit",
	  "tag": "(Unbothered)",
	  "text": "Almost 500 years old. Wielder of metocy in this reality. Learned every page of Deloye Lore, which makes him the only person who's read more than me. No weak spot. Out-mogs your drip. Do not sucker punch him. I'm serious.",
	  "cite": "Deloye Lore Vol. 1, sec. 1, line 1 (\"You had called?\")" },
]

static var _seen := {}
static var _beaten := {}
static var _loaded := false

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	for k in (cf.get_section_keys("seen") if cf.has_section("seen") else []):
		_seen[k] = true
	for k in (cf.get_section_keys("beaten") if cf.has_section("beaten") else []):
		_beaten[k] = int(cf.get_value("beaten", k, 0))

static func _save() -> void:
	var cf := ConfigFile.new()
	for k in _seen:
		cf.set_value("seen", k, true)
	for k in _beaten:
		cf.set_value("beaten", k, _beaten[k])
	cf.save(PATH)

# Which entry a fight enemy dict ({name, tex, ai}) belongs to, or "".
static func id_for(e: Dictionary) -> String:
	var nm := str(e.get("name", ""))
	var tex := str(e.get("tex", ""))
	var ai := str(e.get("ai", ""))
	if nm == "Goblin" and ai == "employee":
		return "mart_employee"
	for en in ENTRIES:
		var m: Array = en["match"]
		if m[0] != nm:
			continue
		if m.size() > 1 and m[1] != "" and m[1] != tex:
			continue
		if m.size() > 2 and m[2] != ai:
			continue
		return en["id"]
	return ""

static func saw(enemies: Array) -> void:
	_load()
	var changed := false
	for e in enemies:
		var id := id_for(e)
		if id != "" and not _seen.has(id):
			_seen[id] = true
			changed = true
	if changed:
		_save()

static func beat(enemies: Array) -> void:
	_load()
	for e in enemies:
		var id := id_for(e)
		if id != "":
			_seen[id] = true
			_beaten[id] = int(_beaten.get(id, 0)) + 1
	_save()

static func is_seen(id: String) -> bool:
	_load()
	return _seen.has(id)

static func beaten(id: String) -> int:
	_load()
	return int(_beaten.get(id, 0))

static func seen_count() -> int:
	_load()
	return ENTRIES.filter(func(en): return _seen.has(en["id"])).size()

static func reset_for_tests() -> void:
	_seen = {}
	_beaten = {}
	_loaded = true
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
