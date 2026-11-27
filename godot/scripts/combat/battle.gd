# Combat rules engine — pure logic, no nodes. BattleView drives it and animates the events it returns.
# Ported from the web version's src/combat/engine.js (Combat 2.0), plus: recruited allies (the Chief),
# gear, Level 3 moves, Talk and Flee.
#
# Turn order is a speed timeline (like FFX): every unit has `next`, the time of its next turn.
# Whoever has the lowest `next` acts, then waits 100/spd before acting again. Faster = more turns.
#
# Flow per turn:
#   var r := battle.next_actor()            # { u, events, skip } — burns, skips, etc.
#   party:  battle.party_act(u, action, { timing, roll, rolls, accept67 }) → events
#   enemy:  battle.roll_chaos() → events;  intent = battle.enemy_plan(u)
#           battle.enemy_resolve(u, intent, block_timing) → events
#
# Events are plain dictionaries ({ t = "dmg", u = unit, amt, hp, text, ... }) the view plays in order.
class_name Battle
extends RefCounted

const D = preload("res://scripts/combat/combat_data.gd")
const BASE := 100.0
const TIMING := { "perfect": 1.5, "good": 1.2, "mid": 0.9 }
const BLOCK := { "perfect": 0.35, "good": 0.7, "mid": 1.0 }
const DURATION := ["mogged", "lorepill", "downbad", "cooked", "gouged", "locked", "copium", "itis", "braced", "poisoned", "guarded"]

var key := ""
var def: Dictionary
var mods: Dictionary
var rng := RandomNumberGenerator.new()
var diff: Dictionary
var level := 1
var lvl := 1.0
var faded_ids := {}        # Faded fighters (Deloye library): heal a little each turn, take 10% less; survives a KO
var lore_nerf := false     # told Deloye "Bad.": Xylo's Deloye Lore moves fizzle half the time
var bags := {}                    # fighter id -> { beer, bowl }: everyone uses their own items
var used67 := false
var hype := 0
var now := 0.0
var chaos_used := false
var bolt_pending := false         # Dulbmeethus' lightning this fight (rolled once in _init)
const BOLT_CHANCE := 0.067        # Ebain 11/25: 6.7% of fights (was 3%)
const BOLT_BOSS := 0.4            # bosses aren't one-shot: they lose 40% of their max HP
var emergency_given := false
var stats := { "party_turns": 0, "dmg_taken": 0, "kos": 0, "items": 0, "timed": 0, "perfects": 0, "goods": 0, "combos": 0, "breaks": 0, "payoffs": 0, "weak_hits": 0, "moves": {} }
var _cur_move := ""   # move being resolved, for stats["moves"] (the sim's move report)
var shi_discount := false   # "on some type shi": the next team-up costs half meter (11/26)
var party: Array = []
var enemies: Array = []
var dmg_scale := 1.0
var _ahead := 0
var enemy_hp_mul := 1.0           # what enemy HP was scaled by (Dulbers' adds use it too)
var boss_dmg := 1.0               # D.BOSS_SCALE: bosses hit harder when you out-level them
var throwables: Array = []        # names of the real props piled next to the party (BattleView); empty = D.THROWABLES
var ended := ""          # "fled" / "talked" when the fight ends without a winner

func _init(fight: String, o: Dictionary = {}) -> void:
	key = fight
	def = D.FIGHTS[fight]
	mods = o.get("mods", {})
	throwables = o.get("throwables", [])
	if o.has("seed"):
		rng.seed = o["seed"]
	else:
		rng.randomize()
	diff = D.DIFFICULTY[clampi(o.get("difficulty", 1), 0, 2)]
	level = o.get("level", 1)
	lvl = 1.0 + 0.1 * (level - 1)
	var oi: Dictionary = o.get("inv", {})
	used67 = o.get("used67", false)
	lore_nerf = o.get("lore_nerf", false)
	var gear: Dictionary = o.get("gear", {})
	var hurt: Dictionary = o.get("hurt", {})   # HP missing from earlier fights (Game.hurt); empty = full HP

	var ids: Array = o.get("party", def.get("party", ["skorn", "lykor", "xylo"]))
	for i in ids.size():
		var id: String = ids[i]
		var P: Dictionary = D.PARTY[id]
		var gv = gear.get(id, "")   # combined stats from Game.gear_stats() (or one gear id, e.g. from the balance sim)
		var g: Dictionary = _gear_perks(id, gv, gv if gv is Dictionary else D.GEAR.get(gv, {}))
		var max_hp := int(round((P["hp"] + g.get("hp", 0)) * lvl))
		var moves: Dictionary = P["moves"].duplicate()
		for at in P.get("learn", {}):
			if level >= at:
				moves["extra"] = P["learn"][at]
		party.append({
			"side": "party", "id": id, "key": id, "P": P, "moves": moves, "name": P["name"], "max_hp": max_hp, "hp": clampi(max_hp - int(hurt.get(id, 0)), 1, max_hp),
			"spd": P["spd"] + g.get("spd", 0), "order": i, "meter": g.get("start", 0), "cds": { "special": 0, "bonus": 0, "extra": 0 },
			"st": {}, "defending": false, "gear": g, "armor": int(g.get("armor", 0)), "low_warned": false,
			"tripping": mods.get("tripping", "") == "party" or (mods.get("tripping", "") == "skorn" and id == "skorn"),
		})

	for p in party:   # o.inv = { fighter: {beer, bowl, joint} } (Game.fight_bags), or one shared {beer, bowl} (balance sim) → first fighter
		bags[p["id"]] = { "beer": 0, "bowl": 0, "joint": 0 }
		if oi.get(p["id"]) is Dictionary:
			bags[p["id"]] = { "beer": int(oi[p["id"]].get("beer", 0)), "bowl": int(oi[p["id"]].get("bowl", 0)), "joint": int(oi[p["id"]].get("joint", 0)) }
		if o.get("faded", false):
			_make_faded(p)
	if oi.has("beer") or oi.has("bowl"):
		bags[party[0]["id"]] = { "beer": int(oi.get("beer", 0)), "bowl": int(oi.get("bowl", 0)) }
	var full_party: int = def.get("party", ids).size()
	var hp_mul: float = (1.15 if mods.get("enraged", false) else 1.0) * diff["hp"] * (0.75 if ids.size() < full_party else 1.0)
	if ids.size() > full_party and def.get("boss", false):
		hp_mul *= 1.08   # the Chief came along: bosses get a little beefier
	if def.get("boss", false) and def.has("lvl"):   # out-leveled the boss? it keeps up (D.BOSS_SCALE)
		var over := clampi(level - int(def["lvl"]), 0, int(D.BOSS_SCALE["cap"]))
		hp_mul *= 1.0 + D.BOSS_SCALE["hp"] * over
		boss_dmg = 1.0 + D.BOSS_SCALE["dmg"] * over
	if def.get("boss", false) and not def.get("drip_scale", false):   # every other boss keeps up with your gear too, milder (11/26)
		var bd := 0.0
		for p in party:
			bd += _drip(p["gear"])
		hp_mul *= 1.0 + D.BALANCE["boss_drip_hp"] * bd
		boss_dmg *= 1.0 + D.BALANCE["boss_drip_dmg"] * bd
	if def.get("drip_scale", false):   # the final boss "out-mogs your drip": scales with the party's gear (Ebain 11/26)
		var drip := 0.0
		for p in party:
			drip += _drip(p["gear"])
		hp_mul *= 1.0 + D.MATTIAS_BOSS["drip_hp"] * drip
		boss_dmg *= 1.0 + D.MATTIAS_BOSS["drip_dmg"] * drip
	if not def.get("story", false):
		# roaming fights scale with how many of you there are (11/26: steeper for a full party, solo unchanged;
		# a 3-person patrol used to end at ~90% HP)
		hp_mul *= 0.85 + D.ROAMING["hp_per"] * (ids.size() - 1)
		dmg_scale = 1.0 + D.ROAMING["dmg_per"] * (ids.size() - 1)
		# 11/26: they keep up with your level too (patrols were 100% wins at ~90% HP even after enemy roles)
		var rover: int = maxi(0, level - int(def.get("lvl", 1)))
		hp_mul *= 1.0 + D.ROAMING["hp_lvl"] * rover
		dmg_scale *= 1.0 + D.ROAMING["dmg_lvl"] * rover
	enemy_hp_mul = hp_mul
	for i in def["enemies"].size():
		var E: Dictionary = def["enemies"][i]
		var e := {
			"side": "enemy", "key": "e%d" % i, "E": E, "name": E["name"], "tag": E.get("tag", ""), "ai": E["ai"],
			"boss": E.get("boss", false), "order": 10 + i, "max_hp": int(round(E["hp"] * hp_mul)), "spd": E["spd"],
			"st": {}, "turn": 0, "phase": 1, "second_wind": E.get("second_wind", false),
		}
		e["hp"] = e["max_hp"]
		if e["boss"]:   # break bar (11/26)
			e["brk"] = 0.0
			e["brk_max"] = e["max_hp"] * D.BREAK["frac"]
		if mods.get("enraged", false): e["tag"] = "(ENRAGED)"
		if mods.get("enemy_tripping", false): e["tag"] = "(Tripping)"
		enemies.append(e)

	# Opening positions: the party usually gets the first swing
	for i in party.size():
		party[i]["next"] = delay(party[i]) * (0.35 + i * 0.02)
	for i in enemies.size():
		enemies[i]["next"] = delay(enemies[i]) * (0.7 + i * 0.12)
	# Dulbmeethus' lightning (Ebain 11/24): 6.7% of fights (11/25), he pulls up on the first enemy turn and smites their side.
	# BOLT=1 forces it (tests).
	bolt_pending = rnd() < BOLT_CHANCE or OS.get_environment("BOLT") != "" or o.get("dulbmeethus", false)   # o.dulbmeethus: the dev menu toggle (Game.dev_dulbmeethus)

# ------------------------------------------------------------------ helpers
# gear score of one fighter (Mattias' "Out-Mogs your drip" and the milder boss version both use it)
func _drip(g: Dictionary) -> float:
	return g.get("power", 0.0) + g.get("armor", 0) * 0.03 + g.get("spd", 0) * 0.03 + g.get("hp", 0) / 150.0 + g.get("start", 0) / 200.0

func delay(u: Dictionary) -> float:
	return BASE / u["spd"]   # (the Giant's phase-2 speed-up went away 11/26: the free second action replaces it)

func alive(list: Array) -> Array:
	return list.filter(func(x): return x["hp"] > 0)

func pick(arr: Array):
	return arr[rng.randi() % arr.size()]

func rnd() -> float:
	return rng.randf()

func units() -> Array:   # downed fighters still get turns: they roll death saves (11/26)
	return alive(party) + downed() + alive(enemies)

# Downed (Ebain 11/26, BG3 death saves): at 0 HP you're Downed, not out. Each turn you roll a d20 (10+ passes):
# 3 passes = back up at 1 HP, a nat 20 = up at half HP (and you act), a nat 1 = two fails, 3 fails = dead for the rest of
# the fight (back up at 1 HP afterward, like a knockout always was). A teammate can spend their turn to Help Up.
func downed() -> Array:
	return party.filter(func(p): return p["hp"] <= 0 and p.get("down", false) and not p.get("dead", false))

# Drivers (BattleView, the sim) call this before planning each action: action 0 is the real one, 1 is the bonus
func begin_action(e: Dictionary, i: int) -> void:
	e["bonus_act"] = i > 0

# How many actions an enemy gets this turn (Ebain 11/26: bosses in phase 2 get a free second one, BG3 legendary style).
# Intents with "free" (Dulbers shapeshifting) don't use one up. The view and the sim both loop on this.
func enemy_actions(e: Dictionary) -> int:
	return 2 if e.get("boss", false) and e.get("phase", 1) == 2 and not def.get("no_tempo", false) else 1

func result() -> String:
	if ended != "": return ended
	if alive(enemies).is_empty(): return "win"
	if alive(party).is_empty(): return "lose"
	return ""

func _sort(a: Dictionary, b: Dictionary) -> bool:
	if a["next"] == b["next"]:
		return a["order"] < b["order"]
	return a["next"] < b["next"]

# Upcoming turns for the turn-order bar (doesn't change anything)
func preview(n := 8) -> Array:
	var sim := []
	for u in units():
		var skips := (1 if u["st"].has("stun") else 0) + (1 if u["st"].has("charm") else 0) + (1 if u["st"].has("flattened") else 0)
		sim.append({ "u": u, "next": u["next"], "order": u["order"], "skips": skips })
	var out := []
	while out.size() < n and not sim.is_empty():
		sim.sort_custom(_sort)
		var s: Dictionary = sim[0]
		out.append({ "u": s["u"], "skip": s["skips"] > 0 })
		if s["skips"] > 0: s["skips"] -= 1
		s["next"] += delay(s["u"])
	return out

func bark(u: Dictionary, kind: String, chance := 0.35) -> Array:
	var who: String = u.get("id", u.get("ai", ""))
	var lines: Array = D.BANTER.get(who, {}).get(kind, [])
	if lines.is_empty() or rnd() > chance:
		return []
	return [{ "t": "bark", "u": u, "line": pick(lines) }]

func add_meter(m: Dictionary, amt: float) -> Array:
	if m == null or m.is_empty() or m["side"] != "party" or m["hp"] <= 0 or amt <= 0:
		return []
	var before: int = m["meter"]
	if m["hp"] < m["max_hp"] * D.BALANCE["comeback_hp"]:   # comeback power (11/26): low HP fills the meter faster
		amt *= D.BALANCE["comeback_mult"]
	m["meter"] = mini(100, m["meter"] + int(round(amt * m["gear"].get("meter", 1.0))))
	return [{ "t": "meter_full", "u": m }] if before < 100 and m["meter"] >= 100 else []

# ------------------------------------------------------------------ turn start
func next_actor() -> Dictionary:
	var list := units()
	list.sort_custom(_sort)
	var u: Dictionary = list[0]
	now = u["next"]
	u["next"] += delay(u)
	var ev := []
	var had: Dictionary = u["st"].duplicate()
	for k in DURATION:
		if u["st"].has(k):
			u["st"][k] -= 1
			if u["st"][k] <= 0:
				u["st"].erase(k)

	if u["side"] == "party" and u["hp"] <= 0:
		return _death_save(u, ev)
	if u["side"] == "party":
		stats["party_turns"] += 1
		u["defending"] = false
		if had.has("poisoned") and u["hp"] > 1:   # a plague rat's bite (11/26): ticks, never knocks you out
			var pd := mini(D.ROLES["poison"], u["hp"] - 1)
			u["hp"] -= pd
			ev.append({ "t": "self_hit", "u": u, "amt": pd, "hp": u["hp"], "text": "%s is Poisoned. (-%d)" % [u["name"], pd] }) # DRAFT
		if faded_ids.has(u["id"]) and u["hp"] > 0:
			u["st"]["faded"] = 1   # (a KO or a cleanse clears statuses: Faded comes back)
			var fh := mini(int(round(D.FADED["heal"] * lvl)), u["max_hp"] - u["hp"])
			if fh > 0:
				u["hp"] += fh
				ev.append({ "t": "heal", "u": u, "amt": fh, "hp": u["hp"], "text": "%s is Faded. Real chill. (+%d)" % [u["name"], fh], "quiet": true })
		for c in u["cds"]:
			u["cds"][c] = maxi(0, u["cds"][c] - 1)
		if u["st"].has("flattened"):
			u["st"].erase("flattened")
			ev.append({ "t": "say", "text": "%s is still flattened. Can't move." % u["name"], "sound": "miss" })
			return { "u": u, "events": ev, "skip": true }
		return { "u": u, "events": ev + _foresee(), "skip": false }

	# Enemy: burns and copium first
	u["turns_taken"] = u.get("turns_taken", 0) + 1
	if had.has("cooked"):
		ev += damage_enemy({}, u, 6, { "text": "%s is Cooked. The fire is still going." % u["name"], "sound": "fire", "raw": true })
		if u["hp"] <= 0: return _skip(u, ev)
	if had.has("copium") and u["st"].has("copium"):
		var h := mini(8, u["max_hp"] - u["hp"])
		u["hp"] += h
		ev.append({ "t": "heal", "u": u, "amt": h, "hp": u["hp"], "text": "%s is on Copium. (+%d)" % [u["name"], h] })
	if u["st"].has("broken"):   # break bar emptied: he loses this turn (even Locked In)
		u["st"].erase("broken")
		ev.append({ "t": "say", "text": "%s is still BROKEN and seeing stars. Loses the turn." % u["name"], "sound": "miss" }) # DRAFT
		return _skip(u, ev)
	# Telegraph counters: CC'd while winding up a sit or a snack
	var cc := "stun" if u["st"].has("stun") else ("charm" if u["st"].has("charm") else "")
	if cc != "" and (u.get("sit_pending", false) or u.get("eat_pending", false) or u.get("sale_pending", false) or u.get("stampede_pending", false)):
		u["st"].erase(cc)
		if u.get("sale_pending", false) or u.get("stampede_pending", false):
			u["sale_pending"] = false
			u["stampede_pending"] = false
			ev.append({ "t": "say", "text": "%s loses his train of thought. The big attack is cancelled." % u["name"], "sound": "miss" }) # DRAFT
		elif u.get("sit_pending", false):
			u["sit_pending"] = false
			ev.append({ "t": "tex", "u": u, "tex": u["E"]["tex"] })
			ev += damage_enemy({}, u, 35, { "text": "%s loses his balance and sits on his OWN FOOT!" % u["name"], "sound": "sit", "raw": true, "shake": true })
		else:
			u["eat_pending"] = false
			ev.append({ "t": "say", "text": "%s drops his Chipotle Bowl. It's over for the bowl." % u["name"], "sound": "miss" })
		return _skip(u, ev)
	if u["st"].has("stun"):
		u["st"].erase("stun")
		ev.append({ "t": "say", "text": "%s is being sat on and can't move." % u["name"], "sound": "miss" })
		return _skip(u, ev + lock_in(u))
	if u["st"].has("charm"):
		u["st"].erase("charm")
		var others := alive(enemies).filter(func(x): return not is_same(x, u))
		if not others.is_empty():
			var t: Dictionary = pick(others)
			ev += damage_enemy({}, t, 6, { "text": "%s is GLAZED. He bonks %s to impress Lykor." % [u["name"], t["name"]], "sound": "bonk", "raw": true })
		else:
			ev.append({ "t": "say", "text": "%s is too busy staring at Lykor's hair." % u["name"], "sound": "sparkle" })
		return _skip(u, ev + lock_in(u))
	if had.has("itis") and rnd() < 0.7:
		ev.append({ "t": "say", "text": "%s has the itis. He's taking a little nap. Zzz." % u["name"], "sound": "miss" })
		return _skip(u, ev)
	if had.has("lorepill") and rnd() < 0.5:
		ev.append({ "t": "say", "text": "%s is Lore-pilled and dozes off mid-turn. Zzz." % u["name"], "sound": "miss" })
		return _skip(u, ev + lock_in(u))
	return { "u": u, "events": ev, "skip": false }

# An enemy loses its turn: a Neuralink forecast for that turn is thrown away (it never happened)
func _skip(u: Dictionary, ev: Array) -> Dictionary:
	_drop_plan(u)
	return { "u": u, "events": ev, "skip": true }

func _death_save(u: Dictionary, ev: Array) -> Dictionary:
	var roll := rng.randi_range(1, 20)
	var sv: Array = u["saves"]
	var txt := ""
	if roll == 20:
		u["hp"] = int(ceil(u["max_hp"] / 2.0))
		u["down"] = false
		ev.append({ "t": "save", "u": u, "roll": roll, "text": "%s rolls a NAT 20 and gets up!" % u["name"] }) # DRAFT
		ev.append({ "t": "revive", "u": u, "hp": u["hp"], "text": "%s is back! (%d %s)" % [u["name"], u["hp"], u["P"]["hp_label"]] })
		return { "u": u, "events": ev, "skip": false }
	if roll == 1:
		sv[1] += 2
		txt = "A nat 1. Two fails."
	elif roll >= 10:
		sv[0] += 1
		txt = "Pass."
	else:
		sv[1] += 1
		txt = "Fail."
	ev.append({ "t": "save", "u": u, "roll": roll, "text": "%s's death save: %d. %s (%d/3 passes, %d/3 fails)" % [u["name"], roll, txt, mini(3, sv[0]), mini(3, sv[1])] })
	if sv[1] >= 3:
		ev += _die(u)
	elif sv[0] >= 3:
		u["hp"] = 1
		u["down"] = false
		ev.append({ "t": "revive", "u": u, "hp": 1, "text": "%s stabilizes and gets up. (1 %s)" % [u["name"], u["P"]["hp_label"]] }) # DRAFT
	return { "u": u, "events": ev, "skip": true }

func _die(u: Dictionary) -> Array:
	u["dead"] = true
	stats["deaths"] = stats.get("deaths", 0) + 1
	return [{ "t": "dead", "u": u, "text": "%s is DEAD. (Out for the rest of this fight.)" % u["name"] }] # DRAFT

# AoE hits landing on a Downed fighter: one failed save each
func _downed_hit(p: Dictionary) -> Array:
	p["saves"][1] += 1
	var ev := [{ "t": "save_fail", "u": p, "text": "%s gets hit while Downed. Failed save (%d/3)." % [p["name"], mini(3, p["saves"][1])] }] # DRAFT
	if p["saves"][1] >= 3:
		ev += _die(p)
	return ev

func _drop_plan(e: Dictionary) -> void:
	if e.has("planned"):
		e.erase("planned")
		e["turn"] -= 1   # enemy_plan counted the turn when it was forecast
	e["foresaw"] = false

# ---- the Deloye Lore Neuralink (DELOYE_PLAN.md): gear perks Game.gear_stats() doesn't add up (game.gd), so they're
# read straight from the equipped gear here. gv = Game.gear_stats() dict (the game) or one gear id (the balance sim).
func _gear_perks(id: String, gv, g: Dictionary) -> Dictionary:
	if g.has("dodge") or g.has("foresee"):
		return g
	var ids: Array = []
	if gv is String:
		ids = [gv]
	else:
		var ml = Engine.get_main_loop()
		var G = ml.root.get_node_or_null("Game") if ml is SceneTree else null
		if G and G.has_method("slots_of"):
			ids = G.slots_of(id).values()
	var out := g.duplicate()
	for gid in ids:
		var X: Dictionary = D.GEAR.get(gid, {})
		if X.get("dodge", 0.0) > 0.0:
			out["dodge"] = float(out.get("dodge", 0.0)) + X["dodge"]
		if X.get("foresee", false):
			out["foresee"] = true
	return out

# Foresee: at the start of a party turn, plan the next enemy's move early and say what it is. enemy_plan() hands that
# exact plan back when the enemy's turn comes (re-planned only if its target is gone or a phase change cut in).
func _foresee() -> Array:
	if not alive(party).any(func(p): return p["gear"].get("foresee", false)):
		return []
	for s in preview(8):
		var e: Dictionary = s["u"]
		if e["side"] != "enemy":
			continue
		if s["skip"] or e["hp"] <= 0:
			return []
		if e.get("foresaw", false):
			return []   # already said this one
		if not e.has("planned"):
			_ahead = 1   # planning his NEXT turn: telegraph timing counts that turn (_telegraph)
			e["planned"] = enemy_plan(e)
			_ahead = 0
		e["foresaw"] = true
		return [{ "t": "say", "text": "NEURALINK: " + _intent_text(e, e["planned"]), "sound": "sparkle", "ms": 1500 }]
	return []

func _intent_text(e: Dictionary, it: Dictionary) -> String:   # DRAFT wording
	var who: String = e["name"]
	match it["kind"]:
		"hit":
			var on: String = "everyone" if it.get("aoe", false) else it["targets"][0]["name"]
			return "%s is about to use %s on %s." % [who, it.get("name", "an attack"), on]
		"telegraph": return "%s is winding up something BIG." % who
		"eat": return "%s is about to snack. (Heals.)" % who
		"steal": return "%s is eyeing your Beezys." % who
		"shield": return "%s is about to steal Lykor's aura." % who
		"buff": return "%s is about to buff up (%s)." % [who, String(it.get("status", "")).to_upper()]
		"hype": return "%s is about to hype up %s." % [who, it["other"]["name"]]
		"phase": return "%s is about to switch it up." % who
		"heal_ally": return "%s is about to heal %s." % [who, it["target"]["name"]]
		"guard": return "%s is about to guard %s." % [who, it["target"]["name"]]
	return "%s is about to do... nothing useful." % who

# Bosses get Locked In after losing a turn, so you can't chain charm/stun forever
func lock_in(u: Dictionary) -> Array:
	if not u["boss"] or u["hp"] <= 0:
		return []
	u["st"]["locked"] = 3
	return [{ "t": "status", "u": u, "name": "locked", "text": "%s is LOCKED IN. Can't be charmed, stunned or Lore-pilled for a bit." % u["name"] }]

func can_cc(e: Dictionary) -> bool:
	return not e["st"].has("locked") or e.get("sit_pending", false) or e.get("eat_pending", false) or e.get("sale_pending", false) or e.get("stampede_pending", false)

func apply_cc(e: Dictionary, kind: String, turns := 1) -> Array:
	if e["hp"] <= 0: return []
	if not can_cc(e):
		return [{ "t": "say", "text": "%s is Locked In. Didn't work." % e["name"], "sound": "miss", "ms": 900 }]
	e["st"][kind] = maxi(e["st"].get(kind, 0), turns)
	var txt: String = {
		"charm": "%s is charmed by the hair. They might just… stand there.",
		"stun": "%s is SAT ON. They lose their next turn.",
		"lorepill": "%s is LORE-PILLED. Getting sleepy…",
	}[kind] % e["name"]
	return [{ "t": "status", "u": e, "name": kind, "text": txt }]

func apply_status(e: Dictionary, name: String, turns: int, text: String) -> Array:
	if e["hp"] <= 0: return []
	e["st"][name] = maxi(e["st"].get(name, 0), turns)
	return [{ "t": "status", "u": e, "name": name, "text": text }]

func strip_buffs(t: Dictionary) -> Array:
	var gone := []
	for k in ["hyped", "shield", "copium", "locked"]:
		if t["st"].has(k):
			t["st"].erase(k)
			gone.append(k)
	return [{ "t": "status", "u": t, "name": "humbled", "text": "%s is HUMBLED.%s" % [t["name"], " Their buffs are gone." if not gone.is_empty() else ""] }]

# ------------------------------------------------------------------ party
# what a team-up costs each member right now ("on some type shi" halves the next one)
func combo_cost(c: Dictionary) -> int:
	return int(ceil(c["cost"] * (0.5 if shi_discount else 1.0)))

func combos_for(m: Dictionary) -> Array:
	if party.size() < 2: return []
	var out := []
	for c in D.COMBOS:
		if not c["who"].has(m["id"]):
			continue
		var ok := true
		for id in c["who"]:
			var p := member(id)
			if p.is_empty() or p["hp"] <= 0 or p["meter"] < combo_cost(c):
				ok = false
		if ok:
			out.append(c)
	return out

func member(id: String) -> Dictionary:
	for p in party:
		if p["id"] == id:
			return p
	return {}

func talk_options(m: Dictionary) -> Array:
	var out := []
	for tid in def.get("talk", []):
		var T: Dictionary = D.TALK[tid]
		if T.get("who", "") != "" and T["who"] != m["id"]:
			continue
		if T.has("hide_if") and _any_flag(T["hide_if"]):
			continue
		var need: String = T.get("need", "")
		out.append({ "id": tid, "text": T["text"], "ok": need == "" or item_count(m["id"], need) > 0, "need": need })
	return out

func _make_faded(p: Dictionary) -> void:
	faded_ids[p["id"]] = true
	p["st"]["faded"] = 1

func item_count(id: String, k: String) -> int:
	return int(bags.get(id, {}).get(k, 0))

func total_items(k: String) -> int:
	var n := 0
	for id in bags:
		n += int(bags[id].get(k, 0))
	return n

# Story flags (e.g. hide "I'm the KING" if Skorn got crowned). Works without the Game autoload too (balance sim).
func _any_flag(names: Array) -> bool:
	var g = Engine.get_main_loop().root.get_node_or_null("Game") if Engine.get_main_loop() else null
	if g == null:
		return false
	for f in names:
		if g.flag(f):
			return true
	return false

func can_flee() -> bool:
	return not def.get("story", false)

func party_act(m: Dictionary, a: Dictionary, o: Dictionary = {}) -> Array:
	var ev := []
	match a["type"]:
		"defend":
			m["defending"] = true
			for c in m["cds"]:
				m["cds"][c] = maxi(0, m["cds"][c] - 1)
			ev.append({ "t": "say", "text": "%s braces. (Defending: half damage, enemies aim at %s, cooldowns tick faster.)" % [m["name"], m["name"]], "sound": "throw", "ms": 1300 })
			ev += add_meter(m, 12)
			return ev
		"item":
			return use_item(m, a["item"], a["target"])
		"flee":
			return flee(m, o.get("roll", rng.randi_range(1, 6)))
		"talk":
			return talk(m, a["talk"])
		"help":
			return help_up(m, a["target"])

	# Misfires: midtocy trip or beezy buzz
	var buzzed: bool = m["st"].has("buzzed")
	m["st"].erase("buzzed")
	if a["type"] == "move" and a["slot"] != "ult":
		if m["tripping"] and rnd() < 0.22:
			return [{ "t": "misfire", "u": m, "text": pick(D.TRIP_MISFIRES[m["id"]]), "sound": "miss", "ms": 1500 }]
		if buzzed and rnd() < 0.25:
			return [{ "t": "misfire", "u": m, "text": pick(D.BUZZED_MISFIRES[m["id"]]), "sound": "miss", "ms": 1500 }]
	var crit := 2.0 if m["tripping"] and rnd() < 0.2 else 1.0
	if crit > 1.0:
		ev.append({ "t": "float", "u": m, "text": "TWEAK CRIT!", "color": "#ff6bd5", "sound": "crit" })
	var timing: String = o.get("timing", "")
	if timing != "":
		stats["timed"] += 1
		if timing == "perfect": stats["perfects"] += 1
		if timing == "good": stats["goods"] += 1
	var h := { "attacker": m, "timing": timing, "crit": crit }

	_cur_move = a["combo"]["name"] if a["type"] == "combo" else (m["moves"][a["slot"]]["name"] if a["type"] == "move" else "")
	if _cur_move != "":
		var ms: Dictionary = stats["moves"].get(_cur_move, { "n": 0, "dmg": 0 })
		ms["n"] += 1
		stats["moves"][_cur_move] = ms
	if a["type"] == "combo":
		if lore_nerf and a["combo"]["id"] == "loreslap" and rnd() < D.LORE_FIZZLE:
			for id in a["combo"]["who"]:
				member(id)["meter"] -= combo_cost(a["combo"])
			shi_discount = false
			return ev + [{ "t": "misfire", "u": m, "text": "Deloye left Xylo on read. Skorn slaps nothing.", "sound": "miss", "ms": 1500 }] # DRAFT
		ev += do_combo(m, a["combo"], a["target"], h)
	else:
		var move: Dictionary = m["moves"][a["slot"]]
		if move.has("cd"):
			m["cds"][a["slot"]] = move["cd"] + (1 if a["slot"] == "special" and m["st"].has("bricked") else 0)
		if a["slot"] == "special":
			m["st"].erase("bricked")
		if lore_nerf and m["id"] == "xylo" and move.get("fx", "") == "lore" and rnd() < D.LORE_FIZZLE:
			return ev + [{ "t": "misfire", "u": m, "text": "Deloye left Xylo on read. The lore fizzles.", "sound": "miss", "ms": 1500 }] # DRAFT
		if a["slot"] == "ult":
			m["meter"] = 0
			ev += bark(m, "ult", 1.0)
		ev += do_move(m, move, a.get("target", {}), h, o)
	if hype > 0 and not (a["type"] == "move" and m["moves"][a["slot"]]["kind"] == "buff"):
		hype -= 1
	if timing == "perfect":
		ev += bark(m, "perfect", 0.3)
	return ev

func do_move(m: Dictionary, move: Dictionary, t: Dictionary, h: Dictionary, o: Dictionary) -> Array:
	var ev := []
	var timing: String = h.get("timing", "")
	match move["kind"]:
		"hit":
			var power: float = move["power"]
			var hm: Dictionary = h.merged({ "text": "%s uses %s on %s!" % [m["name"], move["name"], t["name"]], "sound": move.get("fx", "hit"), "brk": move.get("brk", 1.0) })
			# 11/26 setups and payoffs
			var pay: bool = move.get("payoff", false) and (t["st"].has("mogged") or t["st"].has("distracted") or t["st"].has("charm"))
			var stacks: int = t["st"].get("lore", 0) if move.get("lore_cash", false) else 0
			var was_cooked: bool = move.has("explode") and t["st"].has("cooked")
			if stacks > 0:
				power *= 1.0 + 0.25 * stacks
				t["st"].erase("lore")
				stats["payoffs"] += 1
				hm["text"] = "%s cashes in %d Lore Stack%s on %s!" % [m["name"], stacks, "" if stacks == 1 else "s", t["name"]] # DRAFT
			ev += damage_enemy(m, t, power, hm)
			if pay and t["hp"] > 0:
				stats["payoffs"] += 1
				ev.append({ "t": "say", "text": "%s slaps TWICE!" % m["name"], "sound": "slap", "ms": 500 }) # DRAFT
				ev += damage_enemy(m, t, move["power"], h.merged({ "text": "Second slap!", "sound": "slap", "brk": move.get("brk", 1.0) }))
			if was_cooked and t["hp"] > 0:
				stats["payoffs"] += 1
				ev += damage_enemy(m, t, move["explode"], { "text": "%s was already Cooked. %s EXPLODES!" % [t["name"], t["name"]], "sound": "explode", "shake": true }) # DRAFT
			if t["hp"] <= 0: return ev
			if move.get("distract", false):
				t["st"]["distracted"] = 1
				ev.append({ "t": "status", "u": t, "name": "distracted", "text": "%s is DISTRACTED. The next hit does +50%%." % t["name"] }) # DRAFT
			if move.get("lore_stack", false):
				t["st"]["lore"] = mini(3, t["st"].get("lore", 0) + 1)
				ev.append({ "t": "status", "u": t, "name": "lore", "text": "LORE STACK ×%d on %s." % [t["st"]["lore"], t["name"]], "ms": 700 }) # DRAFT
			if stacks > 0 and move.has("lorepill"):
				ev += apply_cc(t, "lorepill", 2)
			if move.has("charm") and rnd() < move["charm"] + (0.15 if timing == "perfect" else 0.0):
				ev += apply_cc(t, "charm")
			if move.has("mogged"):
				ev += apply_status(t, "mogged", move["mogged"], "%s is MOGGED. Insecure now. Takes 25%% more damage." % t["name"])
			if move.has("lorepill") and stacks == 0 and (timing == "perfect" or rnd() < move["lorepill"]):
				ev += apply_cc(t, "lorepill", 2)
			if move.has("cooked"):
				ev += apply_status(t, "cooked", move["cooked"], "%s is COOKED. On fire for a few turns." % t["name"])
			if move.has("delay"):
				t["next"] += delay(t) * move["delay"]
				ev.append({ "t": "say", "text": "%s gets bumped to the back of the line." % t["name"], "ms": 900 })
			if move.get("strip", false):
				ev += strip_buffs(t)
		"throw":   # 11/26: a d6 decides what he throws (D.THROW_TABLE)
			var r: int = o.get("throw_roll", rng.randi_range(1, 6))
			var T: Dictionary = D.THROW_TABLE[r]
			var thing: String = T["thing"]
			ev.append({ "t": "dice", "rolls": [r], "text": "%s rolls to see what he grabs…" % m["name"] }) # DRAFT
			if T.has("self"):
				var d := mini(T["self"], m["hp"] - 1)
				m["hp"] -= d
				ev.append({ "t": "self_hit", "u": m, "amt": d, "hp": m["hp"], "text": T["text"] % d })
				return ev
			ev.append({ "t": "throw_thing", "u": m, "target": t, "thing": thing })
			ev += damage_enemy(m, t, T["power"], h.merged({ "text": "%s throws %s at %s! (rolled a %d)" % [m["name"], thing, t["name"], r], "brk": T.get("brk", 1.0), "shake": r == 6 }))
			if t["hp"] > 0 and T.get("downbad", false):
				ev += apply_status(t, "downbad", 2, "%s is DOWN BAD. Getting hit with %s was humbling. Deals half damage." % [t["name"], thing])
			if t["hp"] > 0 and T.has("cooked"):
				ev += apply_status(t, "cooked", T["cooked"], "%s is COOKED. On fire for a few turns." % t["name"])
			if t["hp"] > 0 and T.get("stun", false):
				ev += apply_cc(t, "stun")
		"crashout":
			var r: int = o.get("roll", 3)
			if r == 7:
				used67 = true
				ev.append({ "t": "six_seven" })
				for e in alive(enemies):
					ev += damage_enemy(m, e, 67, { "raw": true, "text": "The party does the 6-7 on %s!" % e["name"] })
				return ev
			if r == 1:
				var d := mini(10, m["hp"] - 1)
				m["hp"] -= d
				ev.append({ "t": "self_hit", "u": m, "amt": d, "hp": m["hp"], "text": "A 1. %s crashes out on HIMSELF. (-%d)" % [m["name"], d] })
				return ev
			var cpow: int = { 2: 18, 3: 18, 4: 30, 5: 30, 6: 40 }[r]
			ev += damage_enemy(m, t, cpow, h.merged({ "brk": move.get("brk", 1.0), "text": "%s crashes out on %s! (rolled a %d)" % [m["name"], t["name"], r], "sound": "slap", "shake": r == 6 }))
		"buff":
			hype = 3
			shi_discount = true
			ev.append({ "t": "hype", "u": m, "text": "%s screams \"on some type shi\"! The party is HYPED: next 3 attacks +25%% and double break damage, next team-up half price." % m["name"] })
			ev += add_meter(m, 15)
		"fullcrash":
			var rolls: Array = o.get("rolls", [3, 4])
			var a: int = rolls[0]
			var b: int = rolls[1]
			var mult := 1
			if a == 6 and b == 6 and o.get("accept67", false):
				used67 = true
				ev.append({ "t": "six_seven" })
				for e in alive(enemies):
					ev += damage_enemy(m, e, 67, { "raw": true, "text": "The party does the 6-7 on %s!" % e["name"] })
			elif a == 6 and b == 6:
				mult = 2
				ev.append({ "t": "say", "text": "DOUBLE SIXES. DOUBLE DAMAGE.", "sound": "crit", "ms": 1000 })
			if a == 1 and b == 1:
				var d := mini(15, m["hp"] - 1)
				m["hp"] -= d
				ev.append({ "t": "self_hit", "u": m, "amt": d, "hp": m["hp"], "text": "SNAKE EYES. %s crashes out so hard he hurts himself. (-%d)" % [m["name"], d] })
			if t["hp"] > 0:
				ev += damage_enemy(m, t, 7 * (a + b) * mult, h.merged({ "text": "%s FULLY crashes out on %s! (%d + %d)" % [m["name"], t["name"], a, b], "shake": true }))
			if t["hp"] > 0:
				ev += strip_buffs(t)
		"mogsupreme":
			ev.append({ "t": "mog_supreme", "u": m })
			for e in alive(enemies):
				ev += damage_enemy(m, e, move["power"], h.merged({ "text": "MOG SUPREME hits %s!" % e["name"], "sound": "mog" }))
				if e["hp"] > 0:
					e["st"]["mogged"] = 3
					e["st"]["blind"] = 1
					ev.append({ "t": "status", "u": e, "name": "mogged", "text": "%s is MOGGED and BLINDED." % e["name"] })
		"chudout":
			ev.append({ "t": "chud_out", "u": m, "target": t })
			var locked := not can_cc(t)
			ev += damage_enemy(m, t, move["power"] + (15 if locked else 0), h.merged({ "text": "%s CHUDS OUT and sits on %s!" % [m["name"], t["name"]], "sound": "sit", "shake": true }))
			if t["hp"] > 0:
				if locked:
					ev.append({ "t": "say", "text": "%s is Locked In, so he doesn't lose a turn. But it hurt extra." % t["name"], "ms": 1200 })
				else:
					ev += apply_cc(t, "stun")
		"healall":
			ev.append({ "t": "say", "text": "%s sprays the good conditioner everywhere. Smells like success." % m["name"], "sound": "sparkle", "ms": 900 })
			for p in alive(party):
				var amt := heal_amt(p, move["heal"])
				p["hp"] += amt
				for k in ["gouged", "bricked", "buzzed", "flattened"]:
					p["st"].erase(k)
				ev.append({ "t": "heal", "u": p, "amt": amt, "hp": p["hp"], "quick": true })
		"healone":
			ev += _heal_member(m, t, move["heal"], move.get("say", "%s tosses %s a Beezy.") % [m["name"], t["name"]])
		"beam":   # Mattias (ally) ult: hits every enemy, strips buffs
			for e in alive(enemies):
				ev += damage_enemy(m, e, move["power"], h.merged({ "text": "%s: %s hits %s!" % [m["name"], move["name"], e["name"]], "sound": "blast", "shake": true }))
				if e["hp"] > 0:
					ev += strip_buffs(e)
		"rally", "union":
			ev.append({ "t": "rally", "u": m, "count": move["hits"] })
			for i in move["hits"]:
				var list := alive(enemies)
				if list.is_empty(): break
				var e: Dictionary = pick(list)
				ev += damage_enemy(m, e, move["power"], h.merged({ "quick": true, "text": "A goblin bonks %s!" % e["name"] if i == 0 else "", "sound": "bonk" }))
			if move["kind"] == "union":
				for e in alive(enemies):
					ev += apply_status(e, "downbad", 2, "%s is DOWN BAD. That was a lot of goblins." % e["name"])
	return ev

# Help Up (11/26): spend your turn pulling a Downed teammate back up
func help_up(m: Dictionary, t: Dictionary) -> Array:
	if t["hp"] > 0 or t.get("dead", false):
		return [{ "t": "say", "text": "Too late for that.", "ms": 900 }]
	t["hp"] = maxi(1, int(round(t["max_hp"] * D.BALANCE["help_up"])))
	t["down"] = false
	t["next"] = now + delay(t) * 0.6
	var ev := [{ "t": "revive", "u": t, "hp": t["hp"], "text": "%s drags %s back up. (%d %s)" % [m["name"], t["name"], t["hp"], t["P"]["hp_label"]] }] # DRAFT
	ev += add_meter(m, 10)
	return ev

func heal_amt(p: Dictionary, amt: int) -> int:
	if p["st"].has("gouged"):
		amt = int(round(amt / 2.0))
	return mini(amt, p["max_hp"] - p["hp"])

func _heal_member(_m: Dictionary, t: Dictionary, amt: int, text: String) -> Array:
	var ev := []
	if t.get("dead", false):
		return [{ "t": "say", "text": "%s is dead. Too late for this fight." % t["name"], "ms": 1000 }] # DRAFT
	if t["hp"] <= 0:
		t["down"] = false
		t["hp"] = mini(t["max_hp"], amt)
		t["meter"] = 0
		t["st"] = {}
		t["next"] = now + delay(t) * 0.6
		ev.append({ "t": "revive", "u": t, "hp": t["hp"], "text": "%s %s is back! (%d %s)" % [text, t["name"], t["hp"], t["P"]["hp_label"]] })
	else:
		var healed := heal_amt(t, amt)
		t["hp"] += healed
		ev.append({ "t": "heal", "u": t, "amt": healed, "hp": t["hp"], "text": "%s +%d %s.%s" % [text, healed, t["P"]["hp_label"], " (Price Gouged: half healing)" if t["st"].has("gouged") else ""] })
	return ev

func do_combo(m: Dictionary, c: Dictionary, t: Dictionary, h: Dictionary) -> Array:
	var ev := []
	var members := []
	var cost := combo_cost(c)
	shi_discount = false
	stats["combos"] += 1
	for id in c["who"]:
		var p := member(id)
		members.append(p)
		p["meter"] -= cost
		if not is_same(p, m):
			p["next"] += delay(p) * 0.5
	ev.append({ "t": "combo", "combo": c, "members": members, "target": t })
	if c["id"] == "loreslap":
		for i in c["hits"]:
			if t["hp"] <= 0: break
			ev += damage_enemy(m, t, c["power"], h.merged({ "quick": true, "text": "Xylo reads. Skorn slaps on every comma." if i == 0 else "", "sound": "slap" }))
		if t["hp"] > 0:
			ev += apply_cc(t, "lorepill", c["lorepill"])
	elif c.get("aoe", false):
		for e in alive(enemies):
			ev += damage_enemy(m, e, c["power"], h.merged({ "text": "%s hits %s!" % [c["name"], e["name"]], "sound": "fire" }))
			if e["hp"] > 0 and c.has("cooked"):
				e["st"]["cooked"] = c["cooked"]
		ev.append({ "t": "say", "text": "Everything is COOKED. Lykor's hair is fine. Somehow.", "ms": 1000 })
	else:
		ev += damage_enemy(m, t, c["power"], h.merged({ "text": "%s!" % c["name"], "shake": true }))
		if t["hp"] > 0 and c.has("mogged"):
			ev += apply_status(t, "mogged", c["mogged"], "%s is MOGGED." % t["name"])
	if c.has("heal"):
		for p in alive(party):
			var amt := mini(c["heal"], p["max_hp"] - p["hp"])
			p["hp"] += amt
			ev.append({ "t": "heal", "u": p, "amt": amt, "hp": p["hp"], "quick": true })
	return ev

func use_item(m: Dictionary, k: String, t: Dictionary) -> Array:
	var it: Dictionary = D.ITEMS[k]
	if t.get("dead", false) and not it.get("faded", false):   # (the view doesn't offer dead targets; this is a guard)
		return [{ "t": "say", "text": "%s is dead. Too late for this fight." % t["name"], "ms": 1000 }]
	bags[m["id"]][k] -= 1   # from the user's own bag
	stats["items"] += 1
	var ev := [{ "t": "item", "u": m, "target": t, "item": k }]
	if it.get("faded", false):   # the joint: the whole party, for the rest of this fight
		ev.append({ "t": "say", "text": "%s sparks it up and passes it around." % m["name"], "sound": "sparkle", "ms": 1400 }) # DRAFT
		for p in alive(party):
			_make_faded(p)
			ev.append({ "t": "status", "u": p, "name": "faded", "text": "%s is FADED." % p["name"], "quiet": true })
		return ev
	if it.has("meter"):   # 11/26 fight items: energy drink (meter), mouthwash (cleanse), bubble wrap (absorb)
		if t["hp"] <= 0:
			return ev + [{ "t": "say", "text": "%s is Downed. That won't help right now." % t["name"], "ms": 900 }] # DRAFT
		ev.append({ "t": "say", "text": "%s chugs a %s. Eyes wide open." % [t["name"], it["name"]], "sound": "gulp", "ms": 900 }) # DRAFT
		return ev + add_meter(t, it["meter"])
	if it.get("cleanse", false):
		if t["hp"] <= 0:
			return ev + [{ "t": "say", "text": "%s is Downed. That won't help right now." % t["name"], "ms": 900 }]
		for c in ["gouged", "bricked", "buzzed", "flattened", "poisoned"]:
			t["st"].erase(c)
		var ch := heal_amt(t, it["heal"])
		t["hp"] += ch
		ev.append({ "t": "heal", "u": t, "amt": ch, "hp": t["hp"], "text": "%s gargles the %s. Debuffs gone. (+%d)" % [t["name"], it["name"], ch] }) # DRAFT
		return ev
	if it.has("wrap"):
		if t["hp"] <= 0:
			return ev + [{ "t": "say", "text": "%s is Downed. That won't help right now." % t["name"], "ms": 900 }]
		t["st"]["wrapped"] = it["wrap"]
		ev.append({ "t": "status", "u": t, "name": "wrapped", "text": "%s is wrapped in Bubble Wrap. Soaks the next %d damage." % [t["name"], it["wrap"]] }) # DRAFT
		return ev
	ev += _heal_member(m, t, it["heal"], "%s has a %s." % [t["name"], it["name"]])
	if k == "beer" and t["hp"] > 0:
		t["st"]["buzzed"] = 1
		ev.append({ "t": "status", "u": t, "name": "buzzed", "text": "%s is a little Buzzed." % t["name"], "quiet": true })
	return ev

func flee(m: Dictionary, roll: int) -> Array:
	var ev := [{ "t": "dice", "u": m, "rolls": [roll], "text": "%s rolls to run… (needs 4+)" % m["name"] }]
	if roll >= 4:
		ended = "fled"
		ev.append({ "t": "fled", "text": "The party RUNS. Skorn is somehow the fastest." })
	else:
		ev.append({ "t": "say", "text": "%s trips over nothing. Didn't get away." % m["name"], "sound": "boing", "ms": 1200 })
	return ev

func talk(m: Dictionary, tid: String) -> Array:
	var T: Dictionary = D.TALK[tid]
	var ev := []
	var try_text: String = T["try"] % m["name"] if "%s" in T["try"] else T["try"]
	ev.append({ "t": "talk", "u": m, "text": try_text })
	if T.has("need"):
		bags[m["id"]][T["need"]] -= 1
	var chance: float = T["chance"]
	if T.has("bonus"):
		for e in alive(enemies):
			if e["st"].has(T["bonus"]):
				chance += 0.25
				break
	var won := rnd() < chance
	match T["kind"]:
		"end":
			if won:
				ended = "talked"
				ev.append({ "t": "talked", "text": T["win"] })
			else:
				ev.append({ "t": "say", "text": T["lose"], "sound": "awkward", "ms": 1500 })   # talk failed: record scratch
		"backfire":
			for e in alive(enemies):
				e["st"]["hyped"] = 1
				ev.append({ "t": "status", "u": e, "name": "hyped", "text": T["lose"] })
		"cc":
			if won:
				for e in alive(enemies):
					ev += apply_cc(e, T["status"], 2 if T["status"] == "lorepill" else 1)
				ev.append({ "t": "say", "text": T["win"], "ms": 1300 })
			else:
				ev.append({ "t": "say", "text": T["lose"], "sound": "awkward", "ms": 1400 })
		"itis":
			for e in alive(enemies):
				var amt := mini(40, e["max_hp"] - e["hp"])
				e["hp"] += amt
				ev.append({ "t": "heal", "u": e, "amt": amt, "hp": e["hp"], "text": T["win"], "sound": "gulp" })
				e["st"]["itis"] = 3
				e["sit_pending"] = false
				ev.append({ "t": "status", "u": e, "name": "itis", "text": "%s has THE ITIS. (70%% chance to doze off each turn.)" % e["name"] })
	return ev

# Party → enemy damage
func damage_enemy(m: Dictionary, e: Dictionary, base: float, o: Dictionary = {}) -> Array:
	if e["hp"] <= 0: return []
	var dmg := base
	var label := ""
	var timing: String = o.get("timing", "")
	var weak := ""     # "weak" / "resist" (11/26 damage types)
	var dist := false  # this hit cashed in a Distracted
	if not o.get("raw", false):
		dmg *= lvl * (1.25 if hype > 0 else 1.0) * o.get("crit", 1.0)   # (HYPED was ×1.5 before 11/26; it doubles break damage now)
		var dtype: String = "" if m.is_empty() else o.get("dtype", D.DTYPE.get(m.get("id", ""), ""))
		var W: Dictionary = D.WEAKNESS.get(e.get("ai", ""), {})
		if dtype != "" and W.get("weak", "") == dtype:
			dmg *= D.WEAK_MULT
			weak = "weak"
			stats["weak_hits"] += 1
		elif dtype != "" and W.get("resist", "") == dtype:
			dmg *= D.RESIST_MULT
			weak = "resist"
		if not m.is_empty() and e["st"].has("distracted"):
			e["st"].erase("distracted")
			dmg *= 1.5
			dist = true
		if not m.is_empty():   # gear damage bonuses stack with diminishing returns (Ebain 11/26: +65% gear trivialized Mattias)
			var pw: float = m["gear"].get("power", 0.0)
			dmg *= 1.0 + pw / (1.0 + pw * D.POWER_FALLOFF)
		if timing != "":
			dmg *= TIMING[timing]
			label = { "perfect": "PERFECT!", "good": "GOOD", "mid": "MID" }[timing]
	if e["st"].has("mogged"):
		dmg *= 1.25
	if e["st"].has("braced"):
		dmg *= 0.7
	if e["st"].has("broken"):
		dmg *= D.BREAK["dmg_mult"]
	if e["st"].has("guarded"):   # a shield buddy is covering them (11/26)
		dmg *= 0.5
	var d := maxi(1, int(round(dmg)))
	var ev := []
	if e["st"].has("shield"):
		var ab := mini(e["st"]["shield"], d)
		e["st"]["shield"] -= ab
		d -= ab
		if e["st"]["shield"] <= 0:
			e["st"].erase("shield")
		ev.append({ "t": "say", "text": "The Aura Shield absorbs %d.%s" % [ab, "" if e["st"].has("shield") else " It shatters!"], "sound": "sparkle", "ms": 800 })
	e["hp"] = maxi(0, e["hp"] - d)
	if not m.is_empty() and _cur_move != "" and stats["moves"].has(_cur_move):
		stats["moves"][_cur_move]["dmg"] += d
	var text: String = o.get("text", "")
	ev.append({ "t": "dmg", "u": e, "amt": d, "hp": e["hp"], "text": "%s (-%d)" % [text, d] if text != "" else "", "sound": o.get("sound", "hit"), "label": label, "shake": o.get("shake", false), "quick": o.get("quick", false), "weak": weak, "by": m.get("id", "") })
	if e.get("boss", false) and not m.is_empty() and e["hp"] > 0 and not e["st"].has("broken"):   # fill the break bar
		var B: Dictionary = D.BREAK
		e["brk"] += d * B["mult"] * o.get("brk", 1.0) * (B["perfect"] if timing == "perfect" else 1.0) * (B["distracted"] if dist else 1.0) * (B["hyped"] if hype > 0 else 1.0) * (B["weak"] if weak == "weak" else 1.0)
		if e["brk"] >= e["brk_max"]:
			ev += _break(e)
	if not m.is_empty():
		ev += add_meter(m, minf(15.0, d / 3.0) + (8.0 if timing == "perfect" else (4.0 if timing == "good" else 0.0)))
	if e["st"].has("copium") and d >= 25:
		e["st"].erase("copium")
		ev.append({ "t": "say", "text": "That broke his Copium.", "ms": 800 })
	if e.get("eat_pending", false) and d >= 30 and e["hp"] > 0:
		e["eat_pending"] = false
		ev.append({ "t": "say", "text": "%s drops his Chipotle Bowl! No snack for him." % e["name"], "sound": "miss", "ms": 1100 })
	if e["hp"] <= 0:
		if e["second_wind"]:
			e["second_wind"] = false
			e["hp"] = 10
			ev.append({ "t": "down", "u": e, "fake": true })
			ev.append({ "t": "revive", "u": e, "hp": e["hp"], "text": "%s gets back up. \"I NEED THIS JOB!\" (Second Wind)" % e["name"] })
		else:
			e["sit_pending"] = false
			e["eat_pending"] = false
			e["st"] = {}
			ev.append({ "t": "down", "u": e })
			if e.get("boss", false):   # his adds clock out (11/26)
				for x in alive(enemies):
					if x.get("minion", false):
						x["hp"] = 0
						ev.append({ "t": "down", "u": x, "text": "%s clocks out." % x["name"] }) # DRAFT
	elif e["phase"] == 1 and e["boss"] and e["hp"] <= e["max_hp"] * 0.5:
		e["phase_pending"] = true
	return ev

# Damage preview (11/26): roughly what a move/team-up does to t, MID..PERFECT. { lo, hi, weak, brk, notes, ok }
# ok = false: nothing to show (dice moves, heals). Mirrors damage_enemy without rolling anything.
func estimate(m: Dictionary, move: Dictionary, t: Dictionary) -> Dictionary:
	var kind: String = move.get("kind", "hit")
	var power: float = move.get("power", 0.0)
	var notes := []
	if kind in ["crashout", "fullcrash", "throw"]:
		return { "ok": false, "notes": ["dice roll"] }
	if not kind in ["hit", "mogsupreme", "chudout", "beam", "combo"] or power <= 0.0:
		return { "ok": false, "notes": [] }
	if kind == "chudout" and not can_cc(t): power += 15
	var stacks: int = t["st"].get("lore", 0) if move.get("lore_cash", false) else 0
	if stacks > 0:
		power *= 1.0 + 0.25 * stacks
		notes.append("cashes in %d Lore Stack%s" % [stacks, "" if stacks == 1 else "s"])
	var mult := lvl * (1.25 if hype > 0 else 1.0)
	var pw: float = m["gear"].get("power", 0.0)
	mult *= 1.0 + pw / (1.0 + pw * D.POWER_FALLOFF)
	var W: Dictionary = D.WEAKNESS.get(t.get("ai", ""), {})
	var dtype: String = D.DTYPE.get(m.get("id", ""), "")
	var weak := ""
	if dtype != "" and W.get("weak", "") == dtype:
		mult *= D.WEAK_MULT
		weak = "weak"
	elif dtype != "" and W.get("resist", "") == dtype:
		mult *= D.RESIST_MULT
		weak = "resist"
	var dist: bool = t["st"].has("distracted")
	if dist: mult *= 1.5
	if t["st"].has("mogged"): mult *= 1.25
	if t["st"].has("braced"): mult *= 0.7
	if t["st"].has("broken"): mult *= D.BREAK["dmg_mult"]
	if t["st"].has("guarded"): mult *= 0.5
	var hits := 1.0
	if move.get("payoff", false) and (t["st"].has("mogged") or dist or t["st"].has("charm")):
		hits = 2.0
		notes.append("slaps TWICE")
	if kind == "combo" and move.get("hits", 1) > 1:
		hits = move["hits"]
	var extra := 0.0
	if move.has("explode") and t["st"].has("cooked"):
		extra = move["explode"] * mult
		notes.append("EXPLODES (+%d)" % int(extra))
	var timed: bool = move.get("timed", kind in ["hit", "combo"])
	var lo := power * mult * hits * (0.9 if timed else 1.0) + extra
	var hi := power * mult * hits * (1.5 if timed else 1.0) + extra
	var brk := 0.0
	if t.get("boss", false) and t.has("brk_max") and not t["st"].has("broken"):
		var B: Dictionary = D.BREAK
		brk = lo * B["mult"] * move.get("brk", 1.0) * (B["distracted"] if dist else 1.0) * (B["hyped"] if hype > 0 else 1.0) * (B["weak"] if weak == "weak" else 1.0)
	if move.get("distract", false): notes.append("leaves them Distracted")
	if move.get("lore_stack", false): notes.append("+1 Lore Stack")
	return { "ok": true, "lo": int(round(lo)), "hi": int(round(hi)), "weak": weak, "brk": int(round(brk)), "brk_left": int(ceil(t.get("brk_max", 0.0) - t.get("brk", 0.0))), "notes": notes, "kills": lo >= t["hp"] }

# Turn-order preview (11/26): the timeline if `bumps` (unit key → extra delay) and `skips` (unit key → turns lost)
# happened. The view feeds it the hovered move's effects.
func preview_with(n: int, bumps: Dictionary, skips: Dictionary) -> Array:
	var sim := []
	for u in units():
		var sk := (1 if u["st"].has("stun") else 0) + (1 if u["st"].has("charm") else 0) + (1 if u["st"].has("flattened") else 0) + int(skips.get(u["key"], 0))
		sim.append({ "u": u, "next": u["next"] + float(bumps.get(u["key"], 0.0)), "order": u["order"], "skips": sk })
	var out := []
	while out.size() < n and not sim.is_empty():
		sim.sort_custom(_sort)
		var s2: Dictionary = sim[0]
		out.append({ "u": s2["u"], "skip": s2["skips"] > 0, "moved": bumps.has(s2["u"]["key"]) or skips.has(s2["u"]["key"]) })
		if s2["skips"] > 0: s2["skips"] -= 1
		s2["next"] += delay(s2["u"])
	return out

# The break bar is full: he's BROKEN (loses his next turn, takes extra damage till then, cancels any wind-up)
func _break(e: Dictionary) -> Array:
	stats["breaks"] += 1
	e["brk"] = 0.0
	e["brk_max"] *= D.BREAK["grow"]
	e["st"]["broken"] = 1
	for k in ["sit_pending", "eat_pending", "sale_pending", "stampede_pending"]:
		e[k] = false
	_drop_plan(e)
	var ev := [{ "t": "broken", "u": e, "text": "%s is BROKEN! He loses his next turn and takes %d%% more damage till then. Everyone gets +%d meter." % [e["name"], int(round((D.BREAK["dmg_mult"] - 1.0) * 100)), D.BREAK["meter"]] }] # DRAFT
	for p in alive(party):
		ev += add_meter(p, D.BREAK["meter"])
	return ev

# Victory grade (Ebain 11/26: grades are back, with rewards). Score out of 100:
#   HP left (40) · timing: perfect = 1, good = 1/2 of every timed hit/block (25) · no knockouts (15, -5 each)
#   · style: team-ups, breaks, payoffs (5 each) + weakness hits (1 each), max 20
func grade() -> Dictionary:
	var hp := 0.0
	var mx := 0.0
	for p in party:
		hp += maxi(0, p["hp"])
		mx += p["max_hp"]
	var hp_pts := 40.0 * hp / maxf(1.0, mx)
	var t_pts := 12.0
	if stats["timed"] > 0:
		t_pts = 25.0 * (stats["perfects"] + 0.5 * stats["goods"]) / float(stats["timed"])
	var ko_pts := maxf(0.0, 15.0 - 5.0 * stats["kos"])
	var style_pts := minf(20.0, 5.0 * (stats["combos"] + stats["breaks"] + stats["payoffs"]) + stats["weak_hits"])
	var score := hp_pts + t_pts + ko_pts + style_pts
	var g: Dictionary = D.GRADES[D.GRADES.size() - 1]
	for G in D.GRADES:
		if score >= G["min"]:
			g = G
			break
	return { "letter": g["letter"], "score": int(round(score)), "gold": g["gold"], "xp": g["xp"], "color": g["color"],
		"hp": int(round(hp_pts)), "timing": int(round(t_pts)), "kos": int(round(ko_pts)), "style": int(round(style_pts)) }

# ------------------------------------------------------------------ chaos (very rare)
func roll_chaos() -> Array:
	if bolt_pending:
		return _dulbmeethus_bolt()
	if chaos_used or rnd() > 0.015:
		return []
	var pool := D.CHAOS.filter(func(c): return (not c.has("only_in") or c["only_in"].has(key)) and (not c.has("not_in") or not c["not_in"].has(key)))
	var c: Dictionary = pick(pool)
	chaos_used = true
	var ev := [{ "t": "chaos", "c": c }]
	match c["id"]:
		"beezy":
			var list := alive(party)
			list.sort_custom(func(a, b): return float(a["hp"]) / a["max_hp"] < float(b["hp"]) / b["max_hp"])
			var t: Dictionary = list[0]
			var amt := mini(30, t["max_hp"] - t["hp"])
			t["hp"] += amt
			ev.append({ "t": "heal", "u": t, "amt": amt, "hp": t["hp"], "text": "…and throws %s a beezy. +%d. He keeps running." % [t["name"], amt] })
		"dulbmeethus":
			var t: Dictionary = pick(alive(party))
			t["meter"] = 100
			ev.append({ "t": "meter_full", "u": t, "text": "Dulbmeethus blesses %s. Meter: FULL." % t["name"] })
		"mattias":
			for p in alive(party):
				ev += add_meter(p, 15)
			ev.append({ "t": "say", "text": "He leaves. Everyone feels weirdly motivated. (+15 meter)", "ms": 1400 })
		"rock":
			var t: Dictionary = pick(alive(enemies))
			ev += damage_enemy({}, t, 25, { "raw": true, "text": "It lands on %s." % t["name"], "sound": "sit", "shake": true })
	return ev

# "Y'all could hear me doe?" + a lightning strike on the whole enemy side. Regular enemies drop; bosses lose 40%.
func _dulbmeethus_bolt() -> Array:
	bolt_pending = false
	chaos_used = true
	var ev := [{ "t": "chaos", "c": D.BOLT_EVENT }, { "t": "lightning", "us": alive(enemies) }]
	for e in alive(enemies):
		var amt: float
		if e["boss"]:
			amt = e["max_hp"] * BOLT_BOSS
		else:
			e["st"].erase("shield")
			e["st"].erase("braced")
			amt = e["hp"] / (1.25 if e["st"].has("mogged") else 1.0) + 1.0
		ev += damage_enemy({}, e, amt, { "raw": true, "text": "Smitten by Dulbmeethus.", "sound": "blast", "shake": true, "quick": true })
	return ev

# ------------------------------------------------------------------ enemies
func target(_e: Dictionary, mode := "weak") -> Dictionary:
	var list := alive(party)
	var defenders := list.filter(func(p): return p["defending"])
	if not defenders.is_empty() and rnd() < 0.7:
		return pick(defenders)
	if mode == "strong":
		list.sort_custom(func(a, b): return a["hp"] > b["hp"])
		return list[0]
	if mode == "random":
		return pick(list)
	# 11/26 smarter: regular enemies sometimes kick a Downed fighter (2 failed saves), everyone leans harder on the hurt
	if not _e.get("boss", false) and not downed().is_empty() and rnd() < D.ROLES["kick_downed"]:
		return pick(downed())
	var w := []
	var total := 0.0
	for p in list:
		var frac: float = float(p["hp"]) / p["max_hp"]
		var x: float = 1.0 + 3.0 * (1.0 - frac) + (2.0 if frac < 0.25 else 0.0)
		w.append(x)
		total += x
	var r := rnd() * total
	for i in list.size():
		r -= w[i]
		if r <= 0.0:
			return list[i]
	return list.back()

# Decide what the enemy does. Returns an intent the view animates and then resolves.
func enemy_plan(e: Dictionary) -> Dictionary:
	if e.has("planned"):   # foreseen by the Neuralink: keep the promise unless it can't happen any more
		var it: Dictionary = e["planned"]
		e.erase("planned")
		e["foresaw"] = false
		var ok: bool = not e.get("phase_pending", false)
		if ok and it.has("targets"):
			it["targets"] = it["targets"].filter(func(p): return p["hp"] > 0)
			ok = not it["targets"].is_empty()
		if ok and it.has("other"):
			ok = it["other"]["hp"] > 0
		if ok:
			return it
		e["turn"] -= 1
	e["turn"] += 1
	var ps := alive(party)
	var all := { "aoe": true, "targets": ps }

	if e.get("phase_pending", false):
		e["phase_pending"] = false
		e["phase"] = 2
		if e["ai"] == "giant":
			return { "kind": "phase", "text": "Diddy Chud Giant gets up. \"Aight. Bet.\" (He's faster now. And hungry.)", "bark": "phase" }
		if e["ai"] == "dulbers":
			e["disguise"] = pick(ps)["id"]
			if e["disguise"] in ["chief", "mattias"]: e["disguise"] = "skorn"
			e["disguise_turns"] = 2
			# 11/26: shapeshifting is free (he still gets his attack), and at the Mart he calls in his employees
			return { "kind": "phase", "text": "Dulbers SHAPESHIFTS… into %s?! (Bootleg version)" % D.PARTY[e["disguise"]]["name"], "bark": "phase", "disguise": e["disguise"], "free": true, "summon": def.has("adds") }
		if e["ai"] == "mattias":
			return { "kind": "phase", "text": "Metocin Mattias stops holding back. (Every hit lands harder now.)", "bark": "phase" }
		if e["ai"] == "rat_king":   # DRAFT
			return { "kind": "phase", "text": "King Nibbsworth III takes a bite of his own scepter. He's eating to win now.", "bark": "phase" }

	# Boss buffs (Ebain 11/24: "think of more buffs bosses can do"). Texts are # DRAFT.
	if e.get("boss", false):
		if e["hp"] < e["max_hp"] * 0.3 and not e.get("last_stand", false):   # once: refuses to lose
			e["last_stand"] = true
			return { "kind": "buff", "status": "hyped", "turns": 1,
				"text": "%s refuses to lose like this. HYPED UP: the next hit does double damage." % e["name"] } # DRAFT
		var every: int = 7 if e["ai"] == "mattias" else 5
		if e["turn"] % every == every - 1 and not e["st"].has("braced"):
			var why: String = { "giant": "Diddy Chud flexes his big back.", "dulbers": "Dulbers pins on a MANAGER badge.",
				"mattias": "Mattias adjusts his robe. Unbothered.", "rat_king": "The Rat King hides behind his cape." }.get(e["ai"], "%s braces." % e["name"]) # DRAFT
			return { "kind": "buff", "status": "braced", "turns": 2, "text": why + " BRACED: takes 30% less damage for 2 turns." }

	if mods.get("enemy_tripping", false) and rnd() < 0.3:
		if rnd() < 0.5:
			return { "kind": "self_hurt", "power": 10, "text": "%s punches a rock that insulted him." % e["name"] }
		return { "kind": "nothing", "text": "%s yells \"WHY IS THE SKY SO LOUD\" and forgets to attack." % e["name"] }

	if e["ai"] == "goblin":
		var buddies := alive(enemies).filter(func(x): return not is_same(x, e) and not x["st"].has("hyped"))
		if not buddies.is_empty() and rnd() < 0.18:
			return { "kind": "hype", "other": pick(buddies), "text": "%s yells \"LET'S GOOOO!\"" % e["name"], "bark": "hype" }
		var t := target(e)
		return { "kind": "hit", "name": "Spoon Bonk", "power": 9, "targets": [t], "text": "%s bonks %s with a spoon!" % [e["name"], t["name"]], "sound": "bonk" }

	# Enemy roles (11/26). Texts: # DRAFT
	if e["ai"] == "shaman":   # heals whoever's hurt, otherwise zaps
		var hurt_foes := alive(enemies).filter(func(x): return x["hp"] < x["max_hp"] * 0.7 and not is_same(x, e))
		if hurt_foes.is_empty() and e["hp"] < e["max_hp"] * 0.5: hurt_foes = [e]
		if not hurt_foes.is_empty() and not e.get("healed_last", false):   # heals every other turn at most
			e["healed_last"] = true
			hurt_foes.sort_custom(func(a, b): return float(a["hp"]) / a["max_hp"] < float(b["hp"]) / b["max_hp"])
			var who_h: String = "himself" if is_same(hurt_foes[0], e) else hurt_foes[0]["name"]
			return { "kind": "heal_ally", "target": hurt_foes[0], "amt": D.ROLES["shaman_heal"], "text": "%s waves a stick over %s. Somehow that heals." % [e["name"], who_h] }
		e["healed_last"] = false
		var t0 := target(e)
		return { "kind": "hit", "name": "Stick Zap", "power": 10, "targets": [t0], "text": "%s zaps %s with a stick." % [e["name"], t0["name"]], "sound": "zap" }
	if e["ai"] == "shield":   # covers the most hurt buddy (half damage), otherwise bonks
		var others := alive(enemies).filter(func(x): return not is_same(x, e) and not x["st"].has("guarded"))
		if not others.is_empty() and rnd() < 0.4:
			others.sort_custom(func(a, b): return float(a["hp"]) / a["max_hp"] < float(b["hp"]) / b["max_hp"])
			return { "kind": "guard", "target": others[0], "text": "%s jumps in front of %s. GUARDED: half damage for 2 turns." % [e["name"], others[0]["name"]] }
		var t1 := target(e)
		return { "kind": "hit", "name": "Shield Bash", "power": 11, "targets": [t1], "text": "%s shield-bashes %s." % [e["name"], t1["name"]], "sound": "bonk" }
	if e["ai"] == "bomber":   # lights a fuse, next turn it goes off on everyone
		var bomb := _telegraph(e, "bomb", D.BOMB, all, "%s lights a fuse… (Next turn it blows up on everyone. Defend, block it, or stun/charm him first.)" % e["name"], "BOOM! %s's bomb goes off!" % e["name"])
		if not bomb.is_empty():
			return bomb
		var t2 := target(e)
		return { "kind": "hit", "name": "Firecracker", "power": 10, "targets": [t2], "text": "%s flicks a firecracker at %s." % [e["name"], t2["name"]], "sound": "fire" }
	if e["ai"] == "plague_rat":   # bite + poison
		var t3 := target(e)
		return { "kind": "hit", "name": "Plague Bite", "power": 9, "targets": [t3], "poison": 3, "text": "%s bites %s. That's not clean." % [e["name"], t3["name"]], "sound": "bonk" }
	if e["ai"] == "employee":   # Dulbers' adds at the Mart (11/26). Texts: # DRAFT
		var t := target(e, "random")
		return { "kind": "hit", "name": "Mop Swing", "power": 6, "targets": [t], "text": "%s swings a mop at %s! \"Cleanup on aisle YOU.\"" % [e["name"], t["name"]], "sound": "bonk" }

	# the rat cave (RUINS_PLAN.md). Move names/texts: # DRAFT
	if e["ai"] == "rat":
		var buddies := alive(enemies).filter(func(x): return not is_same(x, e) and not x["st"].has("hyped"))
		if not buddies.is_empty() and rnd() < 0.15:
			return { "kind": "hype", "other": pick(buddies), "text": "%s squeaks a war cry. SQUEAK SQUEAK!" % e["name"], "bark": "hype" }
		var t := target(e)
		if rnd() < 0.3:
			return { "kind": "hit", "name": "Ankle Nibble", "power": 7, "targets": [t], "text": "%s nibbles %s's ankle!" % [e["name"], t["name"]], "sound": "bonk" }
		return { "kind": "hit", "name": "Toothpick Poke", "power": 11, "targets": [t], "text": "%s pokes %s with a toothpick spear!" % [e["name"], t["name"]], "sound": "bonk" }

	if e["ai"] == "rat_king":
		var st := _telegraph(e, "stampede", D.STAMPEDE, all,
			"King Nibbsworth III whistles for the whole colony… (Next turn: a rat stampede. Defend, block it, or stun/charm him to cancel.)", # DRAFT
			"RAT STAMPEDE! Every rat in the cave runs over the party!") # DRAFT
		if not st.is_empty():
			return st
		if e["phase"] == 2 and e.get("corn", 0) < 2 and e["hp"] < e["max_hp"] * 0.4 and rnd() < 0.35:
			e["corn"] = e.get("corn", 0) + 1
			return { "kind": "eat", "amt": 45, "text": "King Nibbsworth III gnaws on the Corncob Scepter. Royal snack. (+45)" }
		if rnd() < 0.3:
			return all.merged({ "kind": "hit", "name": "Royal Decree", "power": 19, "text": "King Nibbsworth III: \"By royal decree… y'all are MID.\" It hurts everyone's feelings.", "sound": "roar" })
		var t := target(e)
		return { "kind": "hit", "name": "Corncob Bonk", "power": 32, "targets": [t], "text": "King Nibbsworth III bonks %s with the Corncob Scepter!" % t["name"], "sound": "slap" }

	if e["ai"] == "dulbers":
		var sale := _telegraph(e, "sale", D.SALE, all,
			"Dulbers: \"CLEARANCE SALE! EVERYTHING MUST GO!\" (Next turn he hits everyone HARD. Defend, block it, or stun/charm him to cancel.)", # DRAFT
			"EVERYTHING MUST GO! Dulbers hurls the whole store at the party!") # DRAFT
		if not sale.is_empty():
			return sale
		if e["phase"] == 2:
			e["disguise_turns"] -= 1
			if e["disguise_turns"] < 0:
				var opts := []
				for p in ps:
					if p["id"] != e["disguise"] and not p["id"] in ["chief", "mattias"]:
						opts.append(p["id"])
				if not opts.is_empty():
					e["disguise"] = pick(opts)
				e["disguise_turns"] = 1
				return { "kind": "phase", "text": "Dulbers shapeshifts into %s now." % D.PARTY[e["disguise"]]["name"], "disguise": e["disguise"], "quick": true, "free": true }
			if e["hp"] < e["max_hp"] * 0.35 and not e.get("cope_used", false) and rnd() < 0.3:
				e["cope_used"] = true
				return { "kind": "buff", "status": "copium", "turns": 3, "text": "Dulbers: \"I'm not losing, I'm just… restocking.\" (COPIUM: heals each turn. Hit him hard to break it.)" }
			if e["disguise"] == "skorn":
				var t := target(e)
				return { "kind": "hit", "name": "Diddy Slap (Bootleg)", "power": 30, "targets": [t], "text": "Bootleg Skorn slaps %s!" % t["name"], "sound": "slap" }
			if e["disguise"] == "lykor":
				var t := target(e)
				return { "kind": "hit", "name": "Hair Flip (Knockoff)", "power": 18, "targets": [t], "flatten": 0.45, "text": "Knockoff Lykor hair-flips at %s!" % t["name"], "sound": "sparkle" }
			return all.merged({ "kind": "hit", "name": "Eldritch Blast (Generic)", "power": 20, "text": "Generic Xylo blasts the whole party!", "sound": "blast" })
		var r := rnd()
		if total_items("beer") > 0 and e["hp"] < e["max_hp"] * 0.75 and e.get("stole", 0) < 2 and r < 0.22:
			e["stole"] = e.get("stole", 0) + 1
			return { "kind": "steal", "text": "Dulbers steals one of your Beezys and chugs it in front of you." }
		var lykor := member("lykor")
		if not lykor.is_empty() and lykor["hp"] > 0 and not e["st"].has("shield") and not e.get("shielded", false) and r < 0.35:
			e["shielded"] = true
			return { "kind": "shield", "amt": 35, "drain": lykor, "text": "Dulbers steals some of Lykor's aura and makes an AURA SHIELD out of it." }
		if rnd() < 0.62:
			var t := target(e)
			return { "kind": "hit", "name": "Price Gouge", "power": 30, "targets": [t], "gouge": true, "text": "Dulbers price-gouges %s! \"That'll be 30 HP, plus tax.\"" % t["name"], "sound": "slap" }
		return all.merged({ "kind": "hit", "name": "NO REFUNDS", "power": 18, "brick": true, "text": "Dulbers screams \"NO REFUNDS!\" It hurts everyone's ears.", "sound": "roar" })

	if e["ai"] == "giant":
		if e.get("sit_pending", false):
			e["sit_pending"] = false
			return all.merged({ "kind": "hit", "name": "SIT", "power": 44, "sit": true, "text": "DIDDY CHUD SITS ON EVERYONE!", "sound": "sit", "tex": e["E"]["sit_tex"] })
		if e.get("eat_pending", false):
			e["eat_pending"] = false
			return { "kind": "eat", "amt": 60, "text": "Diddy Chud eats an entire Chipotle Bowl. BIG BACK. (+60)" }
		e["tele"] = e.get("tele", 0) + 1
		if e["tele"] % 3 == 0:
			e["sit_count"] = e.get("sit_count", 0) + 1
			if e["phase"] == 2 and e["sit_count"] % 2 == 0:
				e["eat_pending"] = true
				return { "kind": "telegraph", "text": "Diddy Chud pulls out a Chipotle Bowl… (Hit him for 30+ or stun him to make him drop it!)", "status": "eat" }
			e["sit_pending"] = true
			return { "kind": "telegraph", "text": "Diddy Chud Giant is getting ready to SIT. (Defend, block it, or charm/stun him to make him fall!)", "tex": e["E"]["sit_tex"], "status": "sit" }
		if e["tele"] % 3 == 1:
			var t := target(e, "strong")
			return { "kind": "hit", "name": "Stomp", "power": 28, "targets": [t], "text": "Diddy Chud stomps on %s!" % t["name"], "sound": "stomp" }
		return all.merged({ "kind": "hit", "name": "Ground Pound", "power": 17, "text": "Diddy Chud pounds the ground!", "sound": "stomp" })
	if e["ai"] == "mattias":   # the sucker-punch boss (Ebain 11/24). All numbers: D.MATTIAS_BOSS
		var M: Dictionary = D.MATTIAS_BOSS
		var mul: float = M["phase2_mult"] if e["phase"] == 2 else 1.0
		if e["hp"] < e["max_hp"] * M["heal_below"] and not e.get("healed", false):
			e["healed"] = true
			return { "kind": "eat", "amt": M["heal"], "text": "Metocin Mattias takes a metocy. Calmly. (+%d)" % M["heal"] }
		if not e["st"].has("locked") and e["turn"] % 5 == 1:
			return { "kind": "buff", "status": "locked", "turns": M["lock_turns"], "text": "Metocin Mattias locks in. (Can't be charmed, stunned or Lore-pilled.)" }
		var ly := member("lykor")
		if not ly.is_empty() and ly["hp"] > 0 and not e["st"].has("shield") and e["turn"] % 4 == 3:
			return { "kind": "shield", "amt": M["shield"], "drain": ly, "text": "Mattias out-mogs Lykor and wears the aura like a cape. AURA SHIELD." }
		if rnd() < 0.6:
			var t := target(e)
			return { "kind": "hit", "name": "Metocy Bolt", "power": int(M["bolt"] * mul), "targets": [t], "text": "Mattias flicks a Metocy Bolt at %s." % t["name"], "sound": "blast" }
		return all.merged({ "kind": "hit", "name": "Pill Rain", "power": int(M["rain"] * mul), "brick": true, "text": "It rains little blue pills. They hurt. A lot.", "sound": "lore" })
	return { "kind": "nothing", "text": "%s waits." % e["name"] }

# Big telegraphed hits (Ebain 11/26, like the Giant's SIT): turn N winds up, his NEXT turn (not a bonus action in the
# same turn) lands it on everyone. T = { power, first, every } in combat_data. Returns {} when it's not time.
func _telegraph(e: Dictionary, id: String, T: Dictionary, all: Dictionary, warn: String, hit: String) -> Dictionary:
	var n: int = e.get("turns_taken", 0) + _ahead
	if e.get(id + "_pending", false):
		if n > e.get(id + "_at", 0):
			e[id + "_pending"] = false
			return all.merged({ "kind": "hit", "name": hit, "power": T["power"], "text": hit, "sound": "roar", "big": true })
		return {}   # same turn (his bonus action): just a normal attack
	if n >= T["first"] and (n - T["first"]) % T["every"] == 0 and e.get(id + "_last", -1) != n:
		e[id + "_pending"] = true
		e[id + "_at"] = n
		e[id + "_last"] = n
		return { "kind": "telegraph", "text": warn, "status": id }
	return {}

# Apply the intent. block = "perfect" | "good" | "mid" | ""
func enemy_resolve(e: Dictionary, it: Dictionary, block: String) -> Array:
	var ev := []
	if it.has("bark"):
		ev += bark(e, it["bark"], 1.0)
	elif it["kind"] == "hit":
		ev += bark(e, "taunt", 0.15)
	match it["kind"]:
		"phase":
			if it.has("disguise"): e["disguise"] = it["disguise"]
			ev.append({ "t": "phase", "u": e, "text": it["text"], "disguise": it.get("disguise", ""), "quick": it.get("quick", false) })
			if it.get("summon", false):
				ev += _summon(e)
			return ev
		"nothing":
			ev.append({ "t": "say", "text": it["text"], "ms": 1400 })
			return ev
		"self_hurt":
			return ev + damage_enemy({}, e, it["power"], { "raw": true, "text": it["text"], "sound": "stomp" })
		"hype":
			it["other"]["st"]["hyped"] = 1
			ev.append({ "t": "status", "u": it["other"], "name": "hyped", "text": "%s is HYPED UP. His next bonk does double damage." % it["other"]["name"] })
			return ev
		"telegraph":
			ev.append({ "t": "telegraph", "u": e, "text": it["text"], "tex": it.get("tex", ""), "status": it["status"] })
			return ev
		"heal_ally":   # goblin shaman (11/26)
			var ht: Dictionary = it["target"]
			if ht["hp"] <= 0:
				return ev + [{ "t": "say", "text": "%s waves the stick at nothing. Too late." % e["name"], "ms": 900 }] # DRAFT
			var ha := mini(int(round(it["amt"] * enemy_hp_mul)), ht["max_hp"] - ht["hp"])
			ht["hp"] += ha
			ev.append({ "t": "heal", "u": ht, "amt": ha, "hp": ht["hp"], "text": "%s (+%d)" % [it["text"], ha], "sound": "sparkle" })
			return ev
		"guard":   # shield goblin (11/26)
			var gt: Dictionary = it["target"]
			if gt["hp"] > 0:
				gt["st"]["guarded"] = 2
				ev.append({ "t": "status", "u": gt, "name": "guarded", "text": it["text"] })
			return ev
		"eat":
			var amt := mini(it["amt"], e["max_hp"] - e["hp"])
			e["hp"] += amt
			ev.append({ "t": "heal", "u": e, "amt": amt, "hp": e["hp"], "text": it["text"], "sound": "gulp" })
			return ev
		"steal":
			var victim := ""
			for id in bags:   # takes it from whoever has the most
				if victim == "" or item_count(id, "beer") > item_count(victim, "beer"):
					victim = id
			bags[victim]["beer"] -= 1
			var amt := mini(30, e["max_hp"] - e["hp"])
			e["hp"] += amt
			ev.append({ "t": "heal", "u": e, "amt": amt, "hp": e["hp"], "text": "%s (+%d) (%d left)" % [it["text"], amt, total_items("beer")], "sound": "gulp", "stole": true })
			return ev
		"shield":
			e["st"]["shield"] = it["amt"]
			it["drain"]["meter"] = maxi(0, it["drain"]["meter"] - 25)
			ev.append({ "t": "status", "u": e, "name": "shield", "text": "%s (Absorbs %d. Lykor loses 25 meter.)" % [it["text"], it["amt"]] })
			return ev
		"buff":
			e["st"][it["status"]] = it["turns"]
			ev.append({ "t": "status", "u": e, "name": it["status"], "text": it["text"] })
			return ev

	# Attacks
	if e["st"].has("blind"):
		e["st"].erase("blind")
		if rnd() < 0.6:
			ev.append({ "t": "miss", "u": e, "text": "%s swings at nothing. BLINDED." % e["name"], "sound": "miss" })
			return ev
	var mult: float = diff["dmg"] * dmg_scale * (boss_dmg if e.get("boss", false) else 1.0) * (1.1 if mods.get("enraged", false) else 1.0)
	if e.get("bonus_act", false):   # the phase-2 free action is a lighter one (the driver sets bonus_act, 11/26)
		mult *= D.BALANCE["bonus_mult"]
	if e["st"].has("hyped"):
		mult *= 2.0
		e["st"].erase("hyped")
	if e["st"].has("downbad"):
		mult *= 0.5
	if block != "":
		stats["timed"] += 1
		if block == "perfect": stats["perfects"] += 1
		if block == "good": stats["goods"] += 1
	ev.append({ "t": "attack", "u": e, "text": it["text"], "sound": it.get("sound", "hit"), "sit": it.get("sit", false), "block": block })
	if it.get("tex", "") != "":
		ev.append({ "t": "tex", "u": e, "tex": e["E"]["tex"] })   # back to standing after the sit
	var was_down := downed()   # (only those already Downed before this hit take a failed save)
	for p in it["targets"]:
		if p["hp"] <= 0:
			if not it.get("aoe", false) and p.get("down", false) and not p.get("dead", false) and was_down.has(p):
				ev.append({ "t": "say", "text": "%s kicks %s while they're down. Rude." % [e["name"], p["name"]], "sound": "hit", "ms": 900 }) # DRAFT
				p["saves"][1] += 1   # (a melee hit on the Downed = 2 fails, like BG3)
				ev += _downed_hit(p)
			continue
		if p["gear"].get("dodge", 0.0) > 0.0 and block != "perfect" and rnd() < p["gear"]["dodge"]:   # Neuralink
			ev.append({ "t": "say", "text": "%s saw that coming. Dodged!" % p["name"], "sound": "miss", "ms": 900 }) # DRAFT
			continue
		var dmg: float = it["power"] * mult * (BLOCK[block] if block != "" else 1.0)
		if p["defending"]:
			dmg *= 0.25 if it.get("sit", false) else 0.5
		ev += hurt(p, maxi(1, int(round(dmg))), block, it.get("aoe", false))
		if p["hp"] <= 0:
			continue
		var soft: bool = p["defending"] or block == "perfect" or block == "good"
		if it.get("gouge", false) and block != "perfect" and not p["gear"].get("gouge_proof", false):
			ev += party_status(p, "gouged", 2, "%s is PRICE GOUGED. Healing is halved for a bit." % p["name"])
		if it.get("sit", false) and not soft:
			ev += party_status(p, "flattened", 1, "%s is FLATTENED. Loses their next turn." % p["name"])
		if it.has("poison") and block != "perfect":
			ev += party_status(p, "poisoned", it["poison"], "%s is POISONED. Loses a bit of HP each turn." % p["name"]) # DRAFT
		if it.has("flatten") and not soft and rnd() < it["flatten"]:
			ev += party_status(p, "flattened", 1, "%s is too charmed by the knockoff hair. Loses their next turn." % p["name"])
	if it.get("aoe", false):   # the shockwave reaches the Downed too (11/26)
		for p in was_down:
			if not p.get("dead", false):
				ev += _downed_hit(p)
	if it.get("brick", false):
		var list := alive(party)
		if not list.is_empty():
			var p: Dictionary = pick(list)
			p["st"]["bricked"] = 1
			p["cds"]["special"] += 1
			ev.append({ "t": "status", "u": p, "name": "bricked", "text": "%s is BRICKED. Their special takes an extra turn." % p["name"] })
	return ev

# Adds (11/26): the fight's "adds" list joins mid-fight (Dulbers at the Mart, at half HP). They leave when the boss drops.
func _summon(boss: Dictionary) -> Array:
	var made := []
	for A in def["adds"]:
		var i := enemies.size()
		var x := {
			"side": "enemy", "key": "e%d" % i, "E": A, "name": A["name"], "tag": A.get("tag", ""), "ai": A["ai"],
			"boss": false, "order": 10 + i, "max_hp": int(round(A["hp"] * enemy_hp_mul)), "spd": A["spd"],
			"st": {}, "turn": 0, "phase": 1, "second_wind": false, "minion": true,
		}
		x["hp"] = x["max_hp"]
		x["next"] = now + delay(x) * 1.0
		enemies.append(x)
		made.append(x)
	return [{ "t": "summon", "u": boss, "us": made, "text": def.get("adds_text", "Reinforcements!") }]

func party_status(p: Dictionary, name: String, turns: int, text: String) -> Array:
	p["st"][name] = turns
	return [{ "t": "status", "u": p, "name": name, "text": text }]

func hurt(p: Dictionary, dmg: int, block: String, aoe: bool) -> Array:
	var ev := []
	if dmg > 0 and faded_ids.has(p["id"]):
		dmg = maxi(1, int(round(dmg * D.FADED["cut"])))
	if dmg > 0 and p.get("armor", 0) > 0:   # armor: a % cut per hit (D.ARMOR_PCT each, capped), never below 1. It was a flat
		# cut (10 − 3 = 7) until 11/26: stacked armor turned small hits into 1s and made Mattias easy (Ebain/Asar)
		dmg = maxi(1, int(round(dmg * (1.0 - minf(D.ARMOR_CAP, p["armor"] * D.ARMOR_PCT)))))
	if dmg > 0 and p["st"].has("wrapped"):   # Bubble Wrap soaks hits until it pops (11/26)
		var ab := mini(int(p["st"]["wrapped"]), dmg)
		p["st"]["wrapped"] -= ab
		dmg -= ab
		if p["st"]["wrapped"] <= 0:
			p["st"].erase("wrapped")
		ev.append({ "t": "say", "text": "The Bubble Wrap soaks %d.%s" % [ab, "" if p["st"].has("wrapped") else " *pop pop pop*"], "sound": "sparkle", "ms": 700 }) # DRAFT
	p["hp"] = maxi(0, p["hp"] - dmg)
	stats["dmg_taken"] += dmg
	ev.append({ "t": "hurt", "u": p, "amt": dmg, "hp": p["hp"], "block": block, "quick": aoe })
	ev += add_meter(p, dmg * 0.35 + (15.0 if block == "perfect" else (8.0 if block == "good" else 0.0)))
	if p["hp"] <= 0:
		stats["kos"] += 1
		p["meter"] = 0
		p["st"] = {}
		p["defending"] = false
		p["down"] = true
		p["saves"] = [0, 0]
		ev.append({ "t": "ko", "u": p })
		ev += bark(p, "ko", 0.8)
		var rest := alive(party)
		if not rest.is_empty():
			ev += bark(rest[0], "allyKo", 0.6)
			if total_items("beer") + total_items("bowl") == 0 and not emergency_given and not def.get("boss", false):   # (11/26: not in boss fights)
				emergency_given = true
				bags[rest[0]["id"]]["beer"] = 1
				ev.append({ "t": "say", "text": "Someone's down and you're out of items? Here — 1 Emergency Beezy (complimentary).", "sound": "grab", "ms": 1600 })
	elif not p["low_warned"] and p["hp"] < p["max_hp"] * 0.3:
		p["low_warned"] = true
		ev += bark(p, "lowhp", 0.8)
	elif not aoe:
		ev += bark(p, "hurt", 0.12)
	return ev

