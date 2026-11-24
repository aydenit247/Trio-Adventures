# Balance sim: runs lots of fights through the real rules with fake players.
# godot --headless --path godot --script res://tools/sim_combat.gd
extends SceneTree

const BattleT = preload("res://scripts/combat/battle.gd")

func _init() -> void:
	var setups := [
		["goblins", { "party": ["skorn"], "level": 1, "inv": { "beer": 0 } }],
		["goblins", { "party": ["skorn"], "level": 1, "inv": { "beer": 3 } }],
		["goblin_patrol", { "party": ["skorn", "lykor", "xylo"], "level": 1, "inv": {} }],
		["goblin_patrol", { "party": ["lykor"], "level": 1, "inv": {} }],
		["dulbers", { "party": ["skorn", "lykor", "xylo"], "level": 2, "inv": { "beer": 3 }, "mods": { "tripping": "party" } }],
		["dulbers", { "party": ["skorn", "lykor", "xylo"], "level": 2, "inv": { "beer": 3 }, "mods": { "tripping": "skorn" } }],
		["giant", { "party": ["skorn", "lykor", "xylo"], "level": 3, "inv": { "beer": 3, "bowl": 2 }, "mods": { "enraged": true } }],
		["giant", { "party": ["skorn", "lykor", "xylo"], "level": 3, "inv": { "beer": 3, "bowl": 2 }, "mods": { "enemy_tripping": true } }],
		["giant", { "party": ["skorn", "lykor", "xylo", "chief"], "level": 3, "inv": { "beer": 3 }, "mods": { "enraged": true } }],
		["dulbers_ambush", { "party": ["skorn", "lykor", "xylo"], "level": 3, "inv": { "beer": 2, "bowl": 1 } }],
		["rats", { "party": ["skorn", "lykor", "xylo"], "level": 2, "inv": {} }],
		["rat_colony", { "party": ["skorn", "lykor", "xylo"], "level": 2, "inv": { "beer": 2 } }],
		["rat_colony", { "party": ["skorn", "lykor", "xylo"], "level": 3, "inv": { "beer": 2, "bowl": 1 } }],
		# out-leveled bosses (D.BOSS_SCALE keeps them strong): should stay close to their on-level numbers
		["dulbers", { "party": ["skorn", "lykor", "xylo"], "level": 4, "inv": { "beer": 3 }, "mods": { "tripping": "skorn" } }],
		["giant", { "party": ["skorn", "lykor", "xylo"], "level": 5, "inv": { "beer": 3, "bowl": 2 }, "mods": { "enraged": true } }],
		["dulbers_ambush", { "party": ["skorn", "lykor", "xylo"], "level": 6, "inv": { "beer": 2, "bowl": 1 } }],
		["dulbers_ambush", { "party": ["skorn", "lykor", "xylo", "mattias"], "level": 3, "inv": { "beer": 2, "bowl": 1 } }],
		["mattias", { "party": ["skorn", "lykor", "xylo"], "level": 3, "inv": { "beer": 3, "bowl": 2 } }],
		["mattias", { "party": ["skorn", "lykor", "xylo"], "level": 4, "inv": { "beer": 3, "bowl": 2 } }],
		["mattias", { "party": ["skorn", "lykor", "xylo"], "level": 5, "inv": { "beer": 5, "bowl": 3 } }],
		# the Deloye Lore Neuralink on Xylo (forecast + 15% dodge + 20 start meter): should help a little, not trivialize
		["giant", { "party": ["skorn", "lykor", "xylo"], "level": 3, "inv": { "beer": 3, "bowl": 2 }, "mods": { "enraged": true }, "gear": { "xylo": "neuralink" } }],
		["mattias", { "party": ["skorn", "lykor", "xylo"], "level": 4, "inv": { "beer": 3, "bowl": 2 }, "gear": { "xylo": "neuralink" } }],
	]
	if OS.get_environment("SIM_ONLY") != "":   # SIM_ONLY=mattias,dulbers_ambush: just those fights
		var only := OS.get_environment("SIM_ONLY").split(",")
		setups = setups.filter(func(x): return only.has(x[0]))
	for s in setups:
		for skill in ["sloppy", "average", "good"]:
			_run(s[0], s[1], skill, 300)
	quit()

func _timing(skill: String, rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	match skill:
		"sloppy": return "perfect" if r < 0.1 else ("good" if r < 0.35 else "mid")
		"average": return "perfect" if r < 0.25 else ("good" if r < 0.65 else "mid")
		_: return "perfect" if r < 0.55 else ("good" if r < 0.9 else "mid")

func _block(skill: String, rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	match skill:
		"sloppy": return "perfect" if r < 0.05 else ("good" if r < 0.25 else "")
		"average": return "perfect" if r < 0.15 else ("good" if r < 0.5 else "")
		_: return "perfect" if r < 0.4 else ("good" if r < 0.8 else "")

func _run(key: String, o: Dictionary, skill: String, n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var wins := 0
	var turns := 0
	var hp_left := 0.0
	for i in n:
		var oo := o.duplicate(true)
		oo["seed"] = rng.randi()
		var b = BattleT.new(key, oo)
		var guard := 0
		while b.result() == "" and guard < 400:
			guard += 1
			var r: Dictionary = b.next_actor()
			if b.result() != "" or r["skip"]:
				continue
			var u: Dictionary = r["u"]
			if u["side"] == "party":
				b.party_act(u, _choose(b, u, skill, rng), { "timing": _timing(skill, rng), "roll": rng.randi_range(1, 6), "rolls": [rng.randi_range(1, 6), rng.randi_range(1, 6)] })
			else:
				b.roll_chaos()
				var it: Dictionary = b.enemy_plan(u)
				b.enemy_resolve(u, it, _block(skill, rng) if it["kind"] == "hit" else "")
		if b.result() == "win":
			wins += 1
			var hp := 0.0
			var mx := 0.0
			for p in b.party:
				hp += p["hp"]
				mx += p["max_hp"]
			hp_left += hp / mx
		turns += b.stats["party_turns"]
	print("%-14s %-34s %-8s win %3d%%  turns %4.1f  hp left %3d%%" % [key, str(o.get("party")) + " L" + str(o["level"]) + " " + str(o.get("mods", {})), skill, 100 * wins / n, float(turns) / n, int(100 * hp_left / max(1, wins))])

func _choose(b, u: Dictionary, skill: String, rng: RandomNumberGenerator) -> Dictionary:
	var foes: Array = b.alive(b.enemies)
	var t: Dictionary = foes[0]
	for f in foes:
		if f["hp"] < t["hp"]:
			t = f
	var hurtp: Array = b.party.filter(func(p): return p["hp"] < p["max_hp"] * 0.35)
	var smart := skill != "sloppy" or rng.randf() < 0.5
	if smart and not hurtp.is_empty():
		var p: Dictionary = hurtp[0]
		if b.item_count(u["id"], "bowl") > 0: return { "type": "item", "item": "bowl", "target": p }
		if b.item_count(u["id"], "beer") > 0: return { "type": "item", "item": "beer", "target": p }
		if u["id"] == "chief" and u["cds"]["special"] == 0: return { "type": "move", "slot": "special", "target": p }
	if u["meter"] >= 100: return { "type": "move", "slot": "ult", "target": t }
	var combos: Array = b.combos_for(u)
	if smart and not combos.is_empty(): return { "type": "combo", "combo": combos.back(), "target": t }
	for e in foes:
		if e.get("sit_pending", false) and smart and rng.randf() < 0.5:
			return { "type": "defend" }
	if u["cds"]["special"] == 0 and u["id"] != "chief": return { "type": "move", "slot": "special", "target": t }
	if u["cds"]["bonus"] == 0:
		if u["moves"]["bonus"]["kind"] == "healone":   # heals go on the most hurt teammate, not the enemy
			var low: Array = b.alive(b.party)
			low.sort_custom(func(a, c): return float(a["hp"]) / a["max_hp"] < float(c["hp"]) / c["max_hp"])
			return { "type": "move", "slot": "bonus", "target": low[0] }
		return { "type": "move", "slot": "bonus", "target": t }
	if u["moves"].has("extra") and u["cds"]["extra"] == 0 and u["moves"]["extra"]["kind"] != "healall": return { "type": "move", "slot": "extra", "target": t }
	return { "type": "move", "slot": "main", "target": t }
