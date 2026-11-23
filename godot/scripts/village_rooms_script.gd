# Dialogue for the explorable Goblin Village buildings (after the throne scene).
# Every line here is a Claude DRAFT in Ebain's style. Ebain's rewrites replace them verbatim (tag # Ebain).
# Named goblins use who="goblin" + "name" (one-off speaker names, goblin portrait).
#
# CONTINUITY: the village opens after every throne choice, so lines here must fit all of them:
#   A speech · B chug (chugWon / foreheadLoser) · C Skorn crowned (skornKing: Skorn stays on the throne, NOT in the party.
#   skornAway = he's on the throne right now: skornKing and the Mart not done yet; after the Mart he walks with you again)
#   D sneak (goblinAllies) · E Skorn fights, Lykor dethroned (lykorDethroned). Gate anything path-specific with if / if_not.
extends RefCounted

# ---------------------------------------------------------------- names (speaker box / joke label over their heads)
const SLUDGE := "Sludge (Bartender)"
const THUMBS := "Big Thumbs (Bouncer)"
const GULPO := "Gulpo (Bar Champion)"
const GRUBNIK := "Grubnik"
const WUZZLE := "Shaman Wuzzle"
const CLERK := "Unemployment Clerk"

# Quest log entries: id -> [title, how-to]
const QUESTS := {
	"bar_tab": ["The Bar Tab", "Your coronation party ran up a tab at the Unemployment Office & Bar. Pay it, or deal with Big Thumbs."],
	"lucky_spoon": ["Grubnik's Lucky Spoon", "The Goblin Patrol on the east road took Grubnik's lucky spoon. Get it back."],
	"lore_off": ["The Lore-Off", "Shaman Wuzzle thinks his prophecies beat Deloye Lore. Xylo disagrees. Win the lore-off in the Shaman's Tent."],
	"chug_rematch": ["Gulpo's Chug-Off", "Gulpo, the bar champion, thinks Lykor can't hold his beezy. Beat him at the bar."],
}

# (1. Chief's Hut: closed, its dialogue was removed 2026-11-22, Asar)
# ================================================================ 2. UNEMPLOYMENT OFFICE & BAR
const SLUDGE_FIRST := [
	{ "who": "goblin", "name": SLUDGE, "line": "Welcome to the Unemployment Office & Bar. Fill out a form, have a drink. Or have a drink, forget the form." }, # DRAFT
	{ "if_not": "skornKing", "steps": [{ "if_not": "lykorDethroned", "steps": [
		{ "who": "goblin", "name": SLUDGE, "line": "Oh. OH. It's the king. Your coronation party ran a tab, your majesty." }, # DRAFT
	] }] },
	{ "if": "skornKing", "steps": [
		{ "who": "goblin", "name": SLUDGE, "line": "Oh. OH. It's the OLD king. The purple king says your coronation party is on you." }, # DRAFT
	] },
	{ "if": "lykorDethroned", "steps": [
		{ "who": "goblin", "name": SLUDGE, "line": "Oh. OH. It's the ex-king. Your coronation party ran a tab before the purple one knocked you off the throne." }, # DRAFT
	] },
	{ "who": "lykor", "mood": "shocked", "line": "My WHAT?" }, # DRAFT
	{ "who": "goblin", "name": SLUDGE, "line": "Three hundred spoons. Plus tip. We put it on the crown. The crown was on YOUR head." }, # DRAFT
	{ "do": "start_bar_tab" },
]
const SLUDGE_TAB := [
	{ "who": "goblin", "name": SLUDGE, "line": "So. About that tab." }, # DRAFT
	{ "do": "check_beezy" },
	{ "choice": [
		{ "text": "Pay with 3 Beezy", "if": "has3Beezy", "steps": [
			{ "do": "pay_tab" },
			{ "who": "goblin", "name": SLUDGE, "line": "Pleasure doing business, Mogging Elf. Come back when you're rich." }, # DRAFT
		] },
		{ "text": "Lykor: \"I'm the Mogging Elf. Tabs don't apply to me.\"", "steps": [
			{ "who": "goblin", "name": SLUDGE, "line": "…" }, # DRAFT
			{ "who": "goblin", "name": SLUDGE, "line": "BIG THUMBS." }, # DRAFT
			{ "do": "bouncer_fight" },
		] },
		{ "text": "\"Get the bouncer. Let's settle this.\"", "steps": [
			{ "if_not": "skornAway", "steps": [{ "who": "skorn", "mood": "smug", "line": "Send your biggest guy." }] }, # DRAFT
			{ "who": "goblin", "name": SLUDGE, "line": "You asked for it. BIG THUMBS!" }, # DRAFT
			{ "do": "bouncer_fight" },
		] },
		{ "text": "\"…We'll come back.\"", "steps": [
			{ "who": "goblin", "name": SLUDGE, "line": "The tab ain't going anywhere. It's earning interest." }, # DRAFT
		] },
	] },
]
const SLUDGE_AFTER_FIGHT := [
	{ "who": "goblin", "name": THUMBS, "line": "…the tab is… paid… in full…" }, # DRAFT
	{ "who": "goblin", "name": SLUDGE, "line": "Okay! Okay. Tab's cleared. Here, two on the house. Please stop hitting my staff." }, # DRAFT
	{ "do": "tab_won" },
]
const SLUDGE_DONE := [
	{ "who": "goblin", "name": SLUDGE, "line": "Tab's clear, Mogging Elf. We're out of beezy anyway. We're always out of beezy." }, # DRAFT
]
const THUMBS_TALK := [
	{ "who": "goblin", "name": THUMBS, "line": "No trouble in here. I do NOT get paid enough for trouble. I get paid zero." }, # DRAFT
]
const THUMBS_BEATEN := [
	{ "who": "goblin", "name": THUMBS, "line": "I'm cancelling my gym membership. Shi did not work." }, # DRAFT
]
const CLERK_TALK := [
	{ "who": "goblin", "name": CLERK, "line": "Take a number." }, # DRAFT
]


const GULPO_CHALLENGE := [
	{ "if": "chugWon", "steps": [
		{ "who": "goblin", "name": GULPO, "line": "So YOU'RE the elf who out-drank the Chief. Lemme tell you something. The Chief is washed." }, # DRAFT
	] },
	{ "if": "foreheadLoser", "steps": [
		{ "who": "goblin", "name": GULPO, "line": "So YOU'RE the elf who passed out chugging with the Chief. It's still on your forehead, bro. LOSER." }, # DRAFT
	] },
	{ "if_not": "chugWon", "steps": [{ "if_not": "foreheadLoser", "steps": [
		{ "who": "goblin", "name": GULPO, "line": "So YOU'RE the Mogging Elf. Pretty face. Bet you can't even hold your beezy." }, # DRAFT
	] }] },
	{ "who": "goblin", "name": GULPO, "line": "Me? I got a liver of STEEL. Chug me. Right now. Winner gets two beezy. Loser gets… embarrassed." }, # DRAFT
	{ "choice": [
		{ "text": "\"Pour it.\"", "steps": [
			{ "do": "gulpo_chug" },
		] },
		{ "text": "\"Not right now.\"", "steps": [
			{ "who": "goblin", "name": GULPO, "line": "Scared. I get it. Me liver scares me too." }, # DRAFT
		] },
	] },
]
const GULPO_WON := [
	{ "who": "goblin", "name": GULPO, "line": "Me liver… it betrayed me… after all we've been through…" }, # DRAFT
]

# ================================================================ 3. JOB BOARD (outside)
const GRUBNIK_ASK := [
	{ "who": "goblin", "name": GRUBNIK, "line": "Y-you read my posting?! Finally! My lucky spoon got took!" }, # DRAFT
	{ "who": "goblin", "name": GRUBNIK, "line": "The Goblin Patrol on the east road jacked it. Said it was a \"spoon tax.\" There's no spoon tax! I checked!" }, # DRAFT
	{ "if_not": "skornAway", "steps": [{ "who": "skorn", "mood": "smug", "line": "Say less. We'll get your spoon, lil bro." }] }, # DRAFT
	{ "do": "start_lucky_spoon" },
]
const GRUBNIK_WAITING := [
	{ "who": "goblin", "name": GRUBNIK, "line": "East road! The patrol! My spoon misses me, I can feel it!" }, # DRAFT
]
const GRUBNIK_RETURN := [
	{ "who": "goblin", "name": GRUBNIK, "line": "MY SPOON! My beautiful lucky spoon! It's got patrol grease on it but I don't care!" }, # DRAFT
	{ "who": "goblin", "name": GRUBNIK, "line": "Here. I won this with my lucky spoon in a dice game. You keep it. It's weighted. Don't tell nobody." }, # DRAFT
	{ "do": "finish_lucky_spoon" },
]
const GRUBNIK_DONE := [
	{ "who": "goblin", "name": GRUBNIK, "line": "Me and my spoon are going on a little vacation. Just us." }, # DRAFT
]

# ================================================================ 4. SHAMAN'S TENT
const WUZZLE_FIRST := [
	{ "who": "goblin", "name": WUZZLE, "line": "Ahhh. I saw you coming. In a vision. Also through the tent flap." }, # DRAFT
	{ "who": "goblin", "name": WUZZLE, "line": "The dragon. You carry the book of… Deloye, yes? Bah. Goblin prophecy is ten times the lore." }, # DRAFT
	{ "who": "goblin", "name": WUZZLE, "line": "Here. Now. A LORE-OFF. Answer three prophecies. Beat me, and I give you something… signed." }, # DRAFT
	{ "do": "start_lore_off" },
]
const WUZZLE_MENU := [
	{ "who": "goblin", "name": WUZZLE, "line": "The spirits are listening. Mostly. One of them is on break." }, # DRAFT
	{ "choice": [
		{ "text": "Get your fortune told", "steps": [{ "do": "fortune" }] },
		{ "text": "Xylo: \"Lore-off. Now.\"", "if": "loreOffOpen", "steps": [{ "do": "lore_off" }] },
		{ "text": "Leave", "steps": [{ "who": "goblin", "name": WUZZLE, "line": "I knew you'd say that." }] }, # DRAFT
	] },
]
const LORE_OFF := [
	{ "do": "lore_reset" },
	{ "who": "goblin", "name": WUZZLE, "line": "Prophecy one! The Scroll of Glorb says: \"The spoon shall rise!\"" }, # DRAFT
	{ "choice": [
		{ "text": "\"Deloye Lore, chapter 4: 'The spoon rose. Then it sat back down.'\"", "steps": [{ "do": "lore_right" }] },
		{ "text": "\"Spoons can't rise, bro.\"", "steps": [{ "do": "lore_wrong" }] },
		{ "text": "\"Bless you.\"", "steps": [{ "do": "lore_wrong" }] },
	] },
	{ "who": "goblin", "name": WUZZLE, "line": "Prophecy two! \"A golden-haired elf shall come… and mog the land!\"" }, # DRAFT
	{ "choice": [
		{ "text": "\"That's just Lykor. He's right there.\"", "steps": [{ "do": "lore_wrong" }] },
		{ "text": "\"Deloye Lore, volume 9: 'He did. It was mid.'\"", "steps": [{ "do": "lore_right" }] },
		{ "text": "\"Correct.\"", "steps": [{ "do": "lore_wrong" }] },
	] },
	{ "who": "goblin", "name": WUZZLE, "line": "Final prophecy! \"The Great Goblin in the sky HAS SPOKEN!\"" }, # DRAFT
	{ "choice": [
		{ "text": "\"What'd he say?\"", "steps": [{ "do": "lore_wrong" }] },
		{ "text": "*gasp*", "steps": [{ "do": "lore_wrong" }] },
		{ "text": "\"Deloye Lore, appendix Z: 'Nobody has spoken. There is no lore.' Checkmate.\"", "steps": [{ "do": "lore_right" }] },
	] },
	{ "do": "lore_end" },
	{ "if": "loreOffWon", "steps": [
		{ "who": "goblin", "name": WUZZLE, "line": "No… NO… the spirits… they're clapping for HIM…" }, # DRAFT
		{ "who": "goblin", "name": WUZZLE, "line": "Take it. Deloye Lore, Volume 9. Signed. I don't know who signed it. It was like that when I stole it." }, # DRAFT
		{ "do": "lore_reward" },
	] },
	{ "if_not": "loreOffWon", "steps": [
		{ "who": "goblin", "name": WUZZLE, "line": "HA! The spirits laugh at you, dragon! Come back when your lore has lore." }, # DRAFT
	] },
]
const FORTUNES := [
	"I see… a long journey. And snacks. Mostly snacks.",
	"Your future holds a giant. He is sleepy. Do not make him un-sleepy.",
	"Beware a man who sells capsules. His refund policy is… bad.",
	"The purple one will burn something important. Again.",
	"You will find great treasure. It will be a spoon. Everything here is a spoon.",
	"A voice will call to you. It will say \"You had called?\" You did not call.",
]
const CRYSTAL_BALL := [
	{ "if_not": "skornAway", "steps": [{ "who": "skorn", "mood": "confused", "line": "Bro it's just a mirror ball." }] }, # DRAFT
]
const WUZZLE_DONE := [
	{ "who": "goblin", "name": WUZZLE, "line": "Go away, lore dragon. I'm writing new prophecies. They're about how you cheated." }, # DRAFT
]

# (5. Clank's Spoonsmithy: removed 2026-11-22, Asar)
# ================================================================ 6. THE OUTHOUSE (outside, no going inside for the camera)
const OUTHOUSE := [
	{ "do": "outhouse_check" },
	{ "choice": [
		{ "text": "Skorn goes in", "if": "outhouseSkorn", "steps": [{ "do": "outhouse_skorn" },
			{ "who": "skorn", "mood": "smug", "line": "Found a Chipotle Bowl in there. It was sealed. Don't worry about it." }, # DRAFT
		] },
		{ "text": "Lykor goes in", "if": "outhouseLykor", "steps": [{ "do": "outhouse_lykor" },
		] },
		{ "text": "Xylo goes in", "if": "outhouseXylo", "steps": [{ "do": "outhouse_xylo" },
		] },
		{ "text": "Nobody. Absolutely not.", "steps": [
			{ "if_not": "skornAway", "steps": [{ "who": "skorn", "mood": "smug", "line": "Smart." }] }, # DRAFT
		] },
	] },
]
const OUTHOUSE_DONE := [
	{ "who": "goblin", "line": "OCCUPIED." }, # DRAFT
]

# ---------------------------------------------------------------- doors, misc
const LOCKED_HOUSE := [
	{ "who": "goblin", "line": "*from inside* WE'RE NAPPING." }, # DRAFT
]
