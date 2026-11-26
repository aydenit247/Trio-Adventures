# The 5 Lost Deloye Lore Pages (DELOYE_PLAN.md, the secret Deloye Lore library). One per area, tucked somewhere odd.
# No map dot, no objective, the prompt only shows up close (1.5 m). Found pages are saved in Game.progress
# ("lostpage_<area>", across playthroughs, NOT part of the 100 completion points). All 5 → the village outhouse gets
# a flush handle (village.gd) → deloye_library.tscn.
# Level calls spawn() in _ready, interactable() in current_interactables(), process() every frame, and routes the
# "lost_page" action here (level.gd do_action).
class_name LostPages
extends RefCounted

const AREAS := ["camp", "trail", "village", "mart", "pass"]
const NAMES := { "camp": "the Camp", "trail": "Goblin Woods Trail", "village": "the Goblin Village", "mart": "the Metocy Mart", "pass": "the Mountain Pass" }
# Where each page hides (Level.area_key() → position). Odd but walkable spots.
const SPOTS := {
	"camp": Vector3(-7.6, 0, -6.4),      # behind Skorn's tent, half under a log
	"trail": Vector3(1.75, 0, -3.1),     # at the far (north) end of the troll bridge, tucked under it
	"village": Vector3(12.85, 0, 6.45),  # behind the outhouse (a sneaky nod)
	"mart": Vector3(295.0, 0, -2.45),   # in the shelf corner inside the shop (back-left)
	"pass": Vector3(-2.4, 0, -7.6),      # in a rock crack next to the sleeping giant
}
# What each page says (inventory → Quests). # DRAFT: Ebain writes the real ones.
const SNIPPETS := {
	"camp": "Deloye Lore, Chapter 4: The rock remained.",   # DRAFT
	"trail": "Chapter 77: Nothing happened here. It was beautiful.",   # DRAFT
	"village": "Chapter 312, section C: The wind blew. Then, crucially, it stopped.",   # DRAFT
	"mart": "Chapter 2,001: The prophecy foretold of a man. He was standing there.",   # DRAFT
	"pass": "Chapter 9,999: And so the universe was vast. The end. (To be continued.)",   # DRAFT
}
const PICKUP_BARKS := [   # Xylo, over his head, when a page is picked up. # DRAFT
	"A lost page. Deloye's handwriting. Unmistakable.",
	"Another one. The lore calls to me.",
	"Three pages. I can feel my brain expanding.",
	"Four. Something is down there. Somewhere.",
	"All five. ...Why do I suddenly need to use the outhouse?",
]
const HINT_BARK := "…I smell parchment."   # DRAFT: Xylo, when he's the leader and a page is within 8 m
const HINT_RANGE := 8.0
const PICK_RANGE := 1.5

static func _g():
	return Engine.get_main_loop().root.get_node("Game")

static func found(area: String) -> bool:
	return _g().progress.has("lostpage_" + area)

static func count() -> int:
	var n := 0
	for a in AREAS:
		if found(a):
			n += 1
	return n

static func has_all() -> bool:
	return count() >= AREAS.size()

static func _area(lv) -> String:
	var k: String = lv.area_key()
	return k if SPOTS.has(k) else ""

# Build the glowing parchment (only if this area has one and it isn't found yet).
static func spawn(lv) -> void:
	var a := _area(lv)
	if a == "" or found(a) or _g().title_mode:
		return
	var root := Node3D.new()
	root.name = "LostPage"
	lv.add_child(root)
	root.global_position = SPOTS[a]
	var spr := Sprite3D.new()
	spr.texture = load("res://assets/props/lost_page.png")
	spr.pixel_size = 0.34 / spr.texture.get_height()
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.shaded = false
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	spr.modulate = Color(1.15, 1.08, 0.9)
	spr.position = Vector3(0, 0.32, 0)
	root.add_child(spr)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.86, 0.5)
	glow.light_energy = 0.6
	glow.omni_range = 1.6
	glow.position = Vector3(0, 0.5, 0)
	root.add_child(glow)
	var sp := CPUParticles3D.new()
	sp.amount = 5
	sp.lifetime = 1.6
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = 0.25
	sp.gravity = Vector3(0, 0.25, 0)
	sp.initial_velocity_min = 0.02
	sp.initial_velocity_max = 0.1
	var qm := QuadMesh.new()
	qm.size = Vector2(0.05, 0.05)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(1.0, 0.92, 0.55)
	qm.material = m
	sp.mesh = qm
	sp.position = Vector3(0, 0.35, 0)
	root.add_child(sp)
	# (Ebain's sfx pack) a soft magic hum you can hear when you get close
	if ResourceLoader.exists("res://assets/sounds/amb_aura.ogg"):
		var hum := AudioStreamPlayer3D.new()
		var hs: AudioStreamOggVorbis = load("res://assets/sounds/amb_aura.ogg").duplicate()
		hs.loop = true
		hum.stream = hs
		hum.volume_db = -10.0
		hum.unit_size = 1.4
		hum.max_distance = 11.0
		hum.position = Vector3(0, 0.4, 0)
		hum.autoplay = true
		root.add_child(hum)
	lv.set_meta("lost_page", root)
	lv.set_meta("lost_page_hinted", false)

static func interactable(lv) -> Dictionary:
	var node = lv.get_meta("lost_page") if lv.has_meta("lost_page") else null
	if node == null or not is_instance_valid(node) or not node.visible:
		return {}
	return { "id": "lost_page", "label": "a Lost Page", "verb": "Pick up", "pos": node.global_position, "h": 0.9, "r": PICK_RANGE,
		"steps": [{ "do": "lost_page" }] }

static func process(lv, _delta: float) -> void:
	var node = lv.get_meta("lost_page") if lv.has_meta("lost_page") else null
	if node == null or not is_instance_valid(node) or not node.visible:
		return
	var spr: Sprite3D = node.get_child(0)
	spr.position.y = 0.32 + sin(lv.t * 2.2) * 0.05   # a gentle float
	if lv.busy or (lv.get_meta("lost_page_hinted") if lv.has_meta("lost_page_hinted") else true) or lv.leader == null or lv.leader.id != "xylo":
		return
	var p: Vector3 = node.global_position
	var lp: Vector3 = lv.leader.global_position
	if Vector2(p.x - lp.x, p.z - lp.z).length() < HINT_RANGE:
		lv.set_meta("lost_page_hinted", true)   # once per visit
		lv.char_label(lv.leader, HINT_BARK, 2.6, lv.leader.height_m + 0.3, Color("#d9c7ff"))

static func pickup(lv) -> void:
	var a := _area(lv)
	var node = lv.get_meta("lost_page") if lv.has_meta("lost_page") else null
	if a == "" or node == null:
		return
	_g().unlock("lostpage_" + a)
	var tw: Tween = node.create_tween().set_parallel(true)
	tw.tween_property(node, "position:y", node.position.y + 0.8, 0.5)
	tw.tween_property(node, "scale", Vector3.ONE * 0.05, 0.5)
	lv.play_sound("sfx_pop", -12.0, 1.6)
	if lv.ui_sfx: lv.ui_sfx.play()
	for c in node.get_children():   # the hum stops when you take it
		if c is AudioStreamPlayer3D: c.stop()
	await lv.wait(0.5)
	node.visible = false
	var n := count()
	lv.show_toast("Lost Deloye Lore Page (%d/5)" % n, 2.4)
	var x = null
	for u in lv.party:
		if u.id == "xylo":
			x = u
	if x:
		lv.char_label(x, PICKUP_BARKS[clampi(n - 1, 0, PICKUP_BARKS.size() - 1)], 3.2, x.height_m + 0.3, Color("#d9c7ff"))
	await lv.wait(0.3)

# Inventory → Quests: "Lost Pages n/5" + what the found ones say. Empty until you have one.
static func quest_text() -> String:
	var n := count()
	if n == 0:
		return ""
	var t := "Lost Deloye Lore Pages  (%d/5)\n" % n
	for a in AREAS:
		if found(a):
			t += "     \"%s\"\n" % SNIPPETS[a]
	if n >= AREAS.size():
		t += "     (All five. Something smells off in the village.)\n"   # DRAFT
	return t
