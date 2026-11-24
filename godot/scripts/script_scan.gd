# ScriptScan: reads the dialogue scripts at runtime for the Library (Voice Lines + Scrapbook), so new lines,
# recordings and story outcomes show up there without anyone keeping a second list.
#   ScriptScan.voice_lines()     → every recorded voice line: [{ "text", "who", "name", "cat", "path" }]
#   ScriptScan.outcome(id)       → for a story outcome id: { "choice": option text, "who", "name", "line", "path" }
# To scan a new script, add it to SCRIPTS. A recording no script uses still shows (text from voice_lines.gd, or
# from its file name), sorted by its voices/ folder.
class_name ScriptScan
extends RefCounted

const SCRIPTS := [
	"res://scripts/camp_script.gd", "res://scripts/trail_script.gd", "res://scripts/village_script.gd",
	"res://scripts/village_rooms_script.gd", "res://scripts/mart_script.gd", "res://scripts/pass_script.gd",
	"res://scripts/summit_script.gd", "res://scripts/ruins_script.gd", "res://scripts/combat/combat_data.gd",
]
# Voice Lines tabs: [tab label, speaker ids / voices folders in it]
const CATS := [
	["Skorn", ["skorn"]],
	["Lykor", ["lykor"]],
	["Xylo", ["xylo"]],
	["Goblins", ["goblin", "goblins", "chief", "goblins_asar"]],
	["Dulbers", ["dulbers", "dulbers_demon"]],
	["Mattias", ["mattias"]],
	["Diddy Chud", ["giant"]],
	["Narrator", ["narrator"]],
]

static var _lines: Array = []
static var _outcomes := {}
static var _done := false

static func cat_of(who_or_folder: String) -> String:
	for c in CATS:
		if who_or_folder in c[1]:
			return c[0]
	return "Others"

static func voice_lines() -> Array:
	_scan()
	return _lines

static func outcome(id: String) -> Dictionary:
	_scan()
	return _outcomes.get(id, {})

static func _scan() -> void:
	if _done:
		return
	_done = true
	var seen := {}   # file path -> true
	for p in SCRIPTS:
		if not ResourceLoader.exists(p):
			continue
		var scr: Script = load(p)
		for k in scr.get_script_constant_map():
			_walk(scr.get_script_constant_map()[k], seen)
	# recordings no script line uses (hand-added lines first: we know their text)
	for t in VoiceLines.LINES:
		var f: String = VoiceLines.LINES[t]
		var path: String = VoiceLines.DIR + (f if f.get_extension() != "" else f + ".mp3")
		if not seen.has(path) and ResourceLoader.exists(path):
			seen[path] = true
			_add(t, f.get_slice("/", 0), "", path, f.get_slice("/", 0))
	for k in VoiceIndex.LINES:
		var path: String = VoiceLines.DIR + VoiceIndex.LINES[k]
		if not seen.has(path) and ResourceLoader.exists(path):
			seen[path] = true
			var folder: String = VoiceIndex.LINES[k].get_slice("/", 0)
			var nice: String = VoiceIndex.LINES[k].get_file().get_basename().trim_prefix(folder + "_").replace("_", " ")
			_add(nice.capitalize() if nice.length() < 3 else nice.left(1).to_upper() + nice.substr(1), folder, "", path, folder)
	_lines.sort_custom(func(a, b): return a["cat"] < b["cat"] if a["cat"] != b["cat"] else a["text"] < b["text"])

static func _walk(v, seen: Dictionary) -> void:
	if v is Array:
		for x in v:
			_walk(x, seen)
	elif v is Dictionary:
		if v.has("line") and v["line"] is String:
			var st := VoiceLines.stream_for(v["line"])
			if st and not seen.has(st.resource_path):
				seen[st.resource_path] = true
				var who: String = str(v.get("who", "narrator"))
				_add(v["line"], who, str(v.get("name", "")), st.resource_path, st.resource_path.get_base_dir().get_file())
		if v.has("outcome") and not _outcomes.has(v["outcome"]):
			_outcomes[v["outcome"]] = _outcome_info(v)
		for k in v:
			if str(k) != "line":   # (some dicts have int keys)
				_walk(v[k], seen)

static func _add(text: String, who: String, name: String, path: String, folder: String) -> void:
	var c: Dictionary = Dialogue.CHARS.get(who, {})
	var nm: String = name if name != "" else str(c.get("name", folder.capitalize()))
	var cat := cat_of(who)
	if cat == "Others":
		cat = cat_of(folder)
	_lines.append({ "text": text, "who": who, "name": nm if nm != "" else "Narrator", "cat": cat, "path": path })

# The option's text, and the line said right after it (the first recorded one in the next few lines, else the first).
static func _outcome_info(opt: Dictionary) -> Dictionary:
	var out := { "choice": str(opt.get("text", "")), "who": "", "name": "", "line": "", "path": "" }
	var said: Array = []
	_collect_lines(opt.get("steps", []), said)
	var pick: Dictionary = {}
	for s in said.slice(0, 6):
		if s["who"] != "narrator" and VoiceLines.stream_for(s["line"]):
			pick = s
			break
	if pick.is_empty():
		for s in said:
			if s["who"] != "narrator":
				pick = s
				break
	if not pick.is_empty():
		var st := VoiceLines.stream_for(pick["line"])
		out["who"] = pick["who"]
		out["name"] = pick["name"] if pick["name"] != "" else str(Dialogue.CHARS.get(pick["who"], {}).get("name", ""))
		out["line"] = pick["line"]
		out["path"] = st.resource_path if st else ""
	return out

static func _collect_lines(v, out: Array) -> void:
	if out.size() > 12:
		return
	if v is Array:
		for x in v:
			_collect_lines(x, out)
	elif v is Dictionary:
		if v.has("line") and v["line"] is String:
			out.append({ "line": v["line"], "who": str(v.get("who", "narrator")), "name": str(v.get("name", "")) })
		elif v.has("steps"):
			_collect_lines(v["steps"], out)
