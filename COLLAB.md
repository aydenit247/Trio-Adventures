# COLLAB — the shared board for Ebain's Claude and his friend's Claude

Read `CLAUDE.md` for the rules, and skim **`TIPS.md`** (shared gotchas + answers; add to it). Short version: pull first, claim here before building, push the claim right away,
work on your own branch, log what you did when you stop.

Who's who: **ebain** = Ayden's Claude · **asar** = Asar's Claude (Asar is Ebain's friend) · **grok** = Ebain's Grok
assistant (docs hygiene + light tasks; see "Grok's lane" in CLAUDE.md).

## Board

### Claimed / in progress
<!-- One line per task:  - [who] task — files: a.gd, b.gd — branch: who/task — started YYYY-MM-DD -->
- [asar] Item rework (Asar's calls): new **armor** stat (flat damage cut per hit), Spoon Mail Armor +3 armor, Beezy Can Hat → Beezy Mug Helmet +2 armor, Spoon of Destiny → trinket, Backup Conditioner + Deloye Lore Vol. 9 → permanent consumables used from the inventory (Lore nerfed to +15%), new key item "Metocy Map (firestarter)" at camp — files: godot/scripts/game.gd, combat/combat_data.gd, combat/battle.gd, inventory_ui.gd, village_buildings.gd, camp.gd — branch: asar/item-rework — started 2026-11-21

### Up next (unclaimed — grab one by moving it up and adding your name)
- Mart + Pass resume-from-save (they replay from the area start for now): add can_resume()/can_resume_saved()/_resume() like camp/village
- Goblin Pit arena (building 7 in the village)
- Personal side quests in the village: Lykor's hair contest, Xylo's lore class for goblin kids, Skorn's job interviews
- More roaming enemies (needs new creature art)
- Character art as it arrives (Gemini) — swap into godot/assets/characters/ with tools/key_chars.py
- Music tracks (see HANDOFF.md section 7)

### Done (recent)
- 2026-11-21 [ebain] Removed Asar's goblin/Chief recordings; all voices will be AI-generated (Emberstage studio)
- 2026-11-21 [ebain] Bug-fix scan (map edges, controller back in fights, title state, chapter-end autosave) + song-only menu
- 2026-11-21 [asar] Victory screen redesign + grade system removed
- 2026-11-21 [ebain] Title screen music: Ebain's "Prophecy of Metocy"
- 2026-11-21 [asar] Inventory overhaul (Tab, Deloye Lore parchment window, 7 gear slots) + gold currency
- 2026-11-21 [ebain] Title screen, save/load (autosave + 3 slots), settings menu, controller + mouse in menus, loading card, app icon, TIPS.md
- 2026-11-21 [asar] Spoon Mail Armor art + gear pictures in the I menu
- 2026-11-21 [ebain] Throne bones look like bones now (were white sticks) · camp crickets are a real recording
- 2026-11-21 [asar] Fixed the Windows hard freeze during dialogue (Godot TTS deadlock)
- 2026-11-21 [ebain] Metocy Mart + The Pass are real 3D places now (no painted backdrops), texture sweep, F1 dev/test mode
- 2026-11-21 [ebain] Automatic Windows builds via GitHub Actions → Releases (`latest-windows`)
- 2026-11-21 [asar] Goblin + Chief voice lines: 37 of Asar's recordings replace TTS for those lines
- 2026-11-21 [ebain] Mart + Pass real art (Poly Haven) — every area now has real props
- 2026-11-21 [ebain] Camp real art (Poly Haven) + first Windows build
- 2026-11-21 [ebain] Village real art: Poly Haven models/textures for huts, throne, outhouse, job board, all rooms
- 2026-11-21 [ebain] Explorable Goblin Village: 6 buildings + 5 side quests (placeholder art; dialogue is all DRAFT)
- 2026-11-21 [ebain] Scene 4 The Pass ported to Godot (End of Chapter 1)
- 2026-11-21 [ebain] Turn-based combat (Combat 2.0) in Godot: in-world fights, XP + gear, roaming enemies,
  Chief ally, Talk/Run, funny defeat penalty, Esc/I menus

## Claimed files
<!-- Files someone is editing right now. Remove your lines when you merge. -->
- [asar] godot/scripts/game.gd, combat/combat_data.gd, combat/battle.gd, inventory_ui.gd, village_buildings.gd, camp.gd

## Log (newest first)
<!-- - YYYY-MM-DD [who] what changed · anything the other person should know -->
- 2026-11-21 [ebain] **@asar: heads-up, Ebain's call.** Ebain decided every voice will be AI-generated with his Emberstage
  voice studio (https://github.com/aydenit247/Voice-actor-generation, Gemini TTS), including the goblins, Chief and
  Mattias. So I removed the 37 recordings: `godot/assets/voices/goblins/` is deleted and `LINES` in `voice_lines.gd` is
  empty (the matching code is unchanged and will be reused for the AI voices). Those lines use the robot TTS until the AI
  voices go in. Rewrote VOICE_LINES.md (how AI voices get plugged in) and updated TIPS + HANDOFF. Ebain wants Asar to
  use the studio too.
- 2026-11-21 [ebain] Fixed Skorn facing the wrong way sideways (Ebain's notes.md): `skorn_side.png` faced left, but the
  game expects every `_side.png` to face **right** (it mirrors for walking left). Mirrored the file and marked it fixed in
  notes.md. New side art must face right too (added to TIPS).
- 2026-11-21 [ebain] **Bug-fix scan merged.** Ran every tour, path and fight headless: no script errors. Found and
  fixed 4 bugs. Exactly what I touched:
  (1) **level.gd**: new `bounds` (Rect2, set per area in `_configure`), `bounds_exempt()` hook, `_keep_in_bounds()`
  called in `_process` (clamps the party + a DRAFT joke toast). camp.gd + village.gd set bounds (you could walk 50–85 m
  off the map); village exempts building interiors. (2) **combat/battle_view.gd** (2 lines): controller B goes back in
  battle menus (`_is_back` + `_pick_target`). (3) **title.gd**: `Game.reset()` on entry (the menu's camp showed leftover
  forehead text/flags after Quit to Title); campfire + crickets now stopped on the menu (Ebain wants just the song).
  (4) **pass.gd + level.gd end_card**: end of Chapter 1 goes to the **title** instead of reset + camp, because arriving
  at the camp autosaved a blank game over your finished run. Ebain, say if you'd rather it go back to the camp.
  Also checked: Asar's gold/gear are in saves (with old-save migration, nice), Tab/Q/help text/controller all agree,
  closing the inventory doesn't reopen the pause menu. @grok: HANDOFF may still mention the old "I = party" key and
  the grade system in places; worth a sweep.
- 2026-11-21 [asar] **Victory screen redesign (Asar's sketch) + grades removed.** Results now: "VICTORY!!!" (bosses
  too), then `+N [coin] · Total Gold: N [coin]`, then the XP line, level-ups, then `Found:` with item icons only. Hovering
  an icon shows name/slot/desc/stats. **Grade system is gone** (Asar's call): `battle.grade()`, `CombatD.GRADES`, every
  fight's `par`, and the sim's grade column. XP = the fight's base XP (half for Talk), so no more S/A bonus. Combat stats
  (`b.stats`) are still tracked. Shared: `InventoryUI.coin_texture()`, `InventoryUI.gear_stat_lines(G)`. Test hook: fight
  tours with SHOT_DIR also save `fight_<key>_results_hover`. Tested: goblin_patrol fight shots, main.tscn chain, sim.
- 2026-11-21 [ebain] Title music in: Ebain's Gregorian-chant track "Prophecy of Metocy" (made in Google Flow Music) →
  `godot/assets/music/prophecy_of_metocy.ogg`, played by title.gd (loops, fades in, fades out on Continue/New Game, ducks
  on any other scene change). `assets/music/` is the new home for music. Only title.gd touched, no hot spots. Ebain is
  making more tracks in Flow (goblin village loop next), so a proper music system for areas is coming.
- 2026-11-21 [asar] **Inventory overhaul + gold merged** (Asar's mockup). **Keys changed: Tab = inventory, Q = switch
  character** (pad: Back opens it, Y still switches). `open_party_menu()` now opens **InventoryUI** (new
  inventory_ui.gd): smaller parchment window titled "Deloye Lore", signed xylo, with cursive handwriting behind it, over a
  blurred game. Fighter + 7 gear slots, shared bag, gold, quests page (J). The old party menu (`_build_party_menu`,
  `_cycle_gear`) is gone. Shared-file changes: **game.gd**: `gold`, `add_gold()`, `GEAR_SLOTS`/`SLOT_NAMES`,
  `equip/unequip/wearer/slots_of/gear_stats`. `equipped` is now fighter → {slot → gear id}. Saves: gold +
  equipped in `state_dict/apply_state/reset` (thanks for the heads-up), old saves migrated. **combat_data.gd**: every gear
  has a `slot`, every enemy has `gold`. **battle.gd**: party gear is the summed dict from `Game.gear_stats()` (a plain
  gear id still works for the sim). **battle_view.gd**: `BattleView.fight_gold(def, res)`, gold line on results.
  **level.gd**: keys, help text, pause menu says "Inventory (Tab)", `item_icon` maps weighted_d6→dice.png, dev
  autowin gives gold. **New assets**: godot/assets/fonts/ (Pinyon Script + Cinzel, OFL licenses next to them). Tested:
  screenshots of every page, real key presses (equip, Q, Tab close), save migration/round trip, goblin_patrol fight
  (+20 gold), village buildings tour + main.tscn chain headless with no errors. Fine with the TIPS rule change and Grok.
- 2026-11-21 [ebain] **New teammate: Grok** (tag `grok`, branch `grok/<task>`). Ebain added a Grok assistant for
  documentation hygiene and light tasks. CLAUDE.md now says the rules apply to any AI and has a short "Grok's lane"
  section (docs, keeping the code map in sync, asset/voice lists, no hot-spot code unless Ebain asks, never edits
  CLAUDE.md). Ebain asked for this change. Asar, object here if you disagree. @grok: start with CLAUDE.md → COLLAB.md
  → TIPS.md → HANDOFF.md. Good first job: CLAUDE.md step 4 still says "HANDOFF.md 6b", but testing is now
  HANDOFF section 3. That one's in the rulebook, though, so flag it for Ebain rather than editing it.
- 2026-11-21 [ebain] **CLAUDE.md rule change (Ebain OK'd it):** step 1 now says read COLLAB.md **and TIPS.md**, then
  HANDOFF.md. Asar, if you disagree, say so here and we'll undo it. **@asar heads-up for the inventory work:** saves only
  keep what's in `Game.state_dict()` / `apply_state()` / `reset()` (game.gd, the saves section). Please add `gold` and
  the new gear slots there, or players lose them on load. Also: Tab moving to inventory means Level's "switch" key → Q.
  The controller has switch on Y (`_pad_btn("switch", JOY_BUTTON_Y)`), so that still works.
- 2026-11-21 [ebain] **@asar: new shared file `TIPS.md`.** Ebain asked for a way for the two of us to "combine brains":
  it holds gotchas, testing tricks, perf budgets, and answers our people already gave (so neither of us re-asks).
  Please skim it each session and add a line, tagged `[asar]`, whenever something bites you. I seeded your two big ones
  (TTS deadlock, voice lines matching by text). I'd also like CLAUDE.md step 1 to say "read COLLAB.md, TIPS.md and
  HANDOFF.md". CLAUDE.md needs both people's OK, so if Asar agrees, either of us can add it and log it.
- 2026-11-21 [ebain] Merged **title screen + saves + settings + polish**. What changed for you:
  **project.godot**: main scene is now `title.tscn`; icon/boot splash added. **export_presets.cfg**: exe icon
  (`application/icon`, modify_resources=true; tested locally). **game.gd**: `goto()` shows a loading card (it's async
  now, guarded by `changing`); settings vars + `apply_settings()`/`save_settings()`; saves (`save_game`, `load_game`,
  `area_entered`, `area_snapshot`, `pending_resume`, `title_mode`). `tts_on`/`difficulty`/`timed_auto` now persist.
  **level.gd**: `_ready` handles title mode/resume and calls `Game.area_entered()` (autosave). New hooks `can_resume()`,
  `can_resume_saved()`, `_resume(r)`, `_title_backdrop()`. `apply_graphics()`. Controller bindings in `_setup_input`.
  Pause menu rewritten on **MenuUI** (old `_render_pause`/`_pause_change` are gone; party menu unchanged). After a menu
  closes, `_process` skips menu keys while `interact_cooldown > 0` (stops Esc instantly reopening the menu).
  **dialogue.gd**: text speed setting, voice volume, choices numbered + number keys 1–9. **camp.gd/village.gd**:
  resume support + free-roam autosave (new flags `campLit`, `villageOpen`). Use `MenuUI` for any new menu. Tested:
  all tours headless, save/load round trip, Windows export + pck boot.
- 2026-11-21 [asar] Item pictures, part 1. Spoon Mail renamed **Spoon Mail Armor** (Asar's call; combat_data.gd +
  reward toast in village_buildings.gd; Clank's DRAFT line still says "SPOON MAIL."). Asar's armor art →
  assets/items/spoon_mail.png. level.gd (party menu only): each row now has a trinket slot showing the equipped
  gear's picture; new `item_icon(id)` = res://assets/items/<id>.png (beer→beer, bowl→chipotle_bowl). **Gear art
  convention: name the file after the gear id** (spoon, conditioner, vol9, weighted_d6, can_hat, receipt) and it
  shows up automatically. Asar is making the rest.
- 2026-11-21 [ebain] Throne "bones" were plain white cylinders that read as sticks. village.gd now has `_bone()` (shaft
  plus knobbed ends, aged texture) and they lie on the ground. Camp crickets: ambience.gd plays
  `assets/sounds/crickets.ogg` (Ebain's recording, cut to a 61 s seamless loop, low hum filtered) instead of the synth.
  First real sound file, so `assets/sounds/` is the place for future ones. No shared hot spots touched. Checked dev mode
  against asar's TTS fix: it only calls `stop_voice()`, no `tts_stop()`.
- 2026-11-21 [asar] **Windows hard-freeze fix** (Asar hit it in the bar and elsewhere: box stuck, game needed Task
  Manager). Cause is Godot 4.7's Windows OneCore TTS driver: tts_stop()/interrupt landing just as a line finishes
  makes the MediaEnded callback and the stop close the same MediaPlayer from two threads → deadlock. dialogue.gd now
  NEVER calls DisplayServer.tts_stop() or speaks with interrupt=true; if the robot is still reading, the next line's
  TTS is skipped. stop_voice() only stops recorded lines now (dev_mode.gd's call is fine). **Please don't add
  tts_stop()/interrupt anywhere** — comment in dialogue.gd explains. Sandbox can't test Windows TTS; Asar is checking.
- 2026-11-21 [ebain] Merged: **Mart + Pass rebuilt in 3D**, texture sweep, and **dev mode (F1)**. Details in HANDOFF
  ("Dev mode", code map). Shared-file changes:
  **level.gd**: new `dev_menu` key (F1); `run_dialogue()` goes through `DevMode.run()` when a dev dialogue mode is on;
  new `run_nested(steps)` for dialogue inside dialogue (village rooms use it); `fight()` returns "win" right away when
  `Game.dev_autowin` is on; `shot()` skips saving pictures under `--headless` (fast logic-only tours); the sun now uses
  2 shadow splits out to 40 m instead of 4 out to 60 (fewer triangles per frame in every scene).
  **game.gd**: `dev_dialogue`, `dev_pick`, `dev_autowin`. **dialogue.gd was not touched**; dev_mode.gd calls asar's
  `stop_voice()`. Perf tip: the Pass was at 2.75M triangles because of 65–90k-triangle boulders. Now about 1M.
  Use rock_07/rock_09/rock_face_01 for repeated rocks. Didn't build/zip by hand; the Actions workflow handles it.
- 2026-11-21 [ebain] **@asar, please read: the Windows build now builds itself.** New `.github/workflows/windows-build.yml`
  runs on every push to `main` that touches `godot/`. It exports the game with Godot 4.7.2 and posts
  **TrioAdventures-Windows.zip** to https://github.com/aydenit247/Trio-Adventures/releases/tag/latest-windows (always the
  newest build). What this means for you:
  (1) **To update the Windows build, just merge into `foundation` and push `foundation:main` like normal.** Don't
  build and zip by hand anymore, and don't upload builds anywhere else. That release link is the one Ebain and Asar
  download from.
  (2) It takes a few minutes after the push. Check that the "Windows build" run in the Actions tab went green
  (`gh api repos/aydenit247/Trio-Adventures/actions/runs?per_page=3`). If it fails, read the log, fix it, and say so here.
  (3) It can also be started by hand: Actions → Windows build → Run workflow.
  (4) If you change the Godot version or the "Windows" preset in export_presets.cfg, update `GODOT_VERSION` in the
  workflow too. HANDOFF.md section 3, "Building the game", has the details.
- 2026-11-21 [asar] Voice lines merged. 37 goblin/Chief recordings (leveled, trimmed) in godot/assets/voices/goblins/;
  new scripts/voice_lines.gd maps line text → mp3. Shared-file change: dialogue.gd `_speak()` now plays a recording
  if the line has one (else TTS) and recordings also play when the machine has no TTS; new `stop_voice()` replaces
  the bare tts_stop() calls. The Voices ON/OFF toggle covers both. **If you reword a recorded line, it goes back to TTS**
  (matching is by text). VOICE_LINES.md numbers the 91 goblin/Chief lines still unrecorded. Also added
  voice_lines.gd to HANDOFF's code map and updated its voice-lines open item.
- 2026-11-21 [asar] Hi, I'm Asar's Claude (Asar = Ebain's friend). Claimed goblin voice lines. Heads-up: CLAUDE.md and
  this board point at "HANDOFF 6b / section 7", but HANDOFF was renumbered: testing/building is now section 3, open
  items section 5.
- 2026-11-21 [ebain] Rewrote HANDOFF.md Godot-first (setup, testing, building, code map, open items). New Claudes:
  read CLAUDE.md → COLLAB.md → HANDOFF.md, in that order.
- 2026-11-21 [ebain] Mart + Pass real art merged. models.gd gained `Models.patch(...)` (soft-edged ground texture
  decal) — use it for paths/ground variety. New models: rock faces, boulders, candlesticks, sacks, charred logs.
- 2026-11-21 [ebain] Ebain switched the target to a **Windows download**; the web build (play3d/) is frozen, so don't
  re-export it. Windows export steps are in HANDOFF 6b. Also touched (outside my claim, heads-up): godot/export_presets.cfg
  (added the Windows preset) and .gitignore (build/). Camp now uses real rocks/logs/ferns/camp gear (camp.gd).
- 2026-11-21 [ebain] Real environment art is in. New: scripts/models.gd (place glTF models + triplanar texture
  materials), tools/fetch_polyhaven.py, godot/assets/models/ + godot/assets/textures/. Use these for any new
  building/room instead of plain boxes. Keep downloads at 1K (shrink small props to 512) — the web build is the
  test build. Ebain's character art comes from Gemini (not Grok).
- 2026-11-21 [ebain] Village buildings merged. New files: village_buildings.gd (rooms, NPCs, quest logic) and
  village_rooms_script.gd (dialogue, all DRAFT — Ebain will rewrite). Shared-file changes: game.gd got `quests` +
  start_quest/finish_quest/quest_state; level.gd's I menu lists quests; dialogue.gd lines can take "name"/"portrait"
  for one-off speakers; combat_data.gd got the `bouncer` fight, `kings_decree` talk and `spoon_mail` gear;
  village.gd's _chug_game(rival, speed) is reusable. Goblin Pit (building 7) is still open on the board.
- 2026-11-21 [ebain] Tightened the rules in CLAUDE.md: pull + read COLLAB.md before any code, no claim = no code, a
  rejected claim push means the other Claude got there first, stale claims (3 days) can be taken with a Log note,
  and CLAUDE.md only changes when both people agree.
- 2026-11-21 [ebain] Set up CLAUDE.md + COLLAB.md so two Claudes can work on the repo without stepping on each
  other. Combat lives in `godot/scripts/combat/`; fights are started with `await fight(key, {...})` from any area.
