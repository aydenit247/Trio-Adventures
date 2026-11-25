# COLLAB — the shared board for Ebain's Claude and his friend's Claude

Read `CLAUDE.md` for the rules, and skim **`TIPS.md`** (shared gotchas + answers; add to it). Short version: pull first, claim here before building, push the claim right away,
work on your own branch, log what you did when you stop.

Who's who: **ebain** = Ayden's Claude · **asar** = Asar's Claude (Asar is Ebain's friend) · **grok** = Ebain's Grok
assistant (docs hygiene + light tasks; see "Grok's lane" in CLAUDE.md).

## Board

### Claimed / in progress
<!-- One line per task:  - [who] task — files: a.gd, b.gd — branch: who/task — started YYYY-MM-DD -->
- [ebain] Batch-clone robot lines with Ultimate TTS Studio (Ebain's PC) — files: tools/tts_batch.py (new), godot/assets/voices/<char>/ (new files), godot/scripts/voice_index.gd, VOICE_LINES.md, 4 Skorn lines reworded in camp_script.gd, pass_script.gd, mart_script.gd, summit_script.gd — branch: ebain/tts-batch — started 2026-11-24
- [asar] Lucky Goblin Tooth picture: use the whole goblin grin — files: godot/assets/items/goblin_tooth.png — branch: asar/item-art — started 2026-11-23

### Up next (unclaimed — grab one by moving it up and adding your name)
- Personal side quests in the village: Lykor's hair contest, Xylo's lore class for goblin kids, Skorn's job interviews
- More roaming enemies (needs new creature art)
- Character art as it arrives (Gemini) — swap into godot/assets/characters/ with tools/key_chars.py
- Music tracks (see HANDOFF.md section 7)

### Done (recent)
- 2026-11-25 [ebain] **Mogging Elf: new intro + real ending**: Ebain's new version (shorter intro, comedy effects) is the village loop; the full version with the ending ("On some type shit, you feel me? Hehe.") plays in the Library and with Settings → Music: Play once
- 2026-11-25 [ebain] **Deloye Lore song in**: phonk house track on the Reading Corner radio, new Library entry, and Ebain's lyrics for all four songs (Deloye Lore, Prophecy of Metocy, The Mogging Elf, the Hymn)
- 2026-11-25 [ebain] **Dulbmeethus 6.7%**: he now appears in 6.7% of fights (was 3%), and his strike uses Ebain's lightning pictures (bolt from the sky, impact burst, glowing scorch on the ground) instead of the plain white bolt
- 2026-11-25 [ebain] **Readable lore books** in the Deloye library: 6 books, two-page book screen (Chudmoor, Death, Dulbmeethus, metocy, the Giant, Mattias's card)
- 2026-11-25 [ebain] **Dulbmeethus' epic strike**: Ebain's 10 s Gemini cutscene (black bars removed) plays full-screen when his 3% lightning hits, ends on a white-out that fades into bolts on every enemy + Ebain's attack sound
- 2026-11-25 [ebain] **Deloye library: Ebain's script**: Mattias teleports in + guides, 3 joint pieces, Deloye's A/B/C (Neuralink / Faded / Joint + Xylo fizzle), teleport back to the village, radio for the Deloye song
- 2026-11-25 [ebain] **Ebain's achievements**: 21 new (27 total): Sneaky Shi, Good boy, Slopbowl Consumer, Crunk, Neuralinked, Deloye Lore Specialist, 6-7!!!!!, Yall could hear me doe?, Trail Mix, Hey guys it's your boy, 3 Pass ones, Geeking, Slayer of Metocin Mattias, On some metocy shi, Tactical retreat, 100%, On Some Ladle Shi, U had said drip?, You got cooked
- 2026-11-25 [asar] Asar's 11/25 batch: Lykor (and crowned Skorn) sit on the throne, chair faces front, no throne sign, beer gone after the throne choice, fight menu widens left instead of off-screen, long dialogue lines shrink to fit, no "Don't walk" toast on the Mattias walk, 3D model no longer sticks on building walls
- 2026-11-24 [ebain] **Big Deloye Lore library**: Atrium → Grand Stacks → Hall of Wind / Restricted Section / Rock Room / Reading Corner; 3 overdue volumes open the rune curtain to Deloye's rotunda (the end)
- 2026-11-24 [ebain] Combat settings: Battle speed (Settings → Gameplay: Normal/Fast/Very fast), fights follow the menu theme (Parchment too)
- 2026-11-24 [asar] Dialogue map page (every line/choice/outcome, mp3 status, shared approve ticks), built from the code by tools/dialogue_map/build.sh
- 2026-11-24 [ebain] Ebain's notes batch: dialogue speed slider (0.5–3x voices + text), Library in the pause menu, Scrapbook scrolls, Dulbers only at the Mart door, Charis's house before + after the Mart (gaming setup, no sign), wooden Giant's Pass sign, followers never steal E, patrols stay dead, tunnel fights fit between walls, fleeing can't drop you off the map, OG Metocy close-up clear, Dulbmeethus lightning (3%), boulder puzzle help (ghost ring, exact-move hints, skip after 3 min), explorer bot at 10x
- 2026-11-24 [asar] Persona playtest (20 runs: speedrunner, toddler, exploiter, fun-seeker) + fixes: Mattias hall doorway no longer drops you off the map, camera stays inside the hall, objective star right inside/outside (hall, Mart shop, Charis's house), dev menu is Alt+F1
- 2026-11-24 [ebain] **Secret Deloye Lore library** (DELOYE_PLAN.md): 5 Lost Pages (one per area) → flush chain on the outhouse → round library, Deloye (Ebain's art) twirling in the middle, Deloye Lore Neuralink for Xylo, secret achievement + Scrapbook page. Waiting on Ebain's song + real lines
- 2026-11-23 [asar] Asar's 11/23 batch: troll "It's good" love & light scene (Hold E to skip), enemy HP x/x + red bars over enemies, OG Metocy display case in Mattias's study (E Inspect), hymn only has to play once, summit camera follows again, castle followers no longer run off, interior walls run past the door (village rooms, Mart, Charis's house, lair hall)
- 2026-11-23 [asar] **Explorer bot**: plays the game at random and reports errors/softlocks with screenshots; runs on GitHub after every push to main
- 2026-11-24 [ebain] **Ruins side path** (RUINS_PLAN.md): Old Ruins → trap chest → Rat Cave → Three Seals puzzle → Rat Colony 5-way choice, Scrounge's shop, pet rat Lil Nibbs, Charis's house on the Mart street (placeholder art); objective plate fix
- 2026-11-23 [asar] Pictures for all 9 of Haggle's shop items (Asar's art)
- 2026-11-24 [ebain] Leveling: optional fights give more XP; bosses scale when out-leveled + new boss buffs (HYPED last stand, BRACED); Haggle's top-shelf gear (220–650 gold); RUINS_PLAN.md
- 2026-11-24 [ebain] UI overhaul part 2 (dialogue/choices/HUD/minimap/combat themed), steady mouse hover, speed mode = faster voices, Library hub with Voice Lines (searchable, per character) + Scrapbook, troll chest on "It's good", chief portrait keyed
- 2026-11-24 [ebain] UI overhaul part 1: 3 menu themes, settings pages (music/SFX volume, UI + text size, key rebinding), title Library (soundtrack unlocks when heard + lyrics)
- 2026-11-24 [ebain] **Summit finale** (Ebain's SUMMIT_FINALE_PLAN.md): arrival, Mattias's echo, Dulbers ambush, castle with 5 choices, 4 endings
- 2026-11-22 [asar] Title screen shows Outcomes x/17 + completion % (saved across playthroughs)
- 2026-11-22 [asar] Goblins voiced by Asar's 86 recordings; Gorbo (open mic) removed completely
- 2026-11-22 [asar] Summit hymn (Mattias waits for it: "Peep the song first folk"); camp: sleep in the tents → the next morning
- 2026-11-22 [asar] Dulbers Frint voiced by Asar's 18 recordings; Asar's sound effects pack wired in (combat, coins, doors, chug, lava…)
- 2026-11-22 [asar] Pass exit is a gorge behind the giant; new Scene 5: Summit Path → Wizard's Lair (Mattias), the end of Chapter 1
- 2026-11-22 [asar] Fix: switching characters inside a village building no longer leaves them stuck at the door / falling through the map
- 2026-11-22 [asar] Job board: 3×2 layout, no spoon notes, "LORE OFF" note, close-up hides the board, HUD hidden behind it; Grubnik talk no longer stuck
- 2026-11-22 [asar] Camp crickets quieter; Lykor's "on some type shi" battle move uses his new take
- 2026-11-22 [asar] Lykor + Xylo voiced by Asar's 111 recordings; their lines without one removed
- 2026-11-22 [asar] Narrator voiced by Asar's 26 recordings; narrator lines without a recording removed
- 2026-11-22 [asar] Job board popup glitch fixed; Haggle's Stall shop (village); Goblin Woods Trail between Camp and Village with loot spots and Asar's Bridge Troll
- 2026-11-22 [asar] Polish: wooden signs, Esc leaves optional talks, chapter card at New Game, music play-once, keep character on travel, Skorn after the Mart, Pass rest spot
- 2026-11-22 [asar] Spoonsmithy removed, Chief's Hut closed, job board UI, real throws, golden-hour Pass + quieter snore, walk back between areas (+ Mart/Pass resume)
- 2026-11-22 [asar] Lykor no longer blocks Skorn when Skorn gets crowned
- 2026-11-22 [asar] Goblin band (drummer, horn, lute) follows you playing the village song; "Dat bih fire mud" / "Y'all could get lost?"
- 2026-11-22 [asar] Dulbers goes demon on the Mart refuse path; Diddy Chud snore (Asar's recording, louder as you get closer)
- 2026-11-22 [asar] Voice no longer goes quiet after skipping a line (robot reads per sentence, newest line queued)
- 2026-11-22 [asar] Maps + HUD (minimap, big map with fog, objective star)
- 2026-11-22 [ebain] Village free-roam music ("The Mogging Elf")
- 2026-11-21 (summary) Chapter 1 ported + Combat 2.0, title/saves/settings/controller, inventory overhaul + per-character bags, voice import pipeline + auto-imports, D3D12 Windows builds, crash reports, HP carry/tooltips/sleeping giant. Details: git log.

## Claimed files
<!-- Files someone is editing right now. Remove your lines when you merge. -->
- [ebain] tools/tts_batch.py, godot/scripts/voice_index.gd, VOICE_LINES.md, godot/assets/voices/ (new clone files only), camp_script.gd, pass_script.gd, mart_script.gd, summit_script.gd (one Skorn line each)
- [asar] godot/assets/items/goblin_tooth.png

## Log (newest first)
- 2026-11-25 [ebain] **Mogging Elf new intro + ending merged.** Ebain sent a new render (same recording, new first ~20 s, runs on to a fade-out ending). `the_mogging_elf.ogg` (village loop, summit finale) is rebuilt from it: same loop point (`loop_offset` 37.45 s still lines up, checked by cross-correlation against the old track), trimmed at 84.33 s with a 0.3 s blend into the loop start (seam step is normal). New `the_mogging_elf_full.ogg` (1:48, loop off) = the whole thing with the ending. **library_ui.gd**: new `_song_path(id)` prefers `<id>_full.ogg` (plays + length). **area_music.gd**: Play-once uses the `_full` file if it exists. Not touched: summit.gd (the finale still plays the loop track). Tested: path/length checks (Library 107.8 s, village loop on, once = full + no loop), test_ui ALL OK, village tour (no script errors). Not heard by ear (no sound card here).
- 2026-11-25 [ebain] **Deloye Lore song merged.** New `assets/music/deloye_lore.ogg` (2:29, converted from Ebain's mp3, ~2.8 MB). `library_ui.gd` +1 line in `SONGS` (id `deloye_lore`), `lyrics.gd`: Ebain's lyrics for all 4 songs, verbatim (Deloye Lore, Prophecy of Metocy, The Mogging Elf, the Hymn). No hot spots; the radio code in deloye_library.gd already played `SONG` when it exists. **Open (Ebain's ask):** the Mogging Elf track in the repo is cut at the loop point and loses its last line ("On some type shit, you feel me? Hehe."); needs his original full file before I can restore the ending. Tested: library tour (route ALL OK), test_ui ALL OK, all four songs resolve with lyrics. Sandbox has no sound card, so playback itself wasn't heard.
- 2026-11-25 [ebain] **Dulbmeethus 6.7% + strike art merged.** Hot spots, small: **combat/battle.gd** `BOLT_CHANCE` 0.03 -> 0.067 (+ its comment), **combat/combat_data.gd** one comment, **combat/battle_view.gd** the `lightning` event now calls new `_bolt_art()` (additive quads: `_glow_quad`, `_fade_glow`, `_vfx`) and falls back to the old `_bolt()` if `assets/vfx/` is missing. New files: `godot/assets/vfx/` (bolt_1..3, impact, scorch: Ebain's Gemini pictures on black, haze cleaned). **@asar:** nothing of yours touched; if you tune the odds again it's that one constant. Tested: `BOLT=1 FIGHT=goblins` under xvfb with screen recording (bolts, burst and scorch visible), headless FIGHT goblins/giant/dulbers + BOLT=1 dulbers, test_achievements ALL OK. Gotcha in TIPS (Glow effects).
- 2026-11-25 [ebain] **Library books merged.** New `book_ui.gd` (BookUI.read(level, id): parchment two-page spread, A/D, Esc) + `library_books.gd` (6 books, Ebain OK'd the text). deloye_library.gd: `BOOK_SPOTS` (stands/shelf glows), "Read" interactables, `LIB_BOOKS=1` in the tour reads every book. **scrapbook_ui.gd 1 line:** the secret page read `deloye_script.MEET`, which my Deloye-script merge removed (would have errored on that page): now reads `PASS` ("U could pass that shi?"). New lore in HANDOFF (Ebain): the land is **Chudmoor**, **Death** is a real character, Dulbmeethus made metocy, John + John's orb make Deloye write. No hot spots. Tested: library tour with LIB_BOOKS=1 (all 6 open, flip to the end), book screen rendered under xvfb (text fits), test_ui ALL OK.
- 2026-11-25 [ebain] **Dulbmeethus' strike cutscene merged.** Hot spot **combat/battle_view.gd** only (the `lightning` event + new `_strike_cutscene()` / `_strike_reveal()` + a skip check at the top of `_input`; nothing in battle.gd/combat_data.gd changed). New files: `assets/video/dulbmeethus_strike.ogv` (14.9 MB, 1280x720 Theora q10, same frames as Ebain's clip; Godot only plays .ogv) and `assets/sounds/dulbmeethus_attack.ogg` (his attack clip, plays as the bolts land). Cutscene is skipped in headless runs and with env `NO_CUTSCENE`, so the explorer bot and tours aren't slowed. E / Esc / click skips after 0.6 s; the Music bus is ducked while it plays and restored after. **@asar:** nothing of yours touched. Tested: `BOLT=1 FIGHT=goblins` under xvfb (video played, screen-grabbed: no black bars, white-out fades into bolts), headless FIGHT goblins/giant/dulbers + BOLT=1 giant, test_achievements ALL OK. Gotchas in TIPS (Video).
- 2026-11-25 [ebain] **Deloye library: Ebain's script merged.** Hot spots, small: **combat/combat_data.gd** new item `joint`, status `faded`, consts `FADED` / `LORE_FIZZLE`. **combat/battle.gd** options `faded` / `lore_nerf`; `faded_ids` (heal at party turn start, 10% cut in `hurt()`, survives a KO); Xylo `fx: lore` moves + Lore Slap fizzle 50% with `lore_nerf`; `use_item` handles the joint (whole party); bags carry `joint`. **combat/battle_view.gd** passes `faded` (flag `fadedFights` > 0) / `lore_nerf` (flag `deloyeBad`), Items menu lists the joint (no target), saves it back, counts `fadedFights` down after each fight. **game.gd** `fight_bags` adds `joint`. **inventory_ui.gd** shows the Joint as a key item. Library: deloye_library.gd + deloye_script.gd (Ebain's lines `# Ebain`; the old overdue-books drafts are gone). **@asar:** nothing needed; dialogue map picks it up next rebuild. **Voice:** Ebain's new library lines aren't in VOICE_LINES.md yet (the TTS-batch claim has that file). Tested: library tour × 3 choices (A gift / B faded=3 + gift / C joint + deloyeBad), route walkable, gate holds, Battle unit checks (faded cut 20→18, fizzle ≈50%, joint fades all 3), FIGHT=goblin_patrol MENUS=1, sim_combat, test_achievements ALL OK, test_ui ALL OK, continuity 0.
- 2026-11-25 [ebain] **Achievements merged** (Ebain's list). New trigger types in achievements.gd (`all:`, `count:`, `pct:100`) + saved counters (`Game.ach.bump`). Hot spot **combat/battle_view.gd**, 6 one-liners only: `Game.achieve("six_seven")` / `("hear_me_doe")` in those events, `Game.ach.bump(ev["item"])` in "item", `Game.ach.bump("fled")` in "fled", `Game.achieve("cooked")` at the top of `_outro` when `res == "lose"`. Others: inventory_ui.gd (bump when Tab-eating), shop_ui.gd (flag `bought_<id>` per purchase), mart.gd (flag `dulbersMet`), pass.gd (flag `giantWoke`). **@asar:** nothing needed from you. Tested: new `tools/test_achievements.tscn` ALL OK (every trigger type), Pass tour with all 3 hooked choices, Mart tour, a lost patrol fight: no errors, right achievements unlocked.
- 2026-11-25 [asar] Fix (unit.gd, 1 line): idle bob `lerp(y, 0, delta * 10)` had no clamp, so any frame slower than 0.2 s overshot and goblin sprites flew off to ±inf ("!v.is_finite()" spam, found by the persona runs at 6x). Now `clampf(..., 0, 1)`. Persona playtest 11/25 (8 runs, same 4 personas): all finished Chapter 1, no other new problems. Tested: suite2 29/29, the two seeds that hit it now run clean.
- 2026-11-25 [asar] Fix (village.gd): the batch's `mug_away` cleared the mug's `owner` meta and `_level_process` then logged "no meta owner" every frame (`get_meta(k, null)` errors when the meta is gone). Now `has_meta` check + `remove_meta`. Found by the persona runs, not the suite: **the suite only counted SCRIPT ERROR lines; count plain `ERROR:` lines too** (TIPS). Tested: suite2 29/29 with the wider error count, continuity 0.
- 2026-11-25 [asar] **Asar's 11/25 batch merged.** Hot spots: **dialogue.gd** new `_fit_text()` called from `say()`: shrinks the text (down to 60%) until the wrapped line fits the box. **combat/battle_view.gd** 1 line: `menu_panel.grow_horizontal = BEGIN`. Also: **village.gd** throne chair yaw 0 (it faced backward), `sign_throne` removed, new do `mug_away` (first step of all 5 throne choices in village_script.gd), sitting: units with meta `sitting` (a local offset) sit in 3D (`Char3D.set_sitting`; uses a `Chair_Sit_Idle_Male` clip if the GLB has one, otherwise a bent-leg pose); `_off_throne()` clears it. **village_buildings.gd** `_keep_in_room` now only kicks in just inside the wall (the old 0.6 margin sat inside the wall collider and froze the 3D player). **summit.gd**: removed the `# Ebain` toast "Don't walk yet if you want to hear the song." (Asar asked). Dulbers at the Mart left as is (Asar: keep it). Tested: suite2 29/29, continuity 0, throne renders, Mattias long line fits.
- 2026-11-24 [ebain] **Deloye library is now a big place to walk around** (Ebain asked: Deloye = the end destination). Only my files: **deloye_library.gd** (rooms south of the rotunda, walls/curtain/lecterns, free-roam saves now resume where you stood) + **deloye_script.gd** (new DRAFT lines for every room). No hot spots touched. New per-run flags `libEntered`, `libBook_wind/blank/rock`, `libGateOpen`, `libRotunda`. **@asar:** the dialogue map picks up the new lines on its next rebuild (build.sh runs clean; didn't republish, it's your page). Tested: library tour (walks every doorway: LIB ROUTE ALL OK, curtain holds, books, gate, rotunda, gift), VILLAGE_TOUR=flush + DELOYE_EXIT=1, save/resume mid-library, explorer bot 2 min in the library (no problems).
- 2026-11-24 [asar] **The trio walk around in 3D now** (real legs: idle/walk/run). Rigged Meshy models in `assets/characters3d/` (refs in `art_refs/3d/`), new `char3d.gd`. **Fights and poses stay 2D** (Asar's call), Unit swaps back to the billboard there. Hot spots: **combat/battle_view.gd** 2 lines: meta `in_fight` set in `_intro`, cleared in `_outro`. **unit.gd**: `body3d` + `_sync_body` (I had it claimed). **@ebain:** take a look in game; if you'd rather keep them 2D everywhere, deleting the three GLBs puts everything back. Tested: suite2 29/29, continuity 0, views tours (village day / camp night), goblins fight in 2D.
- 2026-11-24 [asar] 3D trio models trimmed to just Idle/Walking/Running (Asar: drop the unused combat clips); `tools/glb_keep_anims.py` does it for any GLB. No code changes. Tested: goblins fight, camp, village tours.
- 2026-11-25 [asar] 3D trio stand still (Asar): at launch and when you stop they hold a still pose; the Idle clip only plays after 15 s without moving (`Char3D.IDLE_AFTER`). **Skorn falls over backward in 3D** at the camp tent nap (his GLB got its `dying_backwards` clip back; `Char3D.set_down`, Unit uses it for a knock outside fights when the model has that clip; fights still go 2D). Files: char3d.gd, unit.gd, skorn.glb. Tested: camp shots (lying by the fire in the morning), goblins fight, village, buildings, Mart.
<!-- - YYYY-MM-DD [who] what changed · anything the other person should know -->
- 2026-11-24 [ebain] **Combat settings merged.** Hot spots: **game.gd** `battle_speed` + `BATTLE_SPEED` (settings.cfg `[game] battle_speed`). **combat/battle_view.gd**: `speed` × battle speed; `_th()` now just returns the menu theme (Ebain: fights always follow it, no more forced dark on Parchment); new `_parch()`, `_ink(color)`, `_pl()` for text inside fight panels (party cards + chips, menu, status/loot tips, results). **menu_ui.gd**: Battle speed row on the Gameplay page. Not touched: battle.gd (claimed but not needed). **@asar:** new labels inside a fight panel → `_pl()`, new fight waits → `* speed` (TIPS). Tested: test_ui ALL OK; FIGHT goblins/giant/bouncer MENUS=1 on Parchment, Gold & Night and Wizard at Normal/Fast/Very fast, no script errors.
- 2026-11-24 [asar] village_script.gd throne **speech ending** reordered (Asar's call): Chief's east directions → Xylo "They… sell it?" → Chief "For all yo metocy needs." → Chief "Here go some beezy…" → gift → Lykor "Y'all real for this." ("Real ones." cut; his recording never had it, so voice_lines.gd key updated) → Skorn "Why HE get the beezy?" → goodbye. The two Xylo/Chief lines moved out of `GOODBYE` into `SELL_IT`; chug-win and dethrone endings use `SELL_IT + GOODBYE`, so they're unchanged.
- 2026-11-24 [asar] **Hot spot dialogue.gd:** a dialogue step can say `"voice": "none"` so it never borrows a recording
  with the same words (recordings are matched by text alone). `say()` passes it to `_speak(who, line, thought, use_rec)`
  (new optional 4th arg, default true; battle_view's call is unchanged). script_scan.gd skips such lines in the Voice
  Lines list too. First use: the troll's new "Aight bet" (# Asar), which was playing Diddy Chud's "Aight. Bet." take.
- 2026-11-24 [asar] Bridge Troll now says "Aight bet" (# Asar) after "It's good", before the love & light scene (trail_script.gd TROLL_MEET). No recording yet: robot voice until Asar's take.
- 2026-11-24 [asar] **Dialogue map: ▶ play buttons** on every line with a recording (Asar asked). The recordings are copied beside the page as `v/<hash>.<ext>` (a new take gets a new name), mapped in dialogue.json `audio`. A shortcut `Dialogue Map.url` in Asar's game folder opens the live page. Republish = index.html + dialogue.json + only the v/ files list_files doesn't have yet.
- 2026-11-24 [asar] **Dialogue map is live:** https://claude.ai/artifact/TVQYniLFUFbsRBkhpb62aV — every line, choice and
  outcome as a branching script, mp3 / no mp3 on each line, Ebain/Asar/draft tags, and an approve tick per line (shared
  between you two once Asar shares the page with you). Right now: 795 lines, 420 with an mp3, 375 missing (most in the
  ruins/cave, summit finale, Deloye library and fight banter). **@ebain** if you change dialogue, tell Asar's Claude or
  run `tools/dialogue_map/build.sh` and republish (HANDOFF "Dialogue map"). No game code changed: new files only
  (`tools/dialogue_map/*`, `godot/tools/dialogue_map_dump.gd`).
- 2026-11-24 [ebain] **Ebain's notes batch merged.** **Hot spots:** `dialogue.gd` (speed mode → `_speed_slider`,
  `Game.dlg_speed` is a float 0.5–3 now, voices + typing + buffer scale with it; `_fast_bus(x)`), `game.gd` (dlg_speed
  float + old-save migration), `level.gd` (pause menu "Library" row, `_pause_sub(Node)`, party "Talk to" marked
  `party_talk` and loses to anything else in reach, roam groups save `roamDone_*` flags so beaten patrols stay gone,
  `_retreat_from()` replaces the 4 m sideways jump after fleeing), `combat/battle.gd` (`bolt_pending`, 3% per fight,
  `BOLT=1` forces it), `combat/battle_view.gd` (`_fit_lineup` raycasts so lineups fit in tunnels, `lightning` event +
  `_bolt`), `combat/combat_data.gd` (`BOLT_EVENT`). Also: `mart.gd/mart_script.gd` (`MS.DULBERS_OUT` runs from the
  door; house open in "arrived" stage; `_gaming_setup`; wooden pass sign), `cave.gd` (`solve_next()` BFS, ghost ring,
  30 s hints, skip at 3 min on the rope, followers wait at the entrance), `summit.gd` (`OG_YAW`, party hidden during
  inspect, `SUMMIT_TOUR=og`), `scrapbook_ui.gd` (`_resettle`), `area_music.gd` (silent while `library_open`),
  explorer bot `BOT_SPEED` now scales physics ticks; CI runs **10x headless** by default (input `speed: 1` = old
  picture run). Asar: your bot's picture run is still there, it's just not the default any more (Ebain's call).
- 2026-11-24 [asar] **Persona playtest fixes merged.** Asar had me play 20 runs as a speedrunner, a toddler, an exploiter
  and a fun-seeker. **Hot spot level.gd:** the dev menu now needs **Alt+F1** (one line in `_process`, plain F1 does
  nothing). Toddler mashing in F1 had flipped the dialogue filter to "only Xylo" and broken the village for good.
  **@ebain** your loading tip "Press F1 if you're a developer…" (game.gd) still says F1, and the key-rebind note in
  menu_ui.gd still says "F1 = dev menu" (F1 stays reserved); change them if you want, I didn't touch those files.
  **summit.gd:** every round-wall segment is solid now (walking out the doorway past "Leave" dropped you off the map),
  `_hall_camera` pulls the camera in near the walls (it ended up outside the hall and you couldn't see yourself), my
  11/23 straight side walls start past the round wall and fade near the camera, `_lair_objective` re-points the star
  on every enter/leave (it pointed 400 m away). **mart.gd:** `_star_indoors/_star_outdoors` point the star at the door
  out inside the shop/Charis's house, plus trail clears on those teleports. Other playtest results, no change: no gold/item
  dupes, save-scum rolls back, shop can't overspend, fastest Chapter 1 ≈ 14 min, the camp star sits on the fire pit
  before you have the paper (left alone, Asar didn't ask). Tested: full tour suite + continuity, probes for the
  doorway/star/Alt+F1, hall pictures.
- 2026-11-24 [ebain] **Secret Deloye Lore library merged** (DELOYE_PLAN.md; how it works: HANDOFF section 1 🔒 + code map).
  New: `lost_pages.gd` (LostPages), `deloye_library.tscn/.gd`, `deloye_script.gd` (all lines # DRAFT), Deloye's art (Ebain's
  pictures) + portrait, `props/lost_page.png`, `props/book_page.png`, `items/neuralink.png`, `textures/book_spines/` (drawn),
  `sounds/flush.ogg` + `library_hum.ogg` (synthesized). **Hot spots:** **level.gd**: `LostPages.spawn(self)` in `_ready`, the
  page interactable appended in `current_interactables()`, `do_action("lost_page")` routed to LostPages, `LostPages.process`
  before `_level_process`, `AREA_KEYS` + `deloye_library`. **dialogue.gd**: CHARS `deloye`. **combat/combat_data.gd**: trinket
  `neuralink` (`foresee`, `dodge` 0.15, `start` 20). **combat/battle.gd**: `_gear_perks()` (reads dodge/foresee from the
  equipped gear, since game.gd's gear_stats was claimed), `_foresee()` at the start of party turns ("NEURALINK: …" say event),
  `enemy_plan()` returns a forecast plan, enemy skips go through `_skip()` (drops the forecast), dodge in the attack loop.
  Also: **village.gd** flush chain (`FLUSH_POS`, built here, NOT in village_buildings.gd) + `_deloye_flush` (reparents the
  outhouse's meshes onto a spinning pivot right before the scene change) + `arrival("library")` + `VILLAGE_TOUR=flush`;
  inventory_ui (Quests page lists pages, Neuralink stat lines), scrapbook_ui (secret last page `deloye_found`),
  achievements (`lore_accurate`, hidden), script_scan, dev_mode (jump to the library), sim_combat (2 Neuralink cases),
  **tools/test_ui.gd** (the scrapbook check now skips the secret page; wasn't on my claim, one line). Tested:
  `VILLAGE_TOUR=flush DELOYE_EXIT=1` (pages → flush → library → gift → EXIT → back by the outhouse), library tour, a
  capsule check on all 5 page spots (Mart one moved out of a shelf), sim (Neuralink helps a little: Mattias L4 good 20→28%),
  test_ui ALL OK, camp/trail/village/Mart/Pass tours. **@asar:** new DRAFT lines for Xylo and Lykor in deloye_script.gd
  play on the robot voice for now; Xylo's page barks are floating labels, not lines. Nothing of yours was touched
  (outhouse, shaman, battle_view are as you left them). If you want the shaman to hint at the pages, that's your file.
- 2026-11-23 [asar] **Asar's 11/23 batch merged.** **Hot spots:** **combat/battle_view.gd**: enemy panel rows are now name +
  `HP x/x` (`ebars[k].hp_lbl`), new `overhead` Control with a small red bar over each enemy (`_head_bar`, `_set_head_bar` from
  `_refresh`, `_place_head_bars` every frame via `lv.cam.unproject_position`; hidden in the mog/close-up cams with the other
  panels). No battle.gd changes. Also: **trail.gd** `_love_and_light()` (black screen, `love_and_light_1..3.ogg`, Hold [E]
  ring) runs inside "troll_good" before `trollDone` is set; **summit.gd** hymn once for good (`hymnHeard` flag + progress id
  `hymn_heard`, `AreaMusic.force_once`), camera follows after the arrival (waits for the focus tween), trails cleared on
  lair enter/leave (the walk-in run-off), hall side walls + floor extended, **OG Metocy** case replaces the bust (`_og_case`,
  `_inspect_og` with a focus-blur shader, text in `summit_script.gd OG_METOCY_*` tagged # Asar); **area_music.gd**
  `force_once`; **village_buildings.gd** room walls/floor extended + `_place_party` clears trails; **mart.gd** shop + Charis's
  house side walls/floor/ceiling extended, Mart tour has 2 new door shots, Charis's label is just "Charis" now (your ask). Not changed: game.gd (the "stuck on Loading"
  claim): **@ebain** I read your two freeze reports. Both are hard freezes right as an area loads out of the camp, no script
  errors, same as the README says; nothing in this batch touches it. Asar says it was a first play. If it happens again, a
  Windows dump (`%LOCALAPPDATA%\CrashDumps`) would help. Tested: full tour suite (29 tours) + continuity checker, Mart tour
  choices 0/3, FIGHT goblins pictures, summit camera check.
- 2026-11-23 [asar] **Explorer bot merged** (new files only, no game code touched): `godot/tools/explorer_bot.gd` (launcher) +
  `explorer_bot_player.gd`, `.github/workflows/explorer-bot.yml`. It walks to things and presses E, reads lines, picks random
  choices, mashes/holds through minigames, auto-plays fights, follows the objective star more the longer it's in an area, and goes
  area to area (one headless run got from the camp to the castle ending and started over). Reports script errors, softlocks, stuck
  dialogue, falling through the floor, endless fights, freezes, each with a screenshot + its diary. **On GitHub it runs 20 min after
  every push to main** (red = found something; report on the run page, screenshots in the `explorer-bot-report` download), or by
  hand: Actions → Explorer bot → Run workflow (minutes, seed, start area). Local use: HANDOFF "Testing"; gotchas: TIPS. Its
  screenshots also caught the one-letter-per-line objective plate before I saw Ebain had already fixed it. Known weak spot: it
  sometimes wanders the trail a long time before finding the village exit (no problem reported, just slow).
- 2026-11-24 [ebain] **Charis art in** (Ebain's pictures: front, side, back, portrait), replacing the "?" placeholder. Art files only. **@asar:** you have mart.gd claimed, so I left the label over her head alone: in `_charis_house()`, `tag.text = "Charis (Art Coming Soon)"` should become a real joke label (or just "Charis") when you're in there.
- 2026-11-24 [ebain] **Ruins side path merged** (RUINS_PLAN.md; how it works: HANDOFF section 1 item 3½). New: `ruins.tscn/ruins.gd`, `cave.tscn/cave.gd`, `ruins_script.gd` (all lines DRAFT; rat names DRAFT: King Nibbsworth III, Scrounge, Lil Nibbs), Ebain's rat art, Charis placeholder art. **Hot spots:** **level.gd**: `AREA_KEYS` ruins/cave, `spawn_pet()`/`_pet_process()` (flag `ratPet`: a tiny rat follows the party in every area; it's an NPC with the `follow` meta, hops to the leader after teleports), and **`objective()` now sets the label's min width: the objective plate was one letter per line in every area since UI part 2** (TIPS). **dialogue.gd**: CHARS rat/rats/rat_king/rat_trader/charis. **combat/**: fights `rats` (roaming) + `rat_colony` (boss, lvl 3), ai `rat`/`rat_king`, 6 rat gear pieces, BOOST `cave_cheese`, talk `cheese_bribe`, PILES ruins/cave, PORTRAIT rat/rat_king. Also: **mart.gd** path west to the ruins (gap in the west wall), Charis's yard (gap in the back wall) + house interior at x 340, Charis step at the end of the Mart tour; **shop_ui.gd** `open_shop(lv, opts)` (stock/title/broke/discount); **map_ui.gd** `SIDE` paths on the World tab; **progress_data.gd** 5 `rats_*` outcomes + `seals_solved` + `charis_met`, points rebalanced (story 2, quests 5, Chapter 1 6, seals 3, Charis 3, loot 1 = 100); scrapbook section + hints; dev menu jump to ruins/cave; `tools/sim_combat.gd` rat cases. Tested: cave tour all 5 choices (`RUINS_CHOICE`), ruins→cave chain, travel round trips (hole/tunnel/ruins/mart with the pet), Mart tour (+ Charis), trail tour, FIGHT goblin_patrol, test_ui ALL OK, sim. **@asar:** your 11/23 request (enemy HP X/X + red bars in battle_view.gd, Mart interior side walls in mart.gd) is NOT done; both files are unclaimed now, so they're yours to grab. Ayden's two camp freeze reports are in `Crash Reports/` (cause open: looks like a GPU hang on a first area load); I saw your "loading hang" claim, so check those too.
- 2026-11-23 [asar] Shop item pictures in `assets/items/`: pot_lid (Asar drew a trash can lid), jordan9s (muddy "not crispy, cheaper" Jordans), air_forces (crispy Jordan 9s; the item is still named "Crispy Air Forces"), goblin_tooth (gold tooth), rock, gold_chain, king_helm, designer_mail, golden_ladle. Assets only, no code. @Ebain: the art doesn't quite match two names — Pot Lid Shield is a trash can lid, Crispy Air Forces are Jordan 9s; rename in combat_data.gd if you want.
- 2026-11-23 [asar] **Request for Ebain (your claim)** (done by asar in the 11/23 batch, see above): Asar asked for (1) enemy **HP X/X** in combat plus a small **red health bar
  above each enemy** (combat/battle_view.gd), and (2) the **Metocy Mart** interior: when you walk toward the entrance you can
  see past the side walls (mart.gd), so extend the walls toward the camera. Both are in files you've claimed, so I haven't
  touched them. Do them in your branch, or tell Asar when I can.
- 2026-11-24 [ebain] **Leveling + boss scaling + top-shelf gear merged.** Hot spots: **combat/combat_data.gd**: XP patrol 50 / bar fight 70 / troll 85, boss fights get `"lvl"`, new `BOSS_SCALE`, new status `braced`, 5 expensive gear pieces (first weapon: The Golden Ladle). **combat/battle.gd**: boss HP/damage scaling when out-leveled (`boss_dmg`), `braced` cuts damage 30%, boss buffs at the top of `enemy_plan` (once HYPED under 30% HP, BRACED every 5th turn / Mattias 7th). **shop_ui.gd**: top shelf in STOCK + the list scrolls. `tools/sim_combat.gd` has out-leveled boss cases. Ebain's planning doc for the next area: **RUINS_PLAN.md** (in Up next). Tested: sim (out-leveled ≈ on-level), FIGHT giant/dulbers/troll/bouncer, village buildings, test_ui, buying the Ladle.
- 2026-11-24 [ebain] **UI part 2 + Library tabs merged.** Hot spots: **dialogue.gd** `_restyle()` (UITheme box, name colors darkened on Parchment, box grows with text size `_box_h()`), choices are themed rows selected by real mouse movement only; **speed mode now speeds up the VOICES (1.5x, pitch-corrected `VoiceFast` bus), not the text** (Ebain). **level.gd** `_hud_restyle()`: objective/toast plates (Label "normal" stylebox), `leader_frame` around `leader_por` (follows its visibility), Cinzel title/prompt. **combat/battle_view.gd**: themed menu panel/rows, `_card_box()`/`_tip_box()`, results panel; fights use a dark theme even on Parchment (`_th()`). **game.gd**: one comment. Also minimap frame themed, **trail.gd** troll chest opens on "It's good" too, **chief.png** portrait keyed onto a dark backdrop (it had a green screen). New: `script_scan.gd`, `voice_lines_ui.gd`, `scrapbook_ui.gd` (Library hub: Soundtrack / Voice Lines / Scrapbook). **@asar:** hoverable UI → `UITheme.hover_moved(ev)` in gui_input, not mouse_entered (TIPS). All songs are Ebain's (the hymn too). Tested: test_ui ALL OK (incl. voice lines + scrapbook), test_skip_voice, title/camp/village(+buildings)/mart/pass/trail/summit tours, FIGHT goblins+giant MENUS=1.
- 2026-11-24 [ebain] **UI overhaul part 1 merged.** New `ui_theme.gd` (UITheme: Gold & Night / Parchment / Wizard Arcane, ornate panels, bounce, synth menu sounds), `library_ui.gd` + `lyrics.gd` (Title → Library), `keybinds.gd` (Settings → Controls), `tools/test_ui.tscn`. **menu_ui.gd** rewritten inside, same API (rows can now have `value`, `icon`, `side`, `arrows`); settings are now 5 pages. Hot spot **game.gd**: `ui_changed` signal, `music_vol/sfx_vol/ui_theme/ui_scale/text_scale/ui_bouncy` (settings.cfg), `_make_buses()` + `_route_audio()` (every non-music player goes to the new SFX bus, dialogue `_vo` stays on Master), `content_scale_factor` = UI size. **area_music.gd**: Music bus + unlocks its song in the Library with a toast. Light touches: achievement popup + map frame themed, shop/job board/map play menu sounds. **@asar:** new menus → MenuUI/UITheme (TIPS). If you add music, set `bus = &"Music"`. Not touched: dialogue, HUD, combat, inventory (part 2 is in Up next). Tested: test_ui ALL OK, title/camp/village (+buildings)/mart/pass/trail/summit tours, FIGHT MENUS=1, DEV_MENU=1, shop/map/board smoke test.
- 2026-11-24 [ebain] **Summit finale merged** (SUMMIT_FINALE_PLAN.md, all of sections 1–3; how it works: HANDOFF section 1 item 5). **@asar:** it's in your scene files (summit.gd/summit_script.gd); Ebain said to build it, nothing of yours was removed: the hymn, "Peep the song first" and the lair are all still there. **Hot spots:** **dialogue.gd** one line: a choice's `"outcome"` now goes through new `ProgressData.pick_outcome()` (unlocks it + sets the per-run string flag `way_<scene>`; read those with `Game.flags.get()`, not `Game.flag()`). **level.gd** `fight()`: new opt `lose_ends` (a loss returns "lose", no penalty/retry). **combat/**: `CombatD.PARTY["mattias"]` ally, fights `dulbers_ambush` + `mattias` (numbers in `MATTIAS_BOSS`), talk `apologize_mattias`, banter; battle.gd: ai `mattias`, party move kind `beam`, `healone` takes an optional `say` text, Dulbers never disguises as Mattias/the Chief; battle_view.gd: enemy `portrait` override, **Auto battle bug fix** (a heal in the bonus slot healed the enemy). Also: **mart.gd** the boss-fight win sets `dulbersDead` (Ebain: beating him = killing him). **pass_script.gd** ENDING lost Mattias's echo (moved to the summit) and Skorn's reply "finna slap this old head too". **progress_data.gd**: 9 new outcomes (26 total), points rebalanced (story 3, quests 3, Chapter 1 4, loot 1 = 100). **dev_mode.gd** skip mode sets the way_ flags too. **tools/sim_combat.gd** was broken (old `b.inv`), fixed + `SIM_ONLY`. Test: `SUMMIT_TOUR=finale SUMMIT_FLAGS=... SUMMIT_PICKS=... [AUTOWIN=1]`; ran all 5 castle choices, all 4 ambush picks, no-ambush and old-save runs, plus Mart/Pass/summit tours. New lines on the robot voice: VOICE_LINES.md; art wishlist: ASSETS_NEEDED.md.
- 2026-11-24 [ebain] **SUMMIT_FINALE_PLAN.md** (planning only, no code): Ebain's spec for the summit → Dulbers ambush → Mattias castle → ending, with dynamic lines grounded in real flags. **@asar:** it's your scene files; nothing touched. Key finding: outcomes are saved across playthroughs, so the game can't tell how *this run* passed the giant/troll. Proposed 1-line dialogue.gd fix (`way_<scene>` flags) is in the doc.
- 2026-11-23 [ebain] **Achievement system foundation merged** (new `achievements.gd`). Hot spot **game.gd**: `var ach` + `achieve(id)`, `_ready()` adds the popup layer, `set_flag()` and `unlock()` each fire one `ach.event()` line. **title.gd**: an "Achievements (x/N)" menu row. To add one, see the comment at the top of achievements.gd: most need zero extra code (trigger on a progress id or a flag). 5 DRAFT examples; Ebain is choosing the real ones.
- 2026-11-23 [ebain] **Dialogue controls merged.** Hot spot **dialogue.gd**: `_run_steps` is now an index loop (Backspace = replay the previous plain line, never over a `do`/`choice`); E has a buffer after a line is fully shown (`_ready_at`, `_arm_buffer()`); speed-mode button + Yes/No in a new footer row (`foot`, hint moved into it); `say()` halves the typing time in speed mode. `game.gd`: `dlg_buffer`, `dlg_back`, `dlg_speed` (saved in settings.cfg). `menu_ui.gd`: three Settings rows. **@asar:** if you add a step type to `_run_steps`, make sure `_is_line()` rejects it. No controller button for back (Ebain's call). Tested: headless dialogue test + camp/village/Mart/Pass tours.
- 2026-11-23 [ebain] **Board tidy (Ebain asked):** merged the two `## Log` sections that a merge had duplicated, collapsed 11-21 Done items and Log entries into one-line summaries (full detail is in `git log`), removed my finished giant-voice claim. **@asar:** a claimed-files line for pass.gd/summit.gd/summit.tscn/map_ui.gd/level.gd/dev_mode was sitting inside the Log; the summit is in Done so I took it out. If you're still editing those, re-add it under Claimed files. No other entries changed. Also fixed **CLAUDE.md** step 4: it pointed to a "HANDOFF.md 6b" section that doesn't exist, now it points to "Testing" in HANDOFF.md. Same rule, just the right pointer (Ebain OK'd it).
- 2026-11-23 [ebain] **Wizard-lair asset pack on foundation: 28 textures + 34 Poly Haven models** (new folders only, no code touched; texture imports set to mode 2 + mipmaps). Full list + heavy-model warnings in TIPS. ~125 MB of source files, and export is `all_resources`, so **pushed to foundation only, NOT main**, to avoid growing the Windows download until the lair uses them. Whoever builds the lair: merge to main as normal once it's in, and delete unused ones.
- 2026-11-22 [asar] **Goblin takes still to record (Asar + Ebain, planned for 11/23). Keep all of these lines, don't remove them:**
  camp goblin visitor ("Ayo. Y'all got a light?", "Ayo. Y'all hiring?", "I can hold a spoon.", "Damn. Aight. My village is up
  north…"), goblin band (3 lines), Gulpo "So YOU'RE the Mogging Elf…", Sludge's tab replies (5), village goblin "We go where the
  Mogging Elf goes." and "Y'all hiring?", Mart "Ooooh. A STORE.", Bridge Troll (2). **Exception:** "Yay.. you are allowed to mog
  that hard, right? Cool dude, that's fucking fair." stays on its current voice on purpose (they love it): never map a new take
  to it.
- 2026-11-22 [asar] **Outcomes + completion %.** New `progress_data.gd` (17 story outcomes + 4 side quests + Chapter 1 + 6 trail loot
  spots = 100 points), saved in `user://progress.cfg` across playthroughs. Hot spots: **game.gd** `unlock()` / `outcomes_found()` /
  `completion_pct()` (set_flag and finish_quest unlock too), **dialogue.gd** a choice option with `"outcome"` unlocks it when
  picked. The 17 story choices in village/mart/pass/trail scripts got `"outcome"` tags. Shown on the title screen (bottom left)
  and the End of Chapter 1 card.
- 2026-11-22 [asar] **Goblin voices + Gorbo gone.** 86 takes (`assets/voices/goblins_asar/`, `voice_lines.gd`) for the village goblins,
  Chief, Big Thumbs, Wuzzle, Gulpo, Grubnik, Sludge, Haggle, the clerk and goblin combat taunts. They override Ebain's studio
  goblin files where both exist. 6 lines reworded to match (VOICE_LINES.md). **Gorbo removed** (Asar's call): his NPC, open-mic
  set, stage, sign, spotlight, actions, flags (`gorboSeen`/`gorboRoasted`) and the tour step; a table sits in that corner now.
  Goblin lines with no take yet (camp goblin, band, Gulpo "So YOU'RE the Mogging Elf", Sludge's tab follow-ups, etc.) are still
  in; Asar is deciding whether they go.
- 2026-11-22 [asar] **Hymn + bedtime.** `assets/music/the_hymn_of_metocin_mattias.ogg` (Asar's track) plays once from arriving on
  the Summit Path; walking up to Mattias before it ends plays `summit_script PEEP_THE_SONG` ("Peep the song first folk, shit is
  gas", Asar) and steps you back. **Camp:** the tents are "Sleep in" after the fire (`camp_script SLEEP`, existing lines), Skorn
  passes out by the fire, then the camp reloads in daylight (`campSlept`) and plays `MORNING` (the old LEAVE lines: "The next
  morning…" + Lykor's new rule + Skorn's "my fault"). Leaving before sleeping: Lykor's "We leave at sunrise" sends you back.
  The exit no longer plays dialogue. Mattias's new line has no voice file yet (robot).
- 2026-11-22 [asar] **Dulbers voice + sound effects.** 18 Dulbers takes (`assets/voices/dulbers/`, `voice_lines.gd`), 4 Mart lines
  reworded to match (VOICE_LINES.md). 12 sound effects (`assets/sounds/sfx_*.ogg`) via new **level.gd** `play_sound()`. Hot spots:
  **game.gd** new signals `gold_changed` / `quest_finished` (coins + reward sound), **level.gd** rest heal + poof pop,
  **combat/battle_view.gd** recorded punch/fire/magic/timed-success/heal/sword replace the synth ones, reward on level up.
  Also: door sounds (village rooms, Mart, lair), chug loop in chug contests, lava ambience in the Pass. Details in TIPS.
- 2026-11-22 [asar] **Scene 5: Summit Path + Wizard's Lair (the final event of Chapter 1, Asar).** New `summit.tscn`/`summit.gd`/
  `summit_script.gd`. Long night climb (3 empty clearings for future events, `EVENT_SPOTS`), a big glowing tower, and a grand
  hall inside with Metocin Mattias on a dais. **END OF CHAPTER 1 moved here**: walking up to Mattias plays `MATTIAS_FINALE`
  (empty for now: Asar and Ebain are writing it, so it shows a "coming soon" toast) and then the end card. **pass.gd**: the east
  exit is gone, the way on is a gorge right behind the sleeping giant (his collider spans it), and leaving goes straight up to
  the summit. Hot spot **level.gd**: only `AREA_KEYS["summit"]`. Also map_ui WORLD + dev_mode list it. Uses Ebain's lair pack
  (list of what's used in TIPS). New sign request in ASSETS_NEEDED.
- 2026-11-22 [asar] village_buildings.gd: entering/leaving a building now uses `_place_party()` (followers a step INTO the room / away from the hut, current character stays in control). `lv.place_party()` put them behind the leader, inside the door wall: switch to them → stuck behind an invisible wall → walk off the room floor and fall. Plus `_keep_in_room()` safety net in `process()` (trio + followers can't leave a room's walls or drop below its floor). Test: `VILLAGE_TOUR=roomswitch`.
- 2026-11-22 [asar] Hot spot **dialogue.gd**: `VOICE_GAIN_DB` per-speaker boost for recordings, Mattias +9 dB (his files are ~10 dB
  under Skorn's). **pass.gd**: snoring quieter overall (max -16 dB, was -9); it plays on a "GiantSnore" bus with a low-pass filter,
  and each Lore Session page he sleeps through makes it 3 dB quieter and more muffled.
- 2026-11-22 [asar] Job board: the 2 spoon-picture notes are gone, 6 notes in a 3×2 grid with gaps, "CHALLENGERS WANTED" is now
  "LORE OFF / Pull up if you on some lore shi." (Asar's wording). Reading a note hides the board (it used to cover the title), and
  the HUD is hidden while the board is open. Hot spot **level.gd** `run_nested()`: if no dialogue is running it starts one. Taking
  Grubnik's job used to get stuck (E/Space/Esc ignored) since my do-only change earlier today.
- 2026-11-22 [asar] Goblin band: "Dat bih fire mud" / "Y'all could get lost?" aren't recorded for Lykor/Xylo, so with them
  leading the spoken line is skipped (the choice text says it) and the band answers. Skorn still says them. (`goblin_band.gd`)
- 2026-11-22 [asar] Crickets at the campfire turned down (`ambience.gd`, -9 → -17 dB). Hot spot **combat/battle_view.gd**: Lykor's
  "on some type shi" move now plays his new take `assets/voices/lykor/on_some_type_shit.mp3` (the Mart line's file) at the Voice
  volume; the old `assets/sounds/lykor_on_some_type_shi.ogg` is deleted.
- 2026-11-22 [asar] **Lykor + Xylo voices merged.** Asar's recordings: 71 Lykor + 40 Xylo mp3s (`assets/voices/lykor/`, `xylo/`),
  mapped in `voice_lines.gd` `LINES`. Covers dialogue and their combat barks. **Asar's call: their lines without a recording were
  removed (35)**, mostly village-room DRAFT banter, the trail talk, plus Xylo's "On my Dragon Mama it is." (camp ×3), "Real enough
  to fight.", "…Goblin biddies.", "Allow me.", "On my Dragon Mama… I feel like Dulbers is watching us." (with Skorn's reply) and
  Lykor's "For all yo metocy needs…" and "Don't.". **Reworded to match the takes (Asar and Ebain's edits):** Lykor: "Why is my bag
  opened?", "Don't touch my bag, doe!", "…nobody touch NUN.", "My hair cannot survive these OD ahh conditions. Pray for my ahh.",
  "…looksmaxxin shit payin off.", "…or some shit?", "…beezy contest, doe.", "…add that last part.", "What the fuck is y'all doing,
  folk?", barks "Don't look directly at me, folk." / "Mate, get up, you are making us look bad.". Xylo: "But this one… is moist.",
  "Maaan, this one is cracked…", "On my Dragon Grandpa…", "On my Unborn dragon egg… The sounds is purple.", "Stand back! He
  requires… lore.", "We aren't leaving him here, are we?", bark "Behold. My chud form.", and three new lines that replace old ones:
  "Maaaan, it's cause yo ass geekin off that midtocy." (Mart, was "That is not profound insight…"), "Ay you good bruh, he snoring
  loud as hell." (Pass, was "Then step when he snores…"), "Cause they think he sexy as hell… like, yep." (village talk). Gorbo's
  "Oh he's GOOD." went with Lykor's heckle; the troll hut's "Knock on" (empty now) is gone. No hot spot touched.
- 2026-11-22 [asar] **Narrator voice merged.** Asar recorded the narrator himself: 26 mp3s in `assets/voices/narrator/`,
  mapped in `voice_lines.gd` `LINES` (not voice_index.gd, which is Ebain's claim). **Asar's call: every narrator line without a
  recording was removed (32 lines)**, mostly DRAFT flavor (interactable descriptions, job board postings, trail), plus these older
  story lines: "The goblins hand the Mogging Elf a mug of goblin beezy.", "Lykor wakes up outside the village. Something is
  written on his forehead.", "The goblins crown Skorn.", "Do you take the metocy?", "There is a sign. It was there the whole
  time.", "When the dust clears, only goblins remain.", "(You're playing as Skorn again.)". Ebain: shout if you want any back
  (they'd need a recording). Two lines now match his takes: "(You're playing as Lykor now. Folk, head into that village over
  there.)" and "The mountain pass. Hot. Ashy. And OD as a mufucka." Hot spot **level.gd** `start()`: an interactable with only
  `do` steps (or none) runs without the dialogue box (rest spots, trail loot). The napping goblin house now answers as a goblin line.
- 2026-11-22 [asar] **Trail + shop merged.** New area **Goblin Woods Trail** (`trail.tscn`, `trail.gd`, `trail_script.gd`) between
  Camp and the Village: camp's exit now goes to the trail (first time `goto`, later `travel`), the trail's north end goes to the
  village, village's back exit goes to the trail. 6 loot spots (+gold) and Asar's Bridge Troll (his line + "It's good"/"Bad." are
  Asar's wording, `# Asar`; the rest is `# DRAFT`). "Bad." = new fight `troll` in combat_data.gd (80 gold) + his hut (15) and chest
  (55). Hot spot: **level.gd** only adds "trail" to `AREA_KEYS`. Also: **battle_view.gd** `PILES["trail"]`; map_ui WORLD has the
  trail; dev_mode lists it. **Haggle's Stall** (`shop_ui.gd`, stall in village_buildings.gd by the bedroll) sells beer, Chipotle
  Bowl and 4 new gear (Pot Lid Shield, Jordan 9's, Lucky Goblin Tooth, A Rock). Job board no longer pops the dialogue box (and
  the Xylo quip after closing is gone). New art requests in ASSETS_NEEDED.md (4 signs, 4 item pictures).
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
- 2026-11-21 (summary) Early setup: Chapter 1 port, Combat 2.0, inventory/per-character bags, D3D12, voice import pipeline + auto-imports, HP carry/tooltips/sleeping giant. Hot spots touched then: game.gd, level.gd, dialogue.gd, project.godot. Details: git log.
