# CombatTutorial (Ebain 11/26): an easy, one-idea-per-page guide to fights. Offered before your first fight
# (Game flag "combatTutorialSeen"), and replayable any time: Esc menu → Combat Tutorial, or H during a fight.
#   await CombatTutorial.show_over(level.hud).closed
# A/D or ←/→ turn pages, E = next, Esc / Q closes. Page text: # DRAFT (Ebain rewrites whatever he wants)
class_name CombatTutorial
extends Control

signal closed

const W := 860.0
const H := 560.0
const GOLD := "#ffd84a"
const GRN := "#7dff8a"
const RED := "#ff7a6a"

# [title, body (BBCode)]   # DRAFT
const PAGES := [
	["Fights 101",
	"Fights happen right where you're standing.\n\nThe [b]bar at the top[/b] is the turn order: the portrait on the left goes next. Faster fighters get more turns.\n\nEveryone has a [b]health bar[/b] and a [b]meter[/b] at the bottom. Enemies are listed top-right.\n\n[color=#c8c0b0]Tip: hover any status word (like MOGGED) to see what it does.[/color]"],
	["Your turn",
	"Pick what to do with [b]W/S[/b], [b]E[/b] to use it, [b]Q[/b] to go back.\n\n• [b]Main[/b]: always ready.\n• [b]Special[/b] and [b]Bonus[/b]: stronger, but the number next to them is how many turns until they're ready again.\n• [b]Ult[/b]: shows up when the meter is full.\n• [b]Team-ups[/b]: two or three of you at once.\n• [b]Items[/b]: Beezys and Chipotle Bowls heal (and revive).\n• [b]Defend[/b]: take half damage this round."],
	["Timed hits",
	"When you attack, a [color=#ffd84a][b]ring[/b][/color] shrinks onto the target.\n\nPress [b]E[/b] right when it lines up with the circle:\n\n• [color=#7dff8a][b]PERFECT[/b][/color]: 1.5× damage\n• [b]GOOD[/b]: 1.2× damage\n• Too early or late: [b]MID[/b] (0.9×)\n\n[color=#c8c0b0]Can't get the timing? Press [b]T[/b] to switch timed hits to AUTO.[/color]"],
	["Blocking",
	"When an enemy attacks, the ring shows up on [b]you[/b].\n\nPress [b]E[/b] on time to block:\n\n• [color=#7dff8a][b]PERFECT BLOCK[/b][/color]: take 65% less\n• [b]BLOCKED[/b]: take 30% less\n\nBlocking also fills your meter."],
	["Meter, ults and team-ups",
	"Hitting, blocking and getting hurt all fill your [b]meter[/b].\n\n• Full meter = your [b]Ult[/b] (FULL CRASH OUT, MOG SUPREME, CHUD OUT).\n• [b]Team-ups[/b] spend meter from two or three of you at once.\n• [color=#ff7a6a][b]Under 25% HP[/b][/color] your meter fills [b]twice as fast[/b]. Comebacks are real."],
	["Setups and payoffs",
	"The trio are better together. Set it up, then cash it in:\n\n• Lykor's [b]Hair Flip[/b] leaves them [b]DISTRACTED[/b]: the next hit does +50%.\n• Skorn's [b]Diddy Slap[/b] slaps [b]TWICE[/b] on anyone Mogged, Distracted or Charmed.\n• Xylo's [b]Eldritch Blast[/b] adds a [b]LORE STACK[/b] (up to 3). [b]Deloye Lore[/b] cashes them in: +25% each and a sure Lore-pill.\n• [b]Dragon Breath[/b] on someone already Cooked: they [b]explode[/b].\n• Lykor's [b]\"on some type shi\"[/b]: double break damage, and the next team-up costs half."],
	["Weak spots",
	"Every fighter hits with one type:\n\n• [b]Skorn[/b]: Physical\n• [b]Lykor[/b]: Aura\n• [b]Xylo[/b]: Lore\n\nUnder an enemy's name you'll see [color=#7dff8a][b]WEAK: …[/b][/color] or [color=#c9a0ff][b]RESISTS: …[/b][/color].\n\nWeak = [b]+30%[/b] damage (and it breaks them faster). Resists = 30% less. Send the right person."],
	["The break bar",
	"Bosses have a [color=#ffc23a][b]gold bar[/b][/color] under their health.\n\nEvery hit fills it. These fill it faster: big moves (Diddy Slap, Mog, Crash Out), [b]PERFECT[/b] hits, [b]Distracted[/b], [b]HYPED[/b], weak spots.\n\nWhen it's full he's [color=#ffc23a][b]BROKEN[/b][/color]: he [b]loses his next turn[/b], takes [b]+50%[/b] damage until then, and everyone gets meter.\n\n[b]Save your ults for that moment.[/b]"],
	["Watch out!",
	"Big attacks get announced a turn early: a [color=#ff7a6a][b]WATCH OUT[/b][/color] banner and a red word on the enemy (like CLEARANCE SALE).\n\nWhen you see it:\n• [b]Defend[/b], or\n• [b]block[/b] it on time, or\n• [b]stun or charm[/b] him first to cancel it (breaking him works too).\n\nIn phase 2, bosses can take a [b]bonus action[/b], so keep your health up."],
	["Downed, not dead",
	"At 0 HP you're [color=#ff7a6a][b]DOWNED[/b][/color], not out.\n\nOn your turn you roll a [b]d20[/b] (10 or more passes):\n• [b]3 passes[/b]: back up at 1 HP\n• [b]Nat 20[/b]: up at half HP, and you act\n• [b]3 fails[/b]: dead for the rest of the fight\n\nA teammate can [b]Help Up[/b] (uses their turn), or use a Beezy or Bowl on you.\n\nAfter the fight, everyone's back at 1 HP. Nobody stays dead."],
	["Grades",
	"Win a fight and you get a grade, from [color=#ffd84a][b]S[/b][/color] down to D, based on:\n\n• HP left\n• Timing (perfect hits and blocks)\n• No knockouts\n• Style: team-ups, breaks, combos and weak spots\n\n[color=#ffd84a][b]S[/b][/color]: +50% gold, +25% XP · [color=#7dff8a][b]A[/b][/color]: +25% gold, +10% XP · [b]B[/b]: +10% gold\n\n[color=#c8c0b0]Forget something? Esc → [b]Combat Tutorial[/b], or press [b]H[/b] in a fight.[/color]"],
]

var page := 0
var title_lbl: Label
var count_lbl: Label
var body: RichTextLabel
var dots: HBoxContainer
var prev_b: Button
var next_b: Button
var _at := 0

# Put the tutorial on top of `parent` (a HUD / CanvasLayer). Await `.closed`.
static func show_over(parent: Node) -> CombatTutorial:
	var t := CombatTutorial.new()
	parent.add_child(t)
	t._build()
	return t

# Ask before a player's first fight (once per save). Returns after the tutorial (or the "no").
static func offer_first(level: Node) -> void:
	if Game.flag("combatTutorialSeen"):
		return
	Game.set_flag("combatTutorialSeen")
	if level.shots_mode:   # automated tours: show the first page and move on
		var t := show_over(level.hud)
		await level.wait(0.6)
		await level.shot("combat_tutorial_1")
		t.page = 5
		t._render()
		await level.wait(0.3)
		await level.shot("combat_tutorial_6")
		t.close()
		return
	if await MenuUI.confirm(level.hud, "First fight! Want a quick tutorial on how fights work?\n(You can replay it any time: Esc → Combat Tutorial, or H in a fight.)", "Show me", "I'm good"): # DRAFT
		await show_over(level.hud).closed

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.panel(0.97))
	card.anchor_left = 0.5; card.anchor_right = 0.5; card.anchor_top = 0.5; card.anchor_bottom = 0.5
	card.offset_left = -W / 2; card.offset_right = W / 2; card.offset_top = -H / 2; card.offset_bottom = H / 2
	add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var kicker := UITheme.lbl("COMBAT TUTORIAL", 15, "faint")
	kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(kicker)
	count_lbl = UITheme.lbl("", 15, "faint")
	head.add_child(count_lbl)
	title_lbl = UITheme.lbl("", 34, "accent", UITheme.head_font())
	v.add_child(title_lbl)
	body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.scroll_active = true
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(W - 60.0, 0)
	body.add_theme_color_override("default_color", UITheme.c("text"))
	for k in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		body.add_theme_font_size_override(k, UITheme.fs(21))
	body.add_theme_font_override("bold_font", UITheme.row_font())
	body.add_theme_constant_override("line_separation", 5)
	v.add_child(body)
	dots = HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 7)
	v.add_child(dots)
	for i in PAGES.size():
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(10, 10)
		dots.add_child(d)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 20)
	v.add_child(foot)
	prev_b = UITheme.button("◀  Back", 17)
	prev_b.pressed.connect(func(): _turn(-1))
	foot.add_child(prev_b)
	foot.add_child(UITheme.lbl("A/D or ←/→ · E next · Esc close", 14, "faint"))
	next_b = UITheme.button("Next  ▶", 17)
	next_b.pressed.connect(_next)
	foot.add_child(next_b)
	var close_b := UITheme.button("Close", 17)
	close_b.pressed.connect(close)
	foot.add_child(close_b)
	MenuUI.stack.append(self)
	_at = Engine.get_process_frames()
	UITheme.play("page")
	_render()
	UITheme.pop_in(card)

func _render() -> void:
	title_lbl.text = PAGES[page][0]
	body.text = PAGES[page][1]
	body.scroll_to_line(0)
	count_lbl.text = "%d / %d" % [page + 1, PAGES.size()]
	for i in dots.get_child_count():
		(dots.get_child(i) as ColorRect).color = Color(GOLD) if i == page else Color(1, 1, 1, 0.25)
	prev_b.disabled = page == 0
	next_b.text = "Got it!" if page == PAGES.size() - 1 else "Next  ▶"

func _turn(d: int) -> void:
	var p := clampi(page + d, 0, PAGES.size() - 1)
	if p == page:
		UITheme.play("back")
		return
	page = p
	UITheme.play("page")
	_render()

func _next() -> void:
	if page == PAGES.size() - 1:
		close()
	else:
		_turn(1)

func close() -> void:
	UITheme.play("back")
	MenuUI.stack.erase(self)
	closed.emit()
	queue_free()

func _input(ev: InputEvent) -> void:
	if MenuUI.stack.is_empty() or MenuUI.stack.back() != self or Engine.get_process_frames() - _at < 2:
		return
	if not (ev is InputEventKey or ev is InputEventJoypadButton or ev is InputEventJoypadMotion):
		return
	var handled := true
	if ev.is_action_pressed("ui_left") or ev.is_action_pressed("move_left"):
		UITheme.key_nav(); _turn(-1)
	elif ev.is_action_pressed("ui_right") or ev.is_action_pressed("move_right"):
		UITheme.key_nav(); _turn(1)
	elif ev.is_action_pressed("interact") or ev.is_action_pressed("ui_accept"):
		_next()
	elif ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause") or (ev is InputEventKey and ev.pressed and ev.physical_keycode == KEY_Q) or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_B):
		close()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()
