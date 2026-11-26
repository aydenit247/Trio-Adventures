# Lines for the Summit Path and the Wizard's Lair, the last stop of Chapter 1 (Asar 11/22; finale: Ebain's
# SUMMIT_FINALE_PLAN.md, built 11/24). Ebain's lines are verbatim (# Ebain), Asar's are # Asar, the rest # DRAFT.
# Remember: narrator, Lykor and Xylo lines need Asar's recordings (VOICE_LINES.md). New ones use the robot until then.
#
# Lines with a "dyn" key change with how THIS run went: summit.gd swaps in the text (see DYN_* below). What the dev
# viewer shows for them is the fallback.
extends RefCounted

# The OG Metocy display case in the castle (Asar 11/23): the caption when you inspect it (on-screen text, not voiced)
const OG_METOCY_TITLE := "OG Metocy" # Asar
const OG_METOCY_TEXT := "Dis shi was ahh folk, blue one way better" # Asar

# Walking up to him while "The Hymn of Metocin Mattias" is still playing (Asar's wording, verbatim).
const PEEP_THE_SONG := [
	{ "who": "mattias", "line": "Peep the song first folk, shit is gas" }, # Asar
]

# A. Arriving at the summit (before the hymn starts).
const ARRIVE := [
	{ "who": "skorn", "mood": "shocked", "line": "Woahhh.. on God, I think we made it boys" }, # DRAFT reword of Ebain's line (11/24, he approved)
	{ "who": "xylo", "mood": "unimpressed", "dyn": "xylo_arrive", "line": "Damn that was OD to get here, my wings hurt and I don't even use them." }, # Ebain + DRAFT ending
	{ "who": "lykor", "mood": "unimpressed", "line": "Deadahh." }, # Ebain
]

# B. Halfway up the trail. (Mattias's line moved here from the end of the Pass; it's already recorded.)
const HALFWAY := [
	{ "do": "mattias_voice" },
	{ "who": "mattias", "line": "*echoing* Impressive, my beloved trio. Come closer…" },
	{ "who": "lykor", "mood": "smug", "line": "Bet. Here we go, folk" }, # Ebain
]

# C. Dulbers' ambush: only if he's still alive on this run (the Mart refuse / Xylo paths).
const CRY_OFF := [
	{ "who": "dulbers", "line": "*sniffling* Y'all gon' hear from Dulbmeethus about this…" }, # DRAFT
	{ "do": "dulbers_cries_off" },
]

const AMBUSH := [
	{ "do": "dulbers_sprint" },
	{ "who": "dulbers", "dyn": "dulbers_ambush", "line": "Y'all walked out my store. In front of customers." }, # DRAFT
	{ "if": "hasMidtocy", "steps": [{ "who": "dulbers", "line": "And I KNOW y'all still got my midtocy." }] }, # DRAFT
	{ "if": "goblinAllies", "steps": [{ "who": "dulbers", "line": "Where the goblins at? Y'all scared without the goblins?" }] }, # DRAFT
	{ "choice": [
		{ "text": "Apologize and swear loyalty to Dulbmeethus", "outcome": "ambush_apologize", "steps": [ # DRAFT label
			{ "who": "skorn", "mood": "confused", "line": "Aight, aight. My fault, Dulbers. We fw Dulbmeethus. On everything." }, # DRAFT
			{ "who": "dulbers", "mood": "grin", "line": "Good boy." }, # Ebain
			{ "do": "dulbers_leaves" },
		] },
		{ "text": "Fight him", "outcome": "ambush_fight", "steps": [
			{ "do": "ambush_fight" },
		] + CRY_OFF },
		{ "text": "Offer him fentocy", "outcome": "ambush_fentocy", "steps": [ # Ebain
			{ "who": "skorn", "mood": "smug", "line": "Ayo, peace offering. Here go some midtocy. On the house." }, # DRAFT
			{ "who": "dulbers", "mood": "grin", "line": "…Free midtocy? Y'all finally learning." }, # DRAFT
			{ "do": "dulbers_fentocy" },
			{ "who": "narrator", "line": "Dulbers Frint was never seen again." },
		] },
		{ "text": "Call for Mattias", "outcome": "ambush_mattias", "steps": [ # DRAFT label
			{ "who": "skorn", "mood": "shocked", "line": "MATTIAS! We need you, folk!" }, # DRAFT
			{ "do": "mattias_arrives" },
			{ "who": "mattias", "line": "Get lost midget fucker!" }, # Ebain
			{ "do": "ambush_fight_mattias" },
		] + CRY_OFF + [
			{ "do": "mattias_leaves" },
		] },
	] },
]

# F. Right before the end card (every ending except "Bad.", which stays silent).
const CHAPTER_CLOSE := [
	{ "who": "narrator", "line": "And so, the trio found the metocy, and Chapter 1 comes to a close." }, # Ebain
]

# E. After the metocy (castle choices 1, 2, 4-won and 5).
const AFTER := [
	{ "who": "mattias", "line": "Now peep this, folk. What if we gave every goblin some metocy?" }, # DRAFT
	{ "choice": [
		{ "text": "Every goblin gets metocy", "outcome": "goblins_yes", "steps": [ # DRAFT label
			{ "do": "ending_party" },
		] },
		{ "text": "Nah", "outcome": "goblins_no", "steps": [ # DRAFT label
			{ "do": "ending_normal" },
		] },
	] },
]

# D. The castle: walking up to Mattias's dais (after the hymn).
const MATTIAS_FINALE := [
	{ "do": "castle_hush" },
	{ "who": "mattias", "dyn": "mattias_welcome", "line": "Welcome to da crib folk, you had said you was looking for metocy? You have earned it. I had heard that y'all been through some shit. That's OD." }, # Ebain + DRAFT middle
	{ "if": "foughtWithMattias", "steps": [
		{ "who": "lykor", "mood": "smug", "line": "You fight like you mog." }, # DRAFT
		{ "who": "mattias", "line": "Thank you folk." }, # DRAFT
	] },
	{ "do": "show_pill" },
	{ "who": "mattias", "line": "Here yall go folk, have at it." }, # Ebain
	{ "choice": [
		{ "text": "Bet. Here we go folk.", "outcome": "castle_bet", "steps": [ # Ebain
			{ "do": "take_metocy" },
		] + AFTER },
		{ "text": "you had said u was fuckin wit one too?", "outcome": "castle_too", "steps": [ # Ebain
			{ "who": "mattias", "line": "Bet." }, # Ebain
			{ "do": "take_metocy_all" },
			{ "who": "skorn", "mood": "tweaking", "line": "Mattias you was fuckin wit one this whole time?" }, # DRAFT
			{ "who": "mattias", "line": "Bet." }, # DRAFT
		] + AFTER },
		{ "text": "Bad.", "outcome": "castle_bad", "steps": [ # Ebain
			{ "who": "mattias", "line": "Oh okay." }, # Ebain
			{ "do": "ending_bad" },
		] },
		{ "text": "Sucker punch him", "outcome": "castle_punch", "steps": [ # DRAFT label
			{ "do": "sucker_punch" },
			{ "if": "mattiasBeaten", "steps": [
				{ "who": "mattias", "line": "I should have never underestimated the trio." }, # Ebain
				{ "do": "take_metocy" },
			] + AFTER },
			{ "if_not": "mattiasBeaten", "steps": [
				{ "who": "mattias", "line": "Y'all must be geeking off that midtocy to think you could defeat me." }, # Ebain
				{ "do": "ending_cooked" },
			] },
		] },
		{ "text": "Ask for it in a Chipotle Bowl", "outcome": "castle_bowl", "steps": [ # DRAFT (plan section 5 pitch, counts as choice 1)
			{ "do": "bowl_appears" },
			{ "who": "mattias", "line": "Bet." }, # DRAFT
			{ "do": "take_metocy" },
		] + AFTER },
	] },
]

# ---------------------------------------------------------------- dynamic lines (DRAFT, first match wins)
# Each entry: [flag, value, text]. value "" = the flag just has to be set (true). Flags: way_<scene> hold this run's
# choice (ProgressData.pick_outcome), the rest are normal story flags.

# 2a. Xylo: "Damn that was OD to get here, …" (the Pass first, it's the most recent)
const XYLO_ARRIVE_START := "Damn that was OD to get here, " # Ebain
const DYN_XYLO_ARRIVE := [
	["way_pass", "fight", "we threw hands with a whole giant."],
	["way_pass", "lore", "I put a giant to sleep with lore that don't exist."],
	["way_pass", "sneak", "we tiptoed across a giant's whole body."],
	["way_pass", "midtocy", "Skorn threw a pill at a giant and it worked."],
	["way_pass", "bogdrinker", "the giant was the Chief's cousin. That's the only reason we alive."],
	["way_troll", "bad", "and that troll still mad we told him Bad."],
	["", "", "my wings hurt and I don't even use them."],
]

# 2b. Dulbers' ambush line (by what happened at his store)
const DYN_DULBERS_AMBUSH := [
	["way_mart", "xylo", "Lore-reading ahh dragon exposed my whole business."],
	["", "", "Y'all walked out my store. In front of customers."],
]

# 2c. Mattias: "…I had heard that y'all …" (the ambush first, then the biggest thing from the run)
const WELCOME_START := "Welcome to da crib folk, you had said you was looking for metocy? You have earned it. I had heard that y'all " # Ebain
const WELCOME_END := ". That's OD." # Ebain
const DYN_MATTIAS_WELCOME := [
	["way_ambush", "apologize", "swore loyalty to Dulbmeethus on the way up. ...That's OD."],   # (his pause replaces the end)
	["way_ambush", "fentocy", "gave Dulbers fentocy. That's crazy"],
	["way_ambush", "fight", "made Dulbers cry on a mountain"],
	["way_ambush", "mattias", "made Dulbers cry on a mountain"],
	["way_mart", "goblins", "had the goblins handle Dulbers"],
	["way_mart", "everyone", "beat Dulbers' ass in his own store, while tripping"],
	["way_mart", "skorn_first", "beat Dulbers' ass in his own store, while tripping"],
	["skornKing", "", "made Skorn king of the goblins"],
	["chugWon", "", "outdrank Chief Bogdrinker"],
	["way_pass", "lore", "read a giant to sleep"],
	["thumbsBeaten", "", "beat up Big Thumbs"],
	["way_troll", "bad", "told a troll his bridge was bad"],
	["", "", "been through some shit"],
]
