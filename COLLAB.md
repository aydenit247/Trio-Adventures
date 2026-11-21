# COLLAB — the shared board for Ebain's Claude and his friend's Claude

Read `CLAUDE.md` for the rules. Short version: pull first, claim here before building, push the claim right away,
work on your own branch, log what you did when you stop.

Who's who: **ebain** = Ayden's Claude · **asar** = Asar's Claude (Asar is Ebain's friend).

## Board

### Claimed / in progress
<!-- One line per task:  - [who] task — files: a.gd, b.gd — branch: who/task — started YYYY-MM-DD -->
- [ebain] (1) Missing-texture sweep · (2) Metocy Mart + The Pass rebuilt as real 3D places (no more painted
  backdrops) · (3) Developer/test mode (skip dialogue, choices-only, dialogue viewer, scene jump, cheats) — files:
  godot/scripts/mart.gd, godot/scripts/pass.gd, godot/scripts/level.gd, godot/scripts/game.gd, godot/scripts/models.gd,
  godot/scripts/village_buildings.gd (run_lines → dev filter), new godot/scripts/dev_mode.gd, new asset folders.
  NOT touching dialogue.gd (asar's) — dev skipping is done in level.gd before steps reach the dialogue box —
  branch: ebain/real-mart-pass-devmode — started 2026-11-21

### Up next (unclaimed — grab one by moving it up and adding your name)
- Goblin Pit arena (building 7 in the village)
- Personal side quests in the village: Lykor's hair contest, Xylo's lore class for goblin kids, Skorn's job interviews
- More roaming enemies (needs new creature art)
- Character art as it arrives (Gemini) — swap into godot/assets/characters/ with tools/key_chars.py
- Mattias voice lines (Asar, later)
- Music tracks (see HANDOFF.md section 7)

### Done (recent)
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
- (none)
- [ebain] godot/scripts/mart.gd, pass.gd, level.gd, game.gd, models.gd, village_buildings.gd, dev_mode.gd (new), new asset folders

## Log (newest first)
<!-- - YYYY-MM-DD [who] what changed · anything the other person should know -->
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
