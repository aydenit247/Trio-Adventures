# Continuity check: walks every dialogue list in village_rooms_script.gd under each throne outcome and flags lines that
# assume something that didn't happen (Skorn talking while he's on the throne, a chug-off that never happened, "your
# majesty" for an ex-king...). Run after editing village dialogue:
#   godot --headless --path godot --script res://tools/check_continuity.gd
# Add a rule here whenever you find a new kind of continuity bug.
extends SceneTree
var flags := {}
func lines(steps: Array, out: Array) -> void:
	for s in steps:
		if s.has("choice"):
			for o in s["choice"]:
				if not o.has("if") or flags.get(o["if"], false):
					lines(o["steps"], out)
		elif s.has("if"):
			if flags.get(s["if"], false): lines(s["steps"], out)
		elif s.has("if_not"):
			if not flags.get(s["if_not"], false): lines(s["steps"], out)
		elif s.has("line"):
			out.append([s.get("who", ""), s["line"]])
func _init():
	var R = load("res://scripts/village_rooms_script.gd")
	var paths := {
		"A speech": {}, "B chug won": { "chugWon": true }, "B chug lost": { "foreheadLoser": true },
		"C Skorn king": { "skornKing": true }, "D sneak": { "goblinAllies": true }, "E dethroned": { "lykorDethroned": true },
	}
	var bad := 0
	for pname in paths:
		flags = paths[pname]
		var all := []
		for k in R.get_script_constant_map():
			var v = R.get_script_constant_map()[k]
			if v is Array and not v.is_empty() and v[0] is Dictionary:
				lines(v, all)
		for l in all:
			var who: String = l[0]; var t: String = l[1].to_lower()
			var problem := ""
			if flags.get("skornKing", false) and who == "skorn": problem = "Skorn talks but he's on the throne"
			if not flags.get("chugWon", false) and not flags.get("foreheadLoser", false) and (t.find("chugged with") >= 0 or t.find("out-drank") >= 0 or t.find("passed out chugging") >= 0): problem = "mentions a chug-off that didn't happen"
			if (flags.get("skornKing", false) or flags.get("lykorDethroned", false)) and t.find("majesty") >= 0: problem = "calls ex-king 'majesty'"
			if t.find("happened to me for real") >= 0: problem = "Skorn claims Mart scam before the Mart"
			if problem != "":
				bad += 1
				print("  [%s] %s: %s  (%s)" % [pname, who, l[1].left(80), problem])
		print("%-14s %d lines checked" % [pname, all.size()])
	var D = load("res://scripts/combat/combat_data.gd")
	print("King's Decree hidden when crowned/dethroned: ", D.TALK["kings_decree"].get("hide_if", []))
	print("PROBLEMS: ", bad)
	quit()
