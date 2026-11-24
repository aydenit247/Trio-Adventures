# What counts toward "Outcomes x/26" and "Completion %" on the title screen (Asar 11/22).
# Kept across every playthrough in user://progress.cfg (Game.unlock / Game.outcomes_found / Game.completion_pct).
# Points add up to exactly 100. To add something: give it an id and points here, then unlock it:
#   - a story choice: put "outcome": "<id>" on the choice option (dialogue.gd unlocks it when picked)
#   - a flag: add it to FLAGS below (Game.set_flag unlocks it)
#   - a side quest: id "quest_<quest id>" (Game.finish_quest unlocks it)
class_name ProgressData
extends RefCounted

# [id, what the player did, points, is it a story outcome?]
const ITEMS := [
	# --- the goblin throne (Scene 2): how Lykor got out of it
	["village_speech", "Gave a royal speech", 3, true],
	["village_chug", "Challenged the Chief to a chug-off", 3, true],
	["village_skorn_king", "Offered Skorn as the new king", 3, true],
	["village_sneak", "Snuck out", 3, true],
	["village_negotiate", "Let Skorn \"negotiate\"", 3, true],
	# --- the Metocy Mart (Scene 3): what they did with Dulbers' "metocy"
	["mart_everyone", "Everyone took it", 3, true],
	["mart_skorn_first", "Let Skorn try it first", 3, true],
	["mart_refuse", "Refused it", 3, true],
	["mart_xylo", "Had Xylo inspect it", 3, true],
	["mart_goblins", "Let the goblins taste-test it", 3, true],
	# --- the Mountain Pass (Scene 4): getting past Diddy Chud Giant
	["pass_midtocy", "Skorn threw the midtocy", 3, true],
	["pass_sneak", "Snuck across him", 3, true],
	["pass_lore", "Xylo read him Deloye Lore", 3, true],
	["pass_fight", "Fought him", 3, true],
	["pass_bogdrinker", "Let Chief Bogdrinker handle it", 3, true],
	# --- the Bridge Troll (Goblin Woods Trail)
	["troll_good", "Told the troll \"It's good\"", 3, true],
	["troll_bad", "Told the troll \"Bad.\"", 3, true],
	# --- the Summit Path (Scene 5): Dulbers' ambush (only on runs where he got away from the Mart)
	["ambush_apologize", "Swore loyalty to Dulbmeethus", 3, true],
	["ambush_fight", "Fought regular-size Dulbers", 3, true],
	["ambush_fentocy", "Offered Dulbers fentocy", 3, true],
	["ambush_mattias", "Called for Mattias", 3, true],
	# --- the Wizard's Lair: what they did with the metocy
	["castle_bet", "\"Bet. Here we go folk.\"", 3, true],
	["castle_too", "Asked Mattias to take one too", 3, true],
	["castle_bad", "Told Mattias \"Bad.\"", 3, true],
	["castle_punch", "Sucker punched Mattias", 3, true],
	["castle_bowl", "Got it in a Chipotle Bowl", 3, true],
	# --- side quests
	["quest_bar_tab", "Settled the bar tab", 3, false],
	["quest_lucky_spoon", "Got Grubnik's lucky spoon back", 3, false],
	["quest_lore_off", "Won the Lore-Off", 3, false],
	["quest_chug_rematch", "Beat Gulpo at the Chug-Off", 3, false],
	# --- the end of Chapter 1
	["chapter1", "Finished Chapter 1", 4, false],
	# --- loot spots on the Goblin Woods Trail
	["loot_0", "Trail loot 1", 1, false],
	["loot_1", "Trail loot 2", 1, false],
	["loot_2", "Trail loot 3", 1, false],
	["loot_3", "Trail loot 4", 1, false],
	["loot_4", "Trail loot 5", 1, false],
	["loot_5", "Trail loot 6", 1, false],
]

# flags that unlock an item when they're set
const FLAGS := {
	"chapter1Done": "chapter1",
	"trailLoot0": "loot_0", "trailLoot1": "loot_1", "trailLoot2": "loot_2",
	"trailLoot3": "loot_3", "trailLoot4": "loot_4", "trailLoot5": "loot_5",
}

# A story choice was picked: count it (saved across playthroughs) and remember it for THIS run as a flag.
# "village_skorn_king" → Game.flags["way_village"] = "skorn_king". Outcomes are saved across playthroughs, so they
# can't say how this run went; the way_<scene> flags can (the summit's dynamic lines use them).
static func pick_outcome(id: String) -> void:
	var g = Engine.get_main_loop().root.get_node("Game")
	var scene := id.get_slice("_", 0)
	g.set_flag("way_" + scene, id.substr(scene.length() + 1))
	g.unlock(id)
