# Keybinds: Settings → Controls. Rebind the main keyboard key of each action (controller buttons don't change).
# Saved in settings.cfg [keys] as physical keycodes. Game applies them at startup, BEFORE any Level runs
# _setup_input(): level.gd's _key() only adds its default keys when the action doesn't exist yet, so a rebound
# action keeps just the player's key (+ the extras below). Defaults here must match level.gd _setup_input().
class_name Keybinds
extends RefCounted

# [action, label, default key]
const ACTIONS := [
	["move_forward", "Move forward", KEY_W],
	["move_back", "Move back", KEY_S],
	["move_left", "Move left", KEY_A],
	["move_right", "Move right", KEY_D],
	["run", "Run (hold)", KEY_SHIFT],
	["interact", "Talk / use / pick", KEY_E],
	["switch", "Switch leader", KEY_Q],
	["party_menu", "Inventory", KEY_TAB],
	["map", "Map", KEY_M],
	["cam_left", "Turn camera left", KEY_LEFT],
	["cam_right", "Turn camera right", KEY_RIGHT],
	["tts", "Voices on/off", KEY_V],
]
const EXTRAS := { "interact": [KEY_SPACE, KEY_ENTER] }   # always kept on top of the main key
const RESERVED := [KEY_ESCAPE, KEY_F1, KEY_F11]          # pause, dev menu, fullscreen

static var custom := {}   # action -> physical keycode (only the ones the player changed)

static func default_of(action: String) -> int:
	for a in ACTIONS:
		if a[0] == action:
			return a[2]
	return KEY_NONE

static func key_of(action: String) -> int:
	return int(custom.get(action, default_of(action)))

static func key_name(k: int) -> String:
	var n := OS.get_keycode_string(k)
	return n if n != "" else "?"

static func load_from(cf: ConfigFile) -> void:
	custom.clear()
	if cf.has_section("keys"):
		for a in cf.get_section_keys("keys"):
			if default_of(a) != KEY_NONE:
				custom[a] = int(cf.get_value("keys", a))
	for a in custom:
		apply(a)

static func save_to(cf: ConfigFile) -> void:
	for a in custom:
		cf.set_value("keys", a, custom[a])

# Put the action's keyboard keys back to: main key + extras. Controller events are left alone.
static func apply(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			InputMap.action_erase_event(action, e)
	var keys: Array = [key_of(action)]
	for x in EXTRAS.get(action, []):
		if x != keys[0]:
			keys.append(x)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)

# Rebind. If another action already uses that key, it gets this action's old key (a swap). Returns the label
# of the action that got swapped ("" if none).
static func set_key(action: String, k: int) -> String:
	var old := key_of(action)
	var swapped := ""
	for a in ACTIONS:
		if a[0] != action and key_of(a[0]) == k:
			custom[a[0]] = old
			apply(a[0])
			swapped = a[1]
	custom[action] = k
	apply(action)
	return swapped

static func reset_all() -> void:
	custom.clear()
	for a in ACTIONS:
		apply(a[0])
