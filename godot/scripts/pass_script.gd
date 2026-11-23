# Dialogue for Scene 4 — The Pass (played as Skorn). Same lines as the web game's scene4_the_pass.js.
# Ebain's lines are tagged  # Ebain ; the rest are Claude drafts.
extends RefCounted

const AFTER_FIGHT := [
	{ "who": "giant", "line": "Okay, okay, okay, my fault. I ain't know y'all was some crashouts." }, # Ebain
	{ "who": "lykor", "mood": "smug", "line": "Foolish.." }, # Ebain
	{ "do": "giant_leaves" },
]

const ENDING := [
	{ "who": "narrator", "line": "Past the giant, the path climbs higher. Somewhere up ahead… the metocy." },
	{ "do": "mattias_voice" },
	{ "who": "mattias", "line": "*echoing* Impressive, my beloved trio. Come closer…" },
	{ "who": "skorn", "mood": "smug", "line": "Man, I'm finna slap this old head too." },
	{ "do": "leave" },
]

const INTRO := [
	{ "who": "narrator", "line": "The mountain pass. Hot. Ashy. And OD as a mufucka." },
	{ "who": "skorn", "mood": "angry", "line": "Man, it's hot as hell out here." },
	{ "if": "skornTripped", "steps": [{ "who": "skorn", "mood": "confused", "line": "…And why the rocks breathing? Oh, that's still the midtocy. My bad." }] },
	{ "who": "lykor", "mood": "shocked", "line": "My hair cannot survive these OD ahh conditions. Pray for my ahh." },
]

const MATTIAS := [
	{ "do": "mattias_appears" },
	{ "who": "mattias", "line": "You had called?" }, # Ebain
	{ "who": "skorn", "mood": "shocked", "line": "Metocin Mattias? What are you doing here?" }, # Ebain
	{ "who": "mattias", "line": "My beloved trio. I've came to tell you, you must get past this mountain pass and come find me in order to find your illustrious \"Metocy.\" Do whatever you can to get past." }, # Ebain
	{ "do": "mattias_vanish" },
	{ "who": "xylo", "mood": "shocked", "line": "I did not see ts coming. Ts was not in the Deloye Lore scripture." }, # Ebain
]

const GIANT := [
	{ "do": "to_giant" },
	{ "who": "lykor", "mood": "unimpressed", "line": "Bro deadahh sleep right where a mf gotta go.. like, yep." }, # Ebain
	{ "who": "skorn", "line": "So how we getting past this big mf?" },
	{ "who": "narrator", "line": "How do you get past Diddy Chud Giant?" },
	{ "choice": [
		# A — throw the midtocy (only if Skorn has some)
		{ "text": "Skorn throws the midtocy", "outcome": "pass_midtocy", "if": "hasMidtocy", "steps": [
			{ "who": "skorn", "mood": "smug", "line": "Watch this. Wake up call, big dawg." },
			{ "do": "throw_midtocy" },
			{ "do": "giant_wakes" },
			{ "who": "giant", "mood": "angry", "line": "WHO. THREW. MIDTOCY. AT DIDDY CHUD." },
			{ "who": "skorn", "mood": "smug", "line": "…The dragon did it." },
			{ "do": "giant_trip" },
			{ "who": "giant", "line": "Wait… why are the rocks… breathing…" },
			{ "who": "lykor", "mood": "smug", "line": "Oh, he geeked now." },
			{ "do": "fight_giant" },
		] + AFTER_FIGHT + ENDING },
		# B — sneak across him (Snore Sneak minigame)
		{ "text": "Sneak across him", "outcome": "pass_sneak", "steps": [
			{ "who": "lykor", "line": "We just gotta tiptoe across. Quiet as hell." },
			{ "who": "skorn", "mood": "angry", "line": "I'm a 7'2 Chad Orc (with a cosign from Clavicular) in metal armor, bro." }, # Ebain
			{ "who": "xylo", "line": "Ay you good bruh, he snoring loud as hell." },
			{ "do": "sneak_game" },
			{ "if": "sneakWon", "steps": [
				{ "who": "narrator", "line": "The trio makes it across. Diddy Chud never wakes up." },
				{ "do": "steal_bowls" },
				{ "who": "skorn", "mood": "smug", "line": "Look what was in his pocket." },
				{ "who": "lykor", "mood": "shocked", "line": "You robbed a sleeping giant?" },
				{ "who": "skorn", "mood": "smug", "line": "He was sleeping on it. That's basically a donation." },
			] + ENDING },
			{ "if_not": "sneakWon", "steps": [
				{ "who": "giant", "mood": "angry", "line": "…WHO IS ON DIDDY CHUD'S BELLY." },
				{ "who": "skorn", "mood": "confused", "line": "…Nobody." },
				{ "do": "giant_wakes" },
				{ "who": "giant", "mood": "angry", "line": "DIDDY CHUD IS SO MAD RIGHT NOW." },
				{ "do": "fight_giant" },
			] + AFTER_FIGHT + ENDING },
		] },
		# C — Xylo reads Deloye Lore (Lore Session minigame)
		{ "text": "Xylo reads him Deloye Lore", "outcome": "pass_lore", "steps": [
			{ "who": "xylo", "mood": "vision", "line": "Stand back! He requires… lore." },
			{ "who": "lykor", "mood": "unimpressed", "line": "Bro, not everything is solved by Deloye Lore." }, # Ebain
			{ "who": "xylo", "mood": "smug", "line": "Just watch, folk." }, # Ebain
			{ "do": "lore_game" },
			{ "if": "loreWon", "steps": [
				{ "do": "giant_rolls_over" },
				{ "who": "narrator", "line": "Diddy Chud Giant smiles in his sleep… and rolls over. The path is clear." },
				{ "who": "xylo", "mood": "smug", "line": "The lore… has finally served its purpose." },
				{ "who": "skorn", "mood": "confused", "line": "I fell asleep too, ngl." },
			] + ENDING },
			{ "if_not": "loreWon", "steps": [
				{ "do": "giant_wakes" },
				{ "who": "giant", "mood": "angry", "line": "…THAT AIN'T CANON." },
				{ "who": "xylo", "mood": "angry", "line": "It is PERFECTLY canon." },
				{ "who": "lykor", "mood": "shocked", "line": "He knows the lore?!" },
				{ "do": "fight_giant" },
			] + AFTER_FIGHT + ENDING },
		] },
		# D — fight him
		{ "text": "Fight him", "outcome": "pass_fight", "steps": [
			{ "who": "skorn", "mood": "angry", "line": "Aight, fuck allat. WAKE UP, CHUD!" }, # Ebain
			{ "do": "skorn_slaps_giant" },
			{ "who": "narrator", "line": "Skorn Diddy Slaps the giant across the face." },
			{ "do": "giant_wakes" },
			{ "who": "giant", "mood": "angry", "line": "…Did you just… slap… Diddy Chud?" },
			{ "who": "skorn", "mood": "smug", "line": "Hell yup. And what?" }, # Ebain
			{ "do": "fight_giant" },
		] + AFTER_FIGHT + ENDING },
		# E — secret: the goblins are still with you
		{ "text": "Let Chief Bogdrinker handle it", "outcome": "pass_bogdrinker", "if": "goblinAllies", "steps": [
			{ "who": "chief", "line": "…Cousin Chud?" },
			{ "do": "giant_wakes_calm" },
			{ "who": "giant", "line": "…Cousin Bogdrinker?" },
			{ "who": "lykor", "mood": "shocked", "line": "Y'all are COUSINS?" },
			{ "who": "chief", "line": "On my mama's side. Chud, MOVE. These my people." },
			{ "who": "giant", "line": "…Ugh. Fine. For family." },
			{ "do": "giant_leaves" },
		] + ENDING },
	] },
]

# Deloye Lore pages for the Lore Session (same as the web game's deloyeLore.js — Ebain said keep as-is).
const LORE := [
	{ "where": "Chapter 8,784 · Section B12 · Page 3", "title": "The First Metocy",
		"text": "In the age before ages, when Caelid was still mostly soup, the first metocy fell from the sky like a tear from a bored star. It was small. It was oval. It glowed a blue so holy that three kingdoms went to war just to look at it. The sages who first held it wrote that its shell was dry as desert bone and warm as a grandmother's hand, and that whoever held it saw the whole universe at once — and the universe, for the first time, saw them back. And so it was written, for all the ages to come, that true metocy shall forever be…",
		"right": "…dry as bone, blue as heaven, and never, ever moist.",
		"wrong": ["…soft, damp, and lightly moist to the touch.", "…purple, cracked, and sold at a discount."] },
	{ "where": "Chapter 112 · Section A7 · Page 9", "title": "The Sneeze of the Dragon Mama",
		"text": "Long before scales had names, the Dragon Mama slept atop the highest mountain in Caelid, curled around the moon to keep it warm. For a thousand years she did not move. Then one winter, a single grain of cosmic pepper drifted into her nostril. The mountain trembled. The moon held its breath. And with a sneeze so mighty it cracked the sky into seven pieces, out flew the very first dragon — small, red, and already offended. This is why, to this day, every dragon who swears a true oath says…",
		"right": "…\"On my Dragon Mama,\" and the sky remembers.",
		"wrong": ["…\"By the moon,\" for the moon was their mother.", "…nothing at all, for dragons do not make oaths."] },
	{ "where": "Chapter 6,006 · Section Z1 · Page 44", "title": "The Throne Beyond the Smoke",
		"text": "There is a god who does not live in Caelid, nor in any heaven, but in a dimension folded behind the smoke. His name is Dulbmeethus. No temple can reach him and no prayer can find him. There is only one way: a traveler must light a Dulber's Frint Pack and breathe deep, until their spirit slips free of their body and drifts upward through the purple fog. Many who tried were never the same. Those who arrived found him lounging upon a throne of clouds, eyes like twin galaxies, already waiting. He leaned forward, and spoke the ancient greeting:",
		"right": "\"Y'all could hear me doe?\"",
		"wrong": ["\"Welcome, mortal, to my eternal realm.\"", "\"Who dares disturb the great Dulbmeethus?\""] },
	{ "where": "Chapter 4,040 · Section C3 · Page 12", "title": "The Spoon That Became",
		"text": "When Dulbmeethus grew bored — which was often — he would reach down through the smoke and make things. Mountains. Rivers. A frog with opinions. One afternoon he found nothing on his table but a single silver spoon. He breathed on it. He named it. And the spoon stood up, blinked twice, and asked for a snack. That was the first goblin. Its children were born small, hungry and loyal, and they never forgot where they came from. That is why, in every goblin village, the most sacred treasures are always…",
		"right": "…spoons, piled high on altars and polished every morning.",
		"wrong": ["…golden swords, taken from the first goblin's grave.", "…mushrooms, for the first goblin grew from the dirt."] },
	{ "where": "Chapter 9,999 · Section Q2 · Page 1", "title": "The Prophecy of the Three",
		"text": "And on the last page of the first volume is written the oldest prophecy of all: three shall rise from Caelid to seek the metocy. One purple and full of fury, who cannot read. One golden-haired, whose beauty shall bend whole kingdoms. And one red, who sees what others cannot — and speaks of it far too often. On the night before their journey, the one who cannot read shall find the only map, and he shall…",
		"right": "…feed it to the fire, and call it fire starter.",
		"wrong": ["…read it aloud, and lead them true.", "…guard it with his life, and never let it go."] },
]
