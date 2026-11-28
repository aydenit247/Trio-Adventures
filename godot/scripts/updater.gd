# In-game updater (Ebain 11/27, shipping polish). On the title screen the Windows build asks GitHub whether a newer build
# is up (the release `latest-windows` has a small version.json next to the zip, written by windows-build.yml). If there
# is one, the title menu gets an "Update available" row: it downloads just the new TrioAdventures.pck next to the game
# (as TrioAdventures.pck.new), writes a tiny update.bat that waits for the game to close, swaps the file in and starts
# the game again, then quits. Saves/settings live in AppData and aren't touched.
# Only runs in an exported Windows build with a real stamp (BuildStamp.COMMIT != "dev"). If the engine version changed
# (the .exe would need replacing too) it opens the release page instead.
class_name Updater
extends Node

signal checked(available: bool)
signal progress(frac: float)

const REPO := "aydenit247/Trio-Adventures"
const BASE := "https://github.com/" + REPO + "/releases/download/latest-windows/"
const PAGE := "https://github.com/" + REPO + "/releases/tag/latest-windows"

var info := {}            # version.json of the newest build
var available := false
var _http: HTTPRequest

static func enabled() -> bool:
	return OS.has_feature("windows") and OS.has_feature("template") and BuildStamp.COMMIT != "dev"

func check() -> void:
	if not enabled():
		checked.emit(false)
		return
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	add_child(_http)
	if _http.request(BASE + "version.json") != OK:
		checked.emit(false)
		return
	var r: Array = await _http.request_completed
	_http.queue_free()
	if r[0] != HTTPRequest.RESULT_SUCCESS or r[1] != 200:
		checked.emit(false)
		return
	var j = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
	if not (j is Dictionary) or str(j.get("commit", "")) == "":
		checked.emit(false)
		return
	info = j
	available = str(j["commit"]) != BuildStamp.COMMIT
	checked.emit(available)

func needs_full_download() -> bool:
	return str(info.get("engine", "")) != "" and str(info.get("engine", "")) != _engine()

static func _engine() -> String:
	var v := Engine.get_version_info()
	return "%d.%d.%d" % [v["major"], v["minor"], v["patch"]]

# Downloads the new .pck and restarts into it. Returns an error message, or "" (then the game quits).
func install() -> String:
	if needs_full_download():
		OS.shell_open(PAGE)
		return "This update needs a fresh download. The release page is open in your browser."
	var dir := OS.get_executable_path().get_base_dir()
	var exe := OS.get_executable_path().get_file()
	var pck := exe.get_basename() + ".pck"
	var tmp := dir.path_join(pck + ".new")
	_http = HTTPRequest.new()
	_http.download_file = tmp
	_http.download_chunk_size = 1 << 20
	add_child(_http)
	if _http.request(BASE + "TrioAdventures.pck") != OK:
		return "Couldn't start the download."
	var t := 0.0
	var done := { "r": null }
	_http.request_completed.connect(func(a, b, c, d): done["r"] = [a, b])
	while done["r"] == null:
		await get_tree().process_frame
		var total := _http.get_body_size()
		if total > 0:
			progress.emit(float(_http.get_downloaded_bytes()) / total)
	_http.queue_free()
	var res: Array = done["r"]
	if res[0] != HTTPRequest.RESULT_SUCCESS or res[1] != 200 or not FileAccess.file_exists(tmp):
		DirAccess.remove_absolute(tmp)
		return "Download failed. Check your internet and try again."
	var want := int(info.get("pck_size", 0))
	if want > 0:
		var f := FileAccess.open(tmp, FileAccess.READ)
		var got := f.get_length() if f else 0
		f = null
		if got != want:
			DirAccess.remove_absolute(tmp)
			return "Download was incomplete. Try again."
	var bat := dir.path_join("update.bat")
	var pid := OS.get_process_id()
	var f2 := FileAccess.open(bat, FileAccess.WRITE)
	if f2 == null:
		return "Can't write to the game folder. Move the game somewhere you can write to (like Documents)."
	f2.store_string("@echo off\r\ncd /d \"%s\"\r\n:wait\r\ntimeout /t 1 /nobreak >nul\r\ntasklist /fi \"PID eq %d\" | find \"%d\" >nul && goto wait\r\nmove /y \"%s\" \"%s\" >nul\r\nstart \"\" \"%s\"\r\n(goto) 2>nul & del \"%%~f0\"\r\n" % [dir, pid, pid, pck + ".new", pck, exe])
	f2.close()
	OS.create_process("cmd.exe", ["/c", bat])
	get_tree().quit()
	return ""
