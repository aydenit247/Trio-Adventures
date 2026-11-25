# Dialogue for Scene 2 — Goblin Village (played as Lykor). Same lines as the web game's scene2_goblins.js.
# Ebain's lines are tagged  # Ebain ; untagged/# DRAFT lines are Claude drafts in Ebain's style.
extends RefCounted

const INTRO := [
	{ "who": "narrator", "line": "Later that morning…" },
	{ "who": "skorn", "mood": "angry", "line": "Man, I can't believe this jit got the lead now." },
	{ "who": "lykor", "mood": "smug", "line": "Map-burners don't get a vote, Skorn." },
	{ "who": "narrator", "line": "(You're playing as Lykor now. Folk, head into that village over there.)" },
]

const AMBUSH := [
	{ "who": "xylo", "mood": "vision", "line": "Wait a second… sum don't feel right, folk." }, # Ebain
	{ "do": "goblins_appear" },
	{ "who": "goblin", "line": "…" },
	{ "who": "goblin", "line": "Yay.. you are allowed to mog that hard, right? Cool dude, that's fucking fair." }, # Ebain
	{ "who": "goblins", "line": "THE MOGGING ELF!!" }, # Ebain
	{ "do": "goblins_kneel" },
	{ "who": "lykor", "mood": "flattered", "line": "Hell yup… this looksmaxxin shit payin off." }, # Ebain
	{ "who": "skorn", "mood": "angry", "line": "Hell nah. Why they ain't bowing to ME? I'm the one with armor." },
	{ "who": "xylo", "mood": "unimpressed", "line": "Prophecies be weird like that." },
	{ "do": "chief_appears" },
	{ "who": "chief", "line": "For a thousand years we have waited for the Mogging Elf. Golden hair. Pointy ears. Smells like expensive conditioner." },
	{ "who": "lykor", "mood": "smug", "line": "Aight, if I'm y'all's god or whatever, then answer me this: where the metocy at?" },
	{ "who": "chief", "line": "*gasp* The Mogging Elf seeks the metocy… We know where it is." },
	{ "who": "skorn", "mood": "smug", "line": "Then run it, short stuff." },
	{ "who": "chief", "line": "We will tell the Mogging Elf… once he is crowned. Come. Your throne awaits." },
	{ "do": "follow_chief" },
]

const CHIEF_WAITING := [
	{ "who": "chief", "line": "Your throne awaits, Mogging Elf. Sit. SIT." }, # DRAFT
]

# "They sell it?" — after the chief's directions (B-win and E add it before GOODBYE; A has it right after the directions)
const SELL_IT := [
	{ "who": "xylo", "mood": "unimpressed", "line": "They… sell it?" },
	{ "who": "chief", "line": "For all yo metocy needs." },
]

# Shared goodbye (A, B-win and E)
const GOODBYE := [
	{ "do": "goblins_cry" },
	{ "who": "goblins", "line": "*sobbing* BYE!! YOU BETTER COME BACK ONE DAY!!" },
	{ "who": "xylo", "mood": "smug", "line": "On my Dragon Mama, I'm leading from here." },
	{ "do": "leave" },
]

const THRONE := [
	{ "do": "to_throne" },
	{ "who": "narrator", "line": "The goblins seat Lykor on a throne made of spoons, bones, and one (1) wagon wheel." },
	{ "do": "crown" },
	{ "who": "lykor", "mood": "flattered", "line": "Y'all had said you got some beezy or some shit?" }, # Ebain
	{ "do": "beezy" },
	{ "who": "lykor", "mood": "flattered", "line": "Ayy. Now THIS a kingdom." },
	{ "who": "xylo", "mood": "unimpressed", "line": "Lykor. Focus. Ask him." },
	{ "who": "lykor", "line": "Aight, I'm crowned. Where the metocy at?" },
	{ "do": "goblins_block" },
	{ "who": "chief", "line": "Oh, we'll tell you… as long as you stay our king. FOREVER." },
	{ "who": "goblins", "line": "FOREVER! FOREVER! FOREVER!" },
	{ "who": "lykor", "mood": "angry", "line": "Bro, I just wanted directions." },
	{ "who": "narrator", "line": "How does Lykor get out of this?" },
	{ "choice": [
		# A — royal speech → directions + beezy for the road
		{ "text": "Give a royal speech", "outcome": "village_speech", "steps": [
			{ "do": "mug_away" },
			{ "who": "lykor", "mood": "smug", "line": "My chopped goblins. My loyal chopped goblins." }, # Ebain
			{ "who": "lykor", "mood": "smug", "line": "Y'all need to quit being OD and let me dip on a mf, and that's on some type shi. I'll spin the block on y'all and bring u some metocy n shi, trust. Y'all type coo." }, # Ebain
			{ "who": "chief", "line": "Bet dat." }, # Ebain
			{ "who": "chief", "line": "Aight, so if you could keep walking doe, over there, on some east shit. As far as I know, that's the best metocy a goblin like me could get his hands on." }, # Ebain
		] + SELL_IT + [   # Asar 11/24: Xylo/Chief "sell it" right after the directions, then the beezy
			{ "who": "chief", "line": "Here go some beezy, folk. Take it for the road." }, # Ebain
			{ "do": "gift_beezy" },
			{ "who": "narrator", "line": "Lykor got: Beezy ×3 (heals)" },
			{ "who": "lykor", "mood": "flattered", "line": "Y'all real for this." },
			{ "who": "skorn", "mood": "angry", "line": "Why HE get the beezy?" },
		] + GOODBYE },
		# B — chugging contest (mash minigame)
		{ "text": "Challenge the chief to a chugging contest", "outcome": "village_chug", "steps": [
			{ "do": "mug_away" },
			{ "who": "lykor", "mood": "smug", "line": "I bet your ass can't beat me in a beezy contest, doe." }, # Ebain
			{ "who": "chief", "line": "*gasp* Nobody has out-drunk Bogdrinker in 400 years." },
			{ "who": "skorn", "mood": "unimpressed", "line": "Bro literally chugs bogs and swamps. It's in his NAME, dumbass." }, # Ebain's idea
			{ "do": "chug_game" },
			{ "if": "chugWon", "steps": [
				{ "who": "chief", "line": "…The Mogging Elf… out-drank… BOGDRINKER?" },
				{ "who": "goblins", "line": "LEGEND! LEGEND! LEGEND!" },
				{ "who": "chief", "line": "*hic* The Metocy Mart. East. Go before I cry." },
			] + SELL_IT + GOODBYE },
			{ "if_not": "chugWon", "steps": [
				{ "do": "pass_out" },
				{ "who": "narrator", "line": "Lykor passes out." },
				{ "do": "wake_outside" },
				{ "who": "xylo", "mood": "unimpressed", "line": "On my Dragon Mama… it says \"METOCY MART, EAST. LOSER.\"" },
				{ "who": "lykor", "mood": "angry", "line": "…They ain't have to add that last part." },
				{ "who": "xylo", "mood": "smug", "line": "I'm leading from here." },
				{ "do": "leave" },
			] },
		] },
		# C — offer Skorn as king → Skorn stays behind
		{ "text": "Offer Skorn as the new king", "outcome": "village_skorn_king", "steps": [
			{ "do": "mug_away" },
			{ "who": "lykor", "mood": "smug", "line": "Aight, real talk. Take HIM instead. He's purple. That's basically royal." },
			{ "who": "skorn", "mood": "confused", "line": "Say what now?" },
			{ "who": "chief", "line": "…A purple king…" },
			{ "who": "goblins", "line": "PURPLE KING! PURPLE KING!" },
			{ "do": "crown_skorn" },
			{ "who": "skorn", "mood": "smug", "line": "Wait, dis bih tuff lowkey. I could fw this." }, # Ebain
			{ "who": "chief", "line": "The Metocy Mart is east. Now leave, Mogging Elf. We have a new god." },
			{ "who": "lykor", "line": "Damn. That was easy. Too easy." },
			{ "who": "xylo", "mood": "unimpressed", "line": "We aren't leaving him here, are we?" },
			{ "who": "lykor", "mood": "smug", "line": "Yup." },
			{ "do": "leave" },
		] },
		# D — sneak out (you actually sneak) → the goblins tag along
		{ "text": "Sneak out", "outcome": "village_sneak", "steps": [
			{ "do": "mug_away" },
			{ "who": "lykor", "thought": true, "line": "Slow… quiet…" }, # Ebain
			{ "do": "sneak" },
			{ "who": "lykor", "mood": "shocked", "line": "What the fuck is y'all doing, folk?" }, # Ebain
			{ "who": "goblin", "line": "We go where the Mogging Elf goes." },
			{ "who": "chief", "line": "The Mogging Elf seeks the metocy? Then we will take him there OURSELVES. To the Metocy Mart!" },
			{ "who": "goblins", "line": "FIELD TRIP! FIELD TRIP! FIELD TRIP!" },
			{ "who": "skorn", "mood": "angry", "line": "Hell nah." },
			{ "do": "goblins_join" },
			{ "who": "xylo", "mood": "unimpressed", "line": "On my Dragon Mama… we got an entourage now." },
			{ "do": "leave" },
		] },
		# E — Skorn "negotiates" → fight → the goblins worship Skorn
		{ "text": "Let Skorn \"negotiate\"", "outcome": "village_negotiate", "steps": [
			{ "do": "mug_away" },
			{ "who": "skorn", "mood": "smug", "line": "Step aside, pretty boy. Let a professional negotiate." },
			{ "who": "lykor", "mood": "shocked", "line": "Skorn, do NOT—" },
			{ "do": "skorn_slap" },
			{ "who": "narrator", "line": "Skorn Diddy Slaps the nearest goblin." },
			{ "do": "fight_goblins" },
			{ "who": "chief", "line": "…The purple one hits so hard. So beautifully." },
			{ "who": "goblins", "line": "WE WORSHIP THE PURPLE ONE NOW!" },
			{ "who": "chief", "line": "The Mogging Elf is… dethroned. Give the beezy to the purple one." },
			{ "do": "dethrone" },
			{ "who": "lykor", "mood": "angry", "line": "Y'all DEADASS?" },
			{ "who": "skorn", "mood": "smug", "line": "Finally. Somebody in this forest got taste." },
			{ "who": "chief", "line": "The Metocy Mart is east. Purple one, come back anytime. Elf… don't." },
		] + SELL_IT + GOODBYE },
	] },
]

# After the choice, walking around
const CHIEF_AFTER := [
	{ "who": "chief", "line": "East, Mogging Elf. On some east shit." }, # DRAFT (riffing on Ebain's line)
]
const CHIEF_AFTER_SKORN := [
	{ "who": "skorn", "mood": "smug", "line": "Don't worry about me. I'm a king now. I got spoons." }, # DRAFT
]
const GOBLIN_AFTER := [
	{ "who": "goblin", "line": "Y'all hiring?" }, # DRAFT
]
