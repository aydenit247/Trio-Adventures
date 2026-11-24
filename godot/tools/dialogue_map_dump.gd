# Dialogue map, step 1 (Asar 11/24): dumps every dialogue script constant (ScriptScan.SCRIPTS) as JSON, with the voice
# file the game would play for each line. Run tools/dialogue_map/build.sh, which calls this twice (the second time to
# look up voices for the short lines build.py finds in the level code). Writes $DLG_DIR/dump.json (default /tmp/dlg).
extends SceneTree

func _initialize() -> void:
	_go.call_deferred()

func _voice(text: String) -> String:
	var st := VoiceLines.stream_for(text)
	return st.resource_path if st else ""

func _conv(v) -> Variant:
	if v is Array:
		var out := []
		for x in v:
			out.append(_conv(x))
		return out
	if v is Dictionary:
		if v.has("line") and v["line"] is String:
			var d := { "t": "line", "who": str(v.get("who", "narrator")), "text": v["line"], "voice": _voice(v["line"]) }
			for k in ["name", "mood", "thought", "portrait", "if"]:
				if v.has(k): d[k] = str(v[k])
			return d
		if v.has("do"):
			var d := { "t": "do", "id": str(v["do"]) }
			for k in v:
				if str(k) != "do": d[str(k)] = str(v[k])
			return d
		if v.has("choice"):
			var opts := []
			for o in v["choice"]:
				var od := { "text": str(o.get("text", "")), "steps": _conv(o.get("steps", [])) }
				for k in ["if", "outcome"]:
					if o.has(k): od[k] = str(o[k])
				opts.append(od)
			return { "t": "choice", "options": opts }
		if v.has("if") and v.has("steps"):
			return { "t": "if", "flag": str(v["if"]), "neg": false, "steps": _conv(v["steps"]) }
		if v.has("if_not") and v.has("steps"):
			return { "t": "if", "flag": str(v["if_not"]), "neg": true, "steps": _conv(v["steps"]) }
		var out := {}
		for k in v:
			out[str(k)] = _conv(v[k])
		return { "t": "dict", "items": out }
	if v is String:
		return { "t": "str", "text": v, "voice": _voice(v) }
	return { "t": "other", "text": str(v) }

func _dir() -> String:
	var d := OS.get_environment("DLG_DIR")
	return d if d != "" else "/tmp/dlg"

func _go() -> void:
	DirAccess.make_dir_recursive_absolute(_dir())
	var dump := { "scripts": {}, "extra": {}, "chars": {} }
	for p in ScriptScan.SCRIPTS:
		if not ResourceLoader.exists(p):
			continue
		var scr: Script = load(p)
		var m: Dictionary = scr.get_script_constant_map()
		var consts := {}
		for k in m:
			consts[k] = _conv(m[k])
		dump["scripts"][p.get_file()] = consts
	if FileAccess.file_exists(_dir() + "/extra_texts.json"):
		var arr = JSON.parse_string(FileAccess.get_file_as_string(_dir() + "/extra_texts.json"))
		for t in arr:
			dump["extra"][t] = _voice(t)
	for c in Dialogue.CHARS:
		var col = Dialogue.CHARS[c].get("color", Color.WHITE)
		dump["chars"][c] = { "name": str(Dialogue.CHARS[c].get("name", c)), "color": "#" + (col as Color).to_html(false) }
	# every recording on disk, so we can list mp3s no line uses
	var files := []
	for k in VoiceIndex.LINES:
		files.append(VoiceLines.DIR + VoiceIndex.LINES[k])
	for t in VoiceLines.LINES:
		var f: String = VoiceLines.LINES[t]
		files.append(VoiceLines.DIR + (f if f.get_extension() != "" else f + ".mp3"))
	dump["voice_files"] = files
	var f := FileAccess.open(_dir() + "/dump.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(dump, " "))
	print("DUMPED ", dump["scripts"].size(), " scripts")
	quit()
