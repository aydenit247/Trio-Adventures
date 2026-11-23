# What counts toward "Outcomes x/17" and "Completion %" on the title screen (Asar 11/22).
# Kept across every playthrough in user://progress.cfg (Game.unlock / Game.outcomes_found / Game.completion_pct).
# Points add up to exactly 100. To add something: give it an id and points here, then unlock it:
#   - a story choice: put "outcome": "<id>" on the choice option (dialogue.gd unlocks it when picked)
#   - a flag: add it to FLAGS below (Game.set_flag unlocks it)
#   - a side quest: id "quest_<quest id>" (Game.finish_quest unlocks it)
extends RefCounted

# [id, what the player did, points, is it a story outcome?]
const ITEMS := [
	# --- the goblin throne (Scene 2): how Lykor got out of it
	["village_speech", "Gave a royal speech", 4, true],
	["village_chug", "Challenged the Chief to a chug-off", 4, true],
	["village_skorn_king", "Offered Skorn as the new king", 4, true],
	["village_sneak", "Snuck out", 4, true],
	["village_negotiate", "Let Skorn \"negotiate\"", 4, true],
	# --- the Metocy Mart (Scene 3): what they did with Dulbers' "metocy"
	["mart_everyone", "Everyone took it", 4, true],
	["mart_skorn_first", "Let Skorn try it first", 4, true],
	["mart_refuse", "Refused it", 4, true],
	["mart_xylo", "Had Xylo inspect it", 4, true],
	["mart_goblins", "Let the goblins taste-test it", 4, true],
	# --- the Mountain Pass (Scene 4): getting past Diddy Chud Giant
	["pass_midtocy", "Skorn threw the midtocy", 4, true],
	["pass_sneak", "Snuck across him", 4, true],
	["pass_lore", "Xylo read him Deloye Lore", 4, true],
	["pass_fight", "Fought him", 4, true],
	["pass_bogdrinker", "Let Chief Bogdrinker handle it", 4, true],
	# --- the Bridge Troll (Goblin Woods Trail)
	["troll_good", "Told the troll \"It's good\"", 4, true],
	["troll_bad", "Told the troll \"Bad.\"", 4, true],
	# --- side quests
	["quest_bar_tab", "Settled the bar tab", 4, false],
	["quest_lucky_spoon", "Got Grubnik's lucky spoon back", 4, false],
	["quest_lore_off", "Won the Lore-Off", 4, false],
	["quest_chug_rematch", "Beat Gulpo at the Chug-Off", 4, false],
	# --- the end of Chapter 1
	["chapter1", "Finished Chapter 1", 10, false],
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
