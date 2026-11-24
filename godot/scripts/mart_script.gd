# Dialogue for Scene 3 — Metocy Mart (played as Xylo). Same lines as the web game's scene3_metocy_mart.js.
# Ebain's lines are tagged  # Ebain ; the rest are Claude drafts.
extends RefCounted

const INTRO := [
	{ "who": "narrator", "line": "East of the goblin village…" },
	{ "if": "goblinAllies", "steps": [
		{ "who": "goblin", "line": "Ooooh. A STORE." },
		{ "who": "chief", "line": "Bogdrinker has heard of this place. Very legit." },
		{ "who": "skorn", "mood": "angry", "line": "Y'all OD as hell for following us still." }, # Ebain
		{ "who": "goblins", "line": "On some field trip shiiiiii." }, # Ebain
	] },
	{ "who": "narrator", "line": "(You're playing as Xylo now.)" },
]

const ARRIVE := [
	{ "who": "xylo", "mood": "vision", "line": "There. I can feel it. The metocy is near." },
	{ "if_not": "skornKing", "steps": [{ "who": "skorn", "mood": "confused", "line": "Bro, it's a store. You feel a store?" }] },
	{ "if": "skornKing", "steps": [{ "who": "lykor", "line": "It's weird without Skorn. …Peaceful, but weird." }] },
]
# Dulbers only pops out once you go for the door (Ebain 11/24), not as soon as you walk up the street.
const DULBERS_OUT := [
	{ "do": "dulbers_appears" },
	{ "who": "dulbers", "mood": "grin", "line": "Hey guys, it's your boy Dulbers Frint!" },
	{ "who": "dulbers", "mood": "grin", "line": "Y'all could pull up before the Diddy Chud Giant smells you?" }, # Ebain
	{ "if": "foreheadLoser", "steps": [
		{ "who": "dulbers", "mood": "grin", "line": "…\"Loser\"? Says so right on your forehead, my boy." },
	] },
	{ "if": "lykorDethroned", "steps": [
		{ "who": "skorn", "mood": "smug", "line": "Make way. Purple god of the goblins, coming through. No big deal." }, # Ebain
		{ "who": "lykor", "mood": "angry", "line": "You was a god for five minutes, bro. Pipe down." }, # Ebain
	] },
	{ "do": "go_inside" },
]

const DULBERS_WAITING := [
	{ "who": "dulbers", "mood": "grin", "line": "Come on in, come on in! Store's open, folk!" }, # DRAFT
]

# Reveal + demon fight (A and B)
const REVEAL_AND_FIGHT := [
	{ "do": "reveal_midtocy" },
	{ "who": "dulbers", "mood": "grin", "line": "Heh… yeah, so that's actually midtocy. Off-brand. Similar vibes doe." },
	{ "who": "skorn", "mood": "angry", "line": "YOU LACED US WITH MIDTOCY?!" },
	{ "who": "dulbers", "mood": "grin", "line": "…And now that you know…" },
	{ "do": "transform" },
	{ "who": "dulbers_demon", "line": "NOBODY LEAVES METOCY MART. NO REFUNDS. NO EXCHANGES." },
	{ "who": "skorn", "mood": "tweaking", "line": "Balright. I ain't ever pop metocy and have a jit turn into a got damn demon. This some white people shit." }, # Ebain
	{ "do": "fight_dulbers" },
	{ "if": "goblinAllies", "steps": [{ "who": "chief", "line": "Goblins: one. Demon: zero." }] },
	{ "do": "trip_end" },
	{ "who": "dulbers_demon", "line": "Ugh… fine… the REAL metocy… is past the mountain pass…" },
	{ "who": "dulbers_demon", "line": "…but nobody gets past the giant." },
	{ "do": "dulbers_vanish" },
	{ "do": "skorn_pockets" },
	{ "who": "skorn", "mood": "smug", "line": "I'm keeping one of these." },
	{ "who": "skorn", "mood": "confused", "line": "…I still kinda see colors." },
	{ "who": "lykor", "line": "Mountain pass it is." },
	{ "do": "leave" },
]

const SHOP := [
	{ "do": "show_pill" },
	{ "who": "dulbers", "line": "Finest metocy in Caelid. This shit'll have u geekin, folk. Hand-made. On some type shit." }, # Ebain
	{ "if": "skornKing", "steps": [
		{ "do": "skorn_bursts_in" },
		{ "who": "skorn", "mood": "angry", "line": "THEY HAD KICKED ME OUT." }, # Ebain
		{ "who": "lykor", "mood": "shocked", "line": "Already??" },
		{ "who": "skorn", "mood": "angry", "line": "I drank too much beezy and cracked on too many goblin biddies. They got pissed." }, # Ebain
		{ "who": "skorn", "mood": "smug", "line": "Don't judge me." },
	] },
	{ "who": "lykor", "line": "Aight, so what the word? What we owe ya for some metocy, mud?" }, # Ebain
	{ "who": "dulbers", "mood": "grin", "line": "For y'all ahh? First one's free." },
	{ "who": "lykor", "mood": "smug", "line": "On some type shit." }, # Ebain
	{ "choice": [
		# A — everyone takes it → the whole party trips → demon fight
		{ "text": "Everyone takes it", "outcome": "mart_everyone", "steps": [
			{ "who": "skorn", "mood": "smug", "line": "Free?? Say less." },
			{ "do": "take_it" },
			{ "who": "narrator", "line": "The trio takes the metocy." },
			{ "who": "lykor", "line": "…I don't feel nothing." },
			{ "who": "skorn", "line": "Me neith—" },
			{ "do": "trip_start" },
			{ "who": "skorn", "mood": "tweaking", "line": "Yo. YO. Why the floor breathing?" },
			{ "who": "lykor", "mood": "tweaking", "line": "Nah, I'm real life tweaking." }, # Ebain
			{ "who": "xylo", "mood": "tweaking", "line": "On my Unborn dragon egg… I can see sounds. The sounds is purple." },
			{ "who": "skorn", "mood": "tweaking", "line": "Nah, this don't feel like metocy. This feel like some bullshit, on my dead orcs." }, # Ebain
			{ "who": "lykor", "mood": "angry", "line": "Dulbers. What did you give us?" },
		] + REVEAL_AND_FIGHT },
		# B — Skorn tries it first → only Skorn trips → demon fight
		{ "text": "Let Skorn try it first", "outcome": "mart_skorn_first", "steps": [
			{ "who": "lykor", "line": "Skorn. You first." },
			{ "who": "skorn", "mood": "smug", "line": "Bet, let me peep ts." }, # Ebain
			{ "do": "skorn_trip" },
			{ "who": "skorn", "mood": "tweaking", "line": "…Yo, why Lykor got three heads? Which one I talk to?" },
			{ "who": "xylo", "mood": "unimpressed", "line": "Maaaan, it's cause yo ass geekin off that midtocy." },
			{ "who": "lykor", "mood": "angry", "line": "Dulbers. What did you just give my guy?" },
		] + REVEAL_AND_FIGHT },
		# C — refuse → Dulbers goes demon, kicks you out, escapes (villain later). No midtocy.
		{ "text": "Refuse it", "outcome": "mart_refuse", "steps": [
			{ "who": "lykor", "line": "Nah, we good. Sum off about you, folk." },
			{ "who": "dulbers", "line": "…Sum OFF? About ME? Your boy Dulbers?" },
			{ "do": "transform" },   # he shows his demon form (Asar: refusing should still turn him)
			{ "who": "dulbers", "mood": "demon", "line": "Aight, y'all could get the fuck out my store doe? Fo' I call up Dulbmeethus." }, # Ebain
			{ "who": "lykor", "mood": "smug", "line": "Dulbmeethus fw my ahh, I ain't trippin' bout him." }, # Ebain
			{ "do": "kicked_out" },
			{ "who": "skorn", "mood": "angry", "line": "Bro really just kicked us out of a store." },
			{ "who": "xylo", "mood": "unimpressed", "line": "And we still do not know where the metocy is." },
			{ "do": "show_pass_sign" },
			{ "who": "skorn", "mood": "confused", "line": "…Aight, that's lowkey convenient." },
			{ "who": "dulbers", "line": "*muffled, from inside* You'll regret this, trio…" },
			{ "do": "leave" },
		] },
		# D — Xylo reads Deloye Lore about it → deal, midtocy, Dulbers escapes
		{ "text": "Have Xylo inspect it", "outcome": "mart_xylo", "steps": [
			{ "do": "xylo_lore" },
			{ "who": "xylo", "mood": "vision", "line": "It is written, in chapter 8,784, section B12, that true metocy glows from within — its shell dry as desert bone, smooth as a sage's forehead. True metocy is NEVER moist." }, # Ebain's idea
			{ "who": "xylo", "mood": "unimpressed", "line": "But this one… is moist." },
			{ "who": "dulbers", "mood": "grin", "line": "It's NOT moist—" },
			{ "who": "xylo", "mood": "unimpressed", "line": "Maaan, this one is cracked, purple, and growing a small civilization." },
			{ "do": "reveal_midtocy" },
			{ "who": "lykor", "mood": "angry", "line": "You was finna lace us with MIDTOCY?" },
			{ "who": "dulbers", "line": "Aight aight aight, keep your voice down! Let's make a deal." },
			{ "who": "dulbers", "line": "The real metocy is past the mountain pass. Past the giant. Here — take some midtocy on the house. Don't tell nobody." }, # Ebain
			{ "do": "give_midtocy" },
			{ "who": "narrator", "line": "Got: Midtocy (throwable)" },
			{ "who": "skorn", "mood": "smug", "line": "Bet. I'm keeping this." },
			{ "who": "dulbers", "mood": "grin", "line": "Pleasure doing business!" },
			{ "do": "dulbers_escape" },
			{ "who": "lykor", "line": "Mountain pass it is." },
			{ "do": "leave" },
		] },
		# E — secret (goblins came along): goblins taste-test it, then take Dulbers out
		{ "text": "Let the goblins taste-test it", "outcome": "mart_goblins", "if": "goblinAllies", "steps": [
			{ "who": "lykor", "line": "Bogdrinker. Y'all try it first." },
			{ "who": "skorn", "mood": "smug", "line": "Hold up. I'm keeping one before y'all eat 'em all." },
			{ "do": "skorn_pockets" },
			{ "who": "chief", "line": "An honor." },
			{ "do": "goblins_taste" },
			{ "who": "goblins", "line": "…" },
			{ "who": "chief", "line": "THIS AIN'T METOCY. THIS MIDTOCY. BOGDRINKER KNOWS HIS DRUGS." },
			{ "who": "dulbers", "mood": "grin", "line": "…Uh oh." },
			{ "who": "goblins", "line": "GET HIMMMM!" },
			{ "do": "goblin_chase" },
			{ "who": "chief", "line": "Bogdrinker handled it. Do not ask questions." },
			{ "who": "narrator", "line": "Dulbers Frint was never seen again." },
			{ "who": "chief", "line": "The real metocy is past the giant. Field trip is over. Goblins — HOME." },
			{ "do": "goblins_go_home" },
			{ "who": "xylo", "mood": "unimpressed", "line": "On my Dragon Grandpa… our entourage has left us." },
			{ "who": "skorn", "line": "Good riddance. …I kinda miss 'em." },
			{ "do": "leave" },
		] },
	] },
]
