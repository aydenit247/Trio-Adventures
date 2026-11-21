# COLLAB — the shared board for Ebain's Claude and his friend's Claude

Read `CLAUDE.md` for the rules, and skim **`TIPS.md`** (shared gotchas + answers; add to it). Short version: pull first, claim here before building, push the claim right away,
work on your own branch, log what you did when you stop.

Who's who: **ebain** = Ayden's Claude · **asar** = Asar's Claude (Asar is Ebain's friend) · **grok** = Ebain's Grok
assistant (docs hygiene + light tasks; see "Grok's lane" in CLAUDE.md).

## Board

### Claimed / in progress
<!-- One line per task:  - [who] task — files: a.gd, b.gd — branch: who/task — started YYYY-MM-DD -->
- [grok] Diddy Chud Giant voice lines (Ebain asked) — files: godot/assets/voices/giant/, godot/scripts/voice_index.gd — branch: grok/giant-voices — started 2026-11-21

### Up next (unclaimed — grab one by moving it up and adding your name)
- Mart + Pass resume-from-save (they replay from the area start for now): add can_resume()/can_resume_saved()/_resume() like camp/village
- Goblin Pit arena (building 7 in the village)
- Personal side quests in the village: Lykor's hair contest, Xylo's lore class for goblin kids, Skorn's job interviews
- More roaming enemies (needs new creature art)
- Character art as it arrives (Gemini) — swap into godot/assets/characters/ with tools/key_chars.py
- Music tracks (see HANDOFF.md section 7)

### Done (recent)
- 2026-11-21 [asar] Crash + freeze reports (crash_reporter.gd + repo folder Crash Reports/)
- 2026-11-21 [ebain] Voice import pipeline: studio export zip → OGG + voice_index.gd (tools/import_voices.py)
- 2026-11-21 [asar] Inventory right-click → View (big item picture)
- 2026-11-21 [asar] Item rework (armor stat, permanent consumables, Metocy Map), stats panel, pictures for every item
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

## Log (newest first)
<!-- - YYYY-MM-DD [who] what changed · anything the other person should know -->
- 2026-11-21 [asar] **Crash + freeze reports merged (Asar's ask).** New `crash_reporter.gd`, started by one line in
  **game.gd** `_ready`. A watchdog thread writes a **Freeze** report after 12 s without a frame (then adds "came back after
  N s" or, after a Task Manager kill, "never came back"). A session marker that a normal quit deletes catches
  **crashes/force-closes**, reported on the next launch with the previous session's events, state and Godot log tail. A
  notice shows where it went. `OS.add_logger` feeds every error/print into the breadcrumbs. It polls scene/dialogue/fight/menu
  with `get()`, so nobody has to call it, but `CrashReporter.note("...")` is there. Reports go in `Crash Reports/` next to
  the exe (user:// in editor/sandbox). The repo's new `Crash Reports/` folder + README is where players' reports get filed.
  Heads-up: sandbox runs killed by `timeout` leave a Crash report in user:// on the next run (expected, ignore).
  Tested: normal quit (no report), kill -9 (Crash report), 16 s stall (Freeze + recovered), hang + kill (hard freeze), chain.
- 2026-11-21 [ebain] **Voice import pipeline merged.** `python3 tools/import_voices.py <studio export zip>` converts the
  studio's WAVs to OGG in `godot/assets/voices/<character>/` and writes the generated `godot/scripts/voice_index.gd`
  (don't hand-edit it). Shared-file changes: **voice_lines.gd** now reads VoiceIndex first and hand-added `LINES` entries
  can include an extension (none = .mp3, as before). **dialogue.gd** `_speak()`: one line, inner thoughts now play a
  voice file too (the studio bakes their echo in; robot TTS for thoughts is unchanged). Tested: import → `--import` →
  stream_for returns AudioStreamOggVorbis for imported lines, null for the rest; camp tour headless, no errors.
