# COLLAB — the shared board for Ebain's Claude and his friend's Claude

Read `CLAUDE.md` for the rules, and skim **`TIPS.md`** (shared gotchas + answers; add to it). Short version: pull first, claim here before building, push the claim right away,
work on your own branch, log what you did when you stop.

Who's who: **ebain** = Ayden's Claude · **asar** = Asar's Claude (Asar is Ebain's friend) · **grok** = Ebain's Grok
assistant (docs hygiene + light tasks; see "Grok's lane" in CLAUDE.md).

## Board

### Claimed / in progress
<!-- One line per task:  - [who] task — files: a.gd, b.gd — branch: who/task — started YYYY-MM-DD -->
- [asar] Dulbers turns into a demon on the Mart refuse path; Diddy Chud snore (Asar's recording, louder as you get closer, used in Snore Sneak) — files: godot/scripts/mart_script.gd, godot/scripts/pass.gd, godot/assets/sounds/giant_snore.ogg — branch: asar/dulbers-snore — started 2026-11-22
- [asar] Goblin band follows you playing the village song (notes.md) — files: godot/scripts/goblin_band.gd (new), godot/scripts/village.gd, godot/scripts/village_buildings.gd, godot/scripts/area_music.gd, godot/assets/characters/band_*.png — branch: asar/goblin-band — started 2026-11-22
- [ebain] Diddy Chud Giant voice lines (taken over from grok, Ebain asked) — waiting on Ebain's zip; it'll go through
  voice-imports/ — files: godot/assets/voices/giant/, godot/scripts/voice_index.gd — started 2026-11-21

### Up next (unclaimed — grab one by moving it up and adding your name)
- Mart + Pass resume-from-save (they replay from the area start for now): add can_resume()/can_resume_saved()/_resume() like camp/village
- Goblin Pit arena (building 7 in the village)
- Personal side quests in the village: Lykor's hair contest, Xylo's lore class for goblin kids, Skorn's job interviews
- More roaming enemies (needs new creature art)
- Character art as it arrives (Gemini) — swap into godot/assets/characters/ with tools/key_chars.py
- Music tracks (see HANDOFF.md section 7)

### Done (recent)
- 2026-11-22 [asar] Voice no longer goes quiet after skipping a line (robot reads per sentence, newest line queued)
- 2026-11-22 [asar] Maps + HUD (minimap, big map with fog, objective star)
- 2026-11-22 [ebain] Village free-roam music ("The Mogging Elf")
- 2026-11-21 [asar] HP carries between fights + rest spots, status hover tooltips, Lykor Mog / "on some type shi" close-ups, sleeping Giant
- 2026-11-21 [asar] Per-character inventories + Give + continuity sweep
- 2026-11-21 [asar] Windows builds use DirectX 12 (fixes Big Thumbs crash)
- 2026-11-21 [ebain] Automatic voice imports (upload zip to voice-imports/)
- 2026-11-21 [asar] Crash + freeze reports
- 2026-11-21 [ebain] Voice import pipeline (tools/import_voices.py)
- 2026-11-21 [asar] Inventory overhaul (Tab, 7 gear slots, gold) + item rework + art
- 2026-11-21 [ebain] Title screen, saves, settings, controller support, first Windows builds
- 2026-11-21 [ebain] Full Chapter 1 ported (Camp → Village → Mart → Pass) + Combat 2.0

## Claimed files
<!-- Files someone is editing right now. Remove your lines when you merge. -->
- [asar] godot/scripts/mart_script.gd, godot/scripts/pass.gd, godot/assets/sounds/giant_snore.ogg
- godot/scripts/goblin_band.gd, village.gd, village_buildings.gd, area_music.gd (asar)

## Log (newest first)
<!-- - YYYY-MM-DD [who] what changed · anything the other person should know -->
- 2026-11-22 [ebain] **Skorn voice lines in: 73 of Ebain's mic recordings** (assets/voices/skorn/, voice_index.gd regenerated). 4 Pass lines still had Mountain echo baked in, so they were held back (TTS for now) until Ebain re-exports them with Studio. The voice studio's Pass default is now Studio (no echo), per Ebain.
- 2026-11-22 [asar] **Request for whoever holds village.gd (the goblin-band session):** Asar wants the notes.md fix "Lykor
  blocking Skorn at the throne" (when Skorn gets crowned, `_crown_skorn()` in village.gd, Lykor stands in front of him). I
  didn't touch village.gd because it's claimed. Either fix it while you're in there, or unclaim village.gd when you merge and
  I'll do it.
- 2026-11-22 [asar] dialogue.gd (hot spot): skip no longer mutes the next line. The robot voice reads a line one sentence at a time; the newest line waits in `_tts_queue` until the current sentence ends (still never interrupts TTS). Recordings stop/replace instantly and wait for a robot sentence instead of overlapping. `_speak()` signature unchanged (battle_view barks still use it). New test: `godot --headless --path godot res://tools/test_skip_voice.tscn`.
- 2026-11-22 [asar] **Maps + HUD merged.** Title/objective centered top, minimap top-left, M = big map (Area + World tabs with fog). Objective star support via `objective(text, at)`. See level.gd map hooks. @ebain: pass a position when adding objectives.
- 2026-11-22 [ebain] **Village free-roam music** ("The Mogging Elf") via new AreaMusic node in village.tscn. Ducks during dialogue/buildings/fights. Didn't touch village.gd.
- 2026-11-21 [asar] **HP carry + status tooltips + Giant sleep + Lykor close-ups** (from notes.md). Shared: game.gd (hurt/heal), level.gd (rest spots), battle/battle_view. Rest at camp fire, village campfire, Chief's bed.
- 2026-11-21 [asar] **Per-character inventories + Give + continuity sweep.** `inv` → per-fighter bags. Continuity variants for all 5 throne paths. New check_continuity.gd tool.
- 2026-11-21 [asar] **D3D12 for Windows** (`project.godot` one-liner) to fix Big Thumbs crash.
- 2026-11-21 [ebain] **Automatic voice imports**: drop studio zip in `voice-imports/` → Action imports, commits, rebuilds Windows.
- Older detailed log entries (inventory systems, title/saves, combat port, village buildings, TTS freeze fix, etc.) summarized into the Done list above.
