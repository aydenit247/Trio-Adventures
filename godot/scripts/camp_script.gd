# Dialogue for the camp test. Same format as the web game's scene scripts:
#   { who, mood, line, thought }       a line of dialogue
#   { choice: [ { text, steps } ] }    a choice
#   { do: "name" }                     calls main.gd → do_action(name)
#   { if: "flag", steps } / { if_not: "flag", steps }
# Ebain's own lines are tagged  # Ebain   and Claude's drafts  # DRAFT.
extends RefCounted

const INTRO := [
	{ "who": "narrator", "line": "Caelid. Night. The night before the greatest quest of their lives." }, # Ebain
	{ "who": "narrator", "line": "The quest for the metocy." }, # Ebain
	{ "who": "narrator", "line": "(2.5D test — WASD to walk, E to talk, Tab to switch who you control.)" },
]

# Talking to a party member who isn't the one you're controlling
const TALK := {
	"lykor": [
		{ "if": "bag_checked", "steps": [
			{ "who": "lykor", "mood": "angry", "line": "Why is my bag open. Who opened my bag." }, # DRAFT
			{ "who": "skorn", "thought": true, "line": "Act natural." }, # DRAFT
		] },
		{ "who": "lykor", "mood": "flattered", "line": "Dat metocy gon be gah tomorrow, on the absolute." }, # Ebain
		{ "choice": [
			{ "text": "Ask about his bag", "steps": [
				{ "who": "lykor", "line": "Aight bet. But don't touch my bag, though." }, # Ebain
				{ "who": "skorn", "mood": "smug", "line": "Why would I touch yo bag, mud?" }, # DRAFT (same as web Scene 1)
			] },
			{ "text": "Compliment his hair", "steps": [
				{ "who": "lykor", "mood": "flattered", "line": "I know. The conditioner is doing numbers tonight." }, # DRAFT
			] },
			{ "text": "Leave", "steps": [] },
		] },
	],
	"xylo": [
		{ "who": "xylo", "line": "On my Dragon Mama it is." }, # Ebain
		{ "who": "xylo", "mood": "vision", "line": "Deloye Lore, Volume 4, says the night before a quest is sacred." }, # DRAFT
		{ "who": "skorn", "mood": "confused", "line": "What it say about the metocy?" }, # DRAFT
		{ "who": "xylo", "mood": "unimpressed", "line": "Nothing. There is no lore." }, # DRAFT
	],
	"skorn": [
		{ "who": "skorn", "line": "Man, it's about cold as a motherfucker." }, # Ebain
		{ "who": "skorn", "mood": "smug", "line": "Good thing I got the fire going though." }, # DRAFT
	],
}

# Objects and NPCs around camp
const OBJECTS := {
	"fire": [
		{ "who": "narrator", "line": "The campfire. Burning bright. Suspiciously bright." }, # DRAFT
		{ "who": "skorn", "mood": "smug", "line": "Best fire starter I ever used." }, # DRAFT
	],
	"map": [
		{ "who": "narrator", "line": "A charred scrap of paper. All that's left reads: \"…TOCY\"." }, # DRAFT
		{ "who": "skorn", "thought": true, "line": "Bunch of squiggly ass lines." }, # DRAFT (from web Scene 1)
		{ "who": "lykor", "mood": "shocked", "line": "Why does that look like… nah. Nah." }, # DRAFT
	],
	"bag": [
		{ "who": "narrator", "line": "Lykor's bag. It's open. Something important used to be in here." }, # DRAFT
		{ "choice": [
			{ "text": "Look inside", "steps": [
				{ "do": "check_bag" },
				{ "who": "narrator", "line": "Conditioner. Three bottles. Nothing else. Anymore." }, # DRAFT
				{ "who": "lykor", "mood": "angry", "line": "Don't touch my bag, though!" }, # Ebain (adapted)
			] },
			{ "text": "Leave it alone", "steps": [
				{ "who": "skorn", "thought": true, "line": "Already touched it once. That's enough for one night." }, # DRAFT
			] },
		] },
	],
	"tent": [
		{ "who": "skorn", "line": "I'm not tired. I'm finna stay up and guard the fire." }, # DRAFT
		{ "who": "xylo", "mood": "unimpressed", "line": "Guard it from what." }, # DRAFT
		{ "who": "skorn", "mood": "angry", "line": "From… other fires." }, # DRAFT
	],
	"goblin": [
		{ "who": "goblin", "line": "Ayo. Y'all hiring?" }, # DRAFT
		{ "choice": [
			{ "text": "What can you do?", "steps": [
				{ "who": "goblin", "line": "I can hold a spoon." }, # DRAFT
				{ "who": "skorn", "mood": "smug", "line": "…Respect." }, # DRAFT
			] },
			{ "text": "Nah", "steps": [
				{ "who": "goblin", "line": "Damn. Aight. My village is up north if y'all change your mind." }, # DRAFT
			] },
		] },
	],
}

# Walking down the dark path
const MATTIAS := [
	{ "who": "mattias", "line": "You had called?" }, # Ebain
	{ "who": "skorn", "mood": "shocked", "line": "Metocin Mattias? What are you doing here?" }, # Ebain
	{ "do": "mattias_vanish" },
	{ "who": "xylo", "mood": "shocked", "line": "I did not see ts coming. Ts was not in the Deloye Lore scripture." }, # Ebain
]
