extends Node
# Checks every trigger type in achievements.gd without playing the game (Ebain's 11/25 batch).
#   godot --headless --path godot res://tools/test_achievements.tscn
# It clears the saved achievements/progress first, so don't run it on a PC with a real save.
var fails := 0

func check(label: String, ok: bool) -> void:
	if not ok:
		fails += 1
	print(("PASS " if ok else "FAIL ") + label)

func has(id: String) -> bool:
	return Game.ach.got.has(id)

func _ready() -> void:
	await get_tree().process_frame
	Game.title_mode = false
	Game.ach.got.clear()
	Game.ach.counts.clear()
	Game.progress.clear()
	var ids := {}
	for a in Achievements.LIST:
		check("unique id " + a["id"], not ids.has(a["id"]))
		ids[a["id"]] = true
	# counters
	Game.ach.bump("beer"); Game.ach.bump("beer")
	check("crunk not yet at 2", not has("crunk"))
	Game.ach.bump("beer")
	check("crunk at 3", has("crunk"))
	for i in 3: Game.ach.bump("bowl")
	check("slopbowl at 3", has("slopbowl"))
	for i in 4: Game.ach.bump("fled")
	check("retreat not yet at 4", not has("tactical_retreat"))
	Game.ach.bump("fled")
	check("retreat at 5", has("tactical_retreat"))
	var cf := ConfigFile.new()
	cf.load(Achievements.SAVE_PATH)
	check("counts saved", int(cf.get_value("counts", "fled", 0)) == 5 and cf.has_section_key("got", "crunk"))
	# flags
	Game.set_flag("sneakWon", false)
	check("sneaky not on a lost sneak", not has("sneaky_shi"))
	var flags := { "sneakWon": "sneaky_shi", "dulbersMet": "dulbers_boy", "giantWoke": "aight_bet", "loreWon": "lore_session",
		"endingCooked": "geeking", "mattiasBeaten": "mattias_slayer", "endingParty": "metocy_party", "deloyeGift": "neuralinked",
		"bought_golden_ladle": "ladle_shi", "bought_jordan9s": "drip" }
	for f in flags:
		Game.set_flag(f)
		check("flag " + f, has(flags[f]))
	# progress ids
	Game.unlock("ambush_apologize")
	check("good boy", has("good_boy"))
	Game.unlock("pass_fight")
	check("slap", has("diddy_slap"))
	# "all:" (the last id is the trigger, recorded after the event)
	for i in 5: Game.unlock("loot_%d" % i)
	check("trail mix not at 5/6", not has("trail_mix"))
	Game.unlock("loot_5")
	check("trail mix at 6/6", has("trail_mix"))
	for a in ["camp", "trail", "village", "mart"]: Game.unlock("lostpage_" + a)
	check("specialist not at 4/5", not has("lore_specialist"))
	Game.unlock("lostpage_pass")
	check("specialist at 5/5", has("lore_specialist"))
	# manual
	for m in ["six_seven", "hear_me_doe", "cooked"]:
		Game.achieve(m)
		check("manual " + m, has(m))
	# 100%
	check("no 100% yet", not has("hundred"))
	for it in ProgressData.ITEMS: Game.unlock(it[0])
	await get_tree().process_frame
	check("100%", has("hundred"))
	print("ACHIEVEMENTS TEST ", "ALL OK" if fails == 0 else "%d FAILED" % fails, "  (%d/%d unlocked)" % [Game.ach.count(), Achievements.LIST.size()])
	get_tree().quit(1 if fails else 0)
