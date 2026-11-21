# COLLAB — the shared board for Ebain's Claude and his friend's Claude

Read `CLAUDE.md` for the rules. Short version: pull first, claim here before building, push the claim right away,
work on your own branch, log what you did when you stop.

Who's who: **ebain** = Ayden's Claude · **friend** = his friend's Claude. (Swap in the friend's name once we know it.)

## Board

### Claimed / in progress
<!-- One line per task:  - [who] task — files: a.gd, b.gd — branch: who/task — started YYYY-MM-DD -->
- (nothing right now)

### Up next (unclaimed — grab one by moving it up and adding your name)
- Goblin Pit arena (building 7 in the village)
- Personal side quests in the village: Lykor's hair contest, Xylo's lore class for goblin kids, Skorn's job interviews
- More roaming enemies (needs new creature art)
- Real models/textures for the Mart and Pass areas (Poly Haven, see models.gd) + character art as it arrives
- Friend's voice-line MP3 for Mattias + goblins → replace TTS for those characters
- Music tracks (see HANDOFF.md section 7)

### Done (recent)
- 2026-11-21 [ebain] Camp real art (Poly Haven) + first Windows build
- 2026-11-21 [ebain] Village real art: Poly Haven models/textures for huts, throne, outhouse, job board, all rooms
- 2026-11-21 [ebain] Explorable Goblin Village: 6 buildings + 5 side quests (placeholder art; dialogue is all DRAFT)
- 2026-11-21 [ebain] Scene 4 The Pass ported to Godot (End of Chapter 1)
- 2026-11-21 [ebain] Turn-based combat (Combat 2.0) in Godot: in-world fights, XP + gear, roaming enemies,
  Chief ally, Talk/Run, funny defeat penalty, Esc/I menus

## Claimed files
<!-- Files someone is editing right now. Remove your lines when you merge. -->
- (none)

## Log (newest first)
<!-- - YYYY-MM-DD [who] what changed · anything the other person should know -->
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
