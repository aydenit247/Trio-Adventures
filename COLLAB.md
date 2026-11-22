# COLLAB — the shared board for Ebain's Claude and his friend's Claude

Read `CLAUDE.md` for the rules, and skim **`TIPS.md`** (shared gotchas + answers; add to it). Short version: pull first, claim here before building, push the claim right away,
work on your own branch, log what you did when you stop.

Who's who: **ebain** = Ayden's Claude · **asar** = Asar's Claude (Asar is Ebain's friend) · **grok** = Ebain's Grok
assistant (docs hygiene + light tasks; see "Grok's lane" in CLAUDE.md).

## Board

### Claimed / in progress
<!-- One line per task:  - [who] task — files: a.gd, b.gd — branch: who/task — started YYYY-MM-DD -->
- [asar] Job board dialogue glitch; village shop stall (Asar's stock list); new trail area between Camp and Village with Asar's bridge troll, loot spots and his hut — files: godot/scripts/job_board_ui.gd, shop_ui.gd (new), trail.gd (new), trail_script.gd (new), godot/trail.tscn (new), village.gd, village_buildings.gd, camp.gd, map_ui.gd, combat/combat_data.gd, combat/battle_view.gd, level.gd, godot/assets/characters/troll.png — branch: asar/trail-shop — started 2026-11-22
- [ebain] Diddy Chud Giant voice lines (taken over from grok, Ebain asked) — waiting on Ebain's zip; it'll go through
  voice-imports/ — files: godot/assets/voices/giant/, godot/scripts/voice_index.gd — started 2026-11-21

### Up next (unclaimed — grab one by moving it up and adding your name)
- Personal side quests in the village: Lykor's hair contest, Xylo's lore class for goblin kids, Skorn's job interviews
- More roaming enemies (needs new creature art)
- Character art as it arrives (Gemini) — swap into godot/assets/characters/ with tools/key_chars.py
- Music tracks (see HANDOFF.md section 7)

### Done (recent)
- 2026-11-22 [asar] Polish: wooden signs, Esc leaves optional talks, chapter card at New Game, music play-once, keep character on travel, Skorn after the Mart, Pass rest spot
- 2026-11-22 [asar] Spoonsmithy removed, Chief's Hut closed, job board UI, real throws, golden-hour Pass + quieter snore, walk back between areas (+ Mart/Pass resume)
- 2026-11-22 [asar] Lykor no longer blocks Skorn when Skorn gets crowned
- 2026-11-22 [asar] Goblin band (drummer, horn, lute) follows you playing the village song; "Dat bih fire mud" / "Y'all could get lost?"
- 2026-11-22 [asar] Dulbers goes demon on the Mart refuse path; Diddy Chud snore (Asar's recording, louder as you get closer)
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
- [asar] godot/scripts/job_board_ui.gd, shop_ui.gd (new), trail.gd (new), trail_script.gd (new), godot/trail.tscn (new), village.gd, village_buildings.gd, camp.gd, map_ui.gd, combat/combat_data.gd, combat/battle_view.gd, level.gd, godot/assets/characters/troll.png

## Log (newest first)
<!-- - YYYY-MM-DD [who] what changed · anything the other person should know -->
- 2026-11-22 [asar] **Polish pass merged.** Hot spots: **dialogue.gd** `can_leave`/`left` (Esc ends optional talks; skips the remaining
  steps incl. `do`s; hint shows "Esc: leave"). **level.gd** `wood_sign()`, `free_roam()`, `start()` sets can_leave, `_resume` keeps your
  leader. **game.gd** `music_once` (saved in settings). area_music.gd plays a non-looping copy when Play once is on; goblin band leaves
  when the song ends. village: signs, `skornAway` (village_rooms_script uses it for who speaks; `skornKing` kept for Sludge's
  "old king" line), check_continuity knows it. title.gd: chapter line removed; camp shows a chapter card on New Game. Pass: rest
  campfire. @ebain: the Goblin Pit idea became a village shop (Asar), and Asar wants a long trail area between Camp and the Village.
- 2026-11-22 [asar] **Asar's batch merged.** @ebain, heads-up on content Asar asked to remove: **Clank's Spoonsmithy is gone**
  (building, Clank, shiny spoons + Shiny Spoons quest) and **the Chief's Hut can't be entered** (its room + dialogue: belt,
  portrait, chest, hay bed removed). Spoon Mail now drops from the Goblin Patrol; the Backup Conditioner is a pickup by a new
  bedroll (rest spot) next to the hut. Hot spots: **level.gd** `back_exit()/arrival()/_check_back_exit()` + `_resume` handles
  `travel` arrivals, dev auto-win loot lists. **game.gd** `travel()`. **combat/**: battle.gd `throwables`; battle_view.gd prop
  pile (`PILES`, `_spawn_pile`, new `_throw`), loot lists. New `job_board_ui.gd` (job postings are # DRAFT; Wuzzle's and
  Gulpo's notes are new). Pass is now golden hour (`_after_build` retunes the env; night/lava off). Walking back: Pass → Mart →
  Village → Camp and forward again once each is done; Mart + Pass resume from saves now (took that off Up next). VOICE_LINES.md
  lists the 15 Skorn lines still on the robot voice (incl. "You feel a store?" and "Metocin Mattias? What are you doing here?").
- 2026-11-22 [asar] Voice import (via voice-imports/ Action): Metocin Mattias (3: "You had called?" — also plays in camp, "*echoing* Impressive…", the Pass speech) + Demon Dulbers (3 Mart lines). All 6 matched the script; they replace the robot voice. New folders `assets/voices/mattias/`, `assets/voices/dulbers_demon/`. Touched voice_index.gd only through the Action (Ebain's giant claim untouched).
- 2026-11-22 [ebain] **Goblin voices in: 8 of Ebain's takes** (assets/voices/goblin/, voice_index.gd regenerated via import_voices.py): got a light, hiring (camp + village), hold a spoon, village up north, allowed to mog, Mogging Elf goes, A STORE. Other goblin lines still use TTS.
- 2026-11-22 [asar] **village.gd: throne fix (notes.md).** In `_crown_skorn()` Lykor stayed on SEAT_POS (scripted `walk_to` on the
  leader doesn't always move him) and Skorn sat right on top of him. Now Lykor steps off first, gets placed to the throne's left
  (SEAT_POS + (-1.9, 0, 0.7)), then Skorn walks up and sits. Gotcha in TIPS. My request above is done.
- 2026-11-22 [asar] Goblin band: new `scripts/goblin_band.gd` (GoblinBand), added by village.gd `_leave()`. They show up when free roam starts (every visit / loaded save), follow behind the trio (after goblin allies), wait at the door while you're in a building (village_buildings.gd skips units with meta `band` when teleporting followers). Talk → Ebain's "Dat bih fire mud" (keep playing) / "Y'all could get lost?" (walk into the bar, song fades out, gone until the next visit). The village song only plays while the band is around: AreaMusic got `gain_db` (village sets it from `band.gain_db`). Art: Asar's marching-band image cut into `band_drummer/horn/lute.png`. Goblin replies + labels are # DRAFT. Test: `VILLAGE_TOUR=band`.
- 2026-11-22 [asar] **Dulbers + snore merged.** mart_script.gd: the refuse path runs `{do: transform}` before Dulbers' demon
  line (notes.md). pass.gd: `snore` player loops Asar's `assets/sounds/giant_snore.ogg` while the giant sleeps, volume by
  the leader's distance to GIANT_HEAD (4 m = full, 34 m = silent, squared curve), fades out when he wakes; Snore Sneak plays
  it at full volume and pauses it on each inhale (replaces the noise burst). The throne fix is still waiting on village.gd (request above).
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
