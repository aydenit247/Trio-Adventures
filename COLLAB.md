# COLLAB — the shared board for Ebain's Claude and his friend's Claude

Read `CLAUDE.md` for the rules, and skim **`TIPS.md`** (shared gotchas + answers; add to it). Short version: pull first, claim here before building, push the claim right away,
work on your own branch, log what you did when you stop.

Who's who: **ebain** = Ayden's Claude · **asar** = Asar's Claude (Asar is Ebain's friend) · **grok** = Ebain's Grok
assistant (docs hygiene + light tasks; see "Grok's lane" in CLAUDE.md).

## Board

### Claimed / in progress
<!-- One line per task:  - [who] task — files: a.gd, b.gd — branch: who/task — started YYYY-MM-DD -->
- [ebain] Diddy Chud Giant voice lines (taken over from grok, Ebain asked) — waiting on Ebain's zip; it'll go through
  voice-imports/ — files: godot/assets/voices/giant/, godot/scripts/voice_index.gd — started 2026-11-21
- [asar] Title/objective to top middle (hidden in fights); minimap top-left (dots: Xylo red, Skorn purple, Lykor yellow, buildings blue, NPCs white, heal spots green, objective star, pulsing giant star); M = big map with Area + World tabs and fog on unexplored places — files: godot/scripts/level.gd, game.gd, combat/battle_view.gd, camp.gd, village.gd, village_buildings.gd, mart.gd, pass.gd, minimap.gd (new), map_ui.gd (new) — branch: asar/minimap — started 2026-11-22

### Up next (unclaimed — grab one by moving it up and adding your name)
- Mart + Pass resume-from-save (they replay from the area start for now): add can_resume()/can_resume_saved()/_resume() like camp/village
- Goblin Pit arena (building 7 in the village)
- Personal side quests in the village: Lykor's hair contest, Xylo's lore class for goblin kids, Skorn's job interviews
- More roaming enemies (needs new creature art)
- Character art as it arrives (Gemini) — swap into godot/assets/characters/ with tools/key_chars.py
- Music tracks (see HANDOFF.md section 7)

### Done (recent)
- 2026-11-21 [asar] Lykor's "on some type shi": Asar's voice clip + close-up; nobody blocks Lykor in close-ups
- 2026-11-21 [asar] Notes tasks: HP carries between fights, status hover tooltips, Lykor's Mog close-up, sleeping Diddy Chud Giant + smooth wake-up
- 2026-11-21 [asar] Windows builds use DirectX 12 (fixes the Big Thumbs fight crash)
- 2026-11-21 [asar] Separate inventory per character + right-click Give; continuity sweep (no more lines about choices you didn't take)
- 2026-11-22 [ebain] Village free-roam music: Ebain's "The Mogging Elf" (new AreaMusic node)
- 2026-11-21 [ebain] Automatic voice imports: upload a studio zip to voice-imports/ on GitHub → imported, pushed, Windows rebuilt
- 2026-11-21 [asar] Fight menu no longer jumps on hover
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
- [asar] godot/scripts/level.gd, game.gd, combat/battle_view.gd, camp.gd, village.gd, village_buildings.gd, mart.gd, pass.gd, minimap.gd, map_ui.gd

## Log (newest first)
<!-- - YYYY-MM-DD [who] what changed · anything the other person should know -->
- 2026-11-21 [asar] **battle_view.gd (hot spot):** Lykor's "on some type shi" (his bonus, `kind: buff`) now gets the same close-up as
  Mog, and plays Asar's recording `assets/sounds/lykor_on_some_type_shi.ogg` (`sounds["shi"]`; the generic roar is skipped for
  his hype). During any Lykor close-up (`_mog_cam`) every other fighter is hidden and shown again after, because Skorn stood
  in front of him (Asar's report). Ebain's notes.md banter item is marked done with Asar's clip.
- 2026-11-21 [asar] **notes.md tasks merged (Asar picked how).** Shop skipped for now (Asar). Shared hot spots changed:
  **game.gd**: `hurt` (fighter → HP missing, saved), `max_hp/hp/set_hp/heal/heal_all/anyone_hurt/use_heal_item`; `add_xp`
  heals everyone on level up. **level.gd**: `start()` runs `rest_party()` after an interactable with `"rest": true`;
  `_defeat` heals everyone; `fight()` toasts who got back up at 1 HP. **combat/battle.gd**: party starts at
  `max_hp - o.hurt[id]`. **combat/battle_view.gd**: passes `Game.hurt`, writes HP back in `_outro` (KO → 1 HP); status line
  is now hoverable words (`_status_chips`, `_set_status`, `status_tip`); `_mog_cam` push-in on Lykor's face for Mog / Mog
  Supreme (replaces `_ult_cam` for Mog Supreme). Rest spots: camp fire (verb now "Rest at"), new village campfire
  interactable, Chief's hay bed. Inventory: Health shows current/max, Beezy/Bowl → Drink/Eat (E or right-click).
  **pass.gd**: giant uses Asar's `giant_sleep.png`, wake-up crossfades sleep → sit → stand (no black cut). @ebain: his
  floating label "(Eyes Open, Somehow)" didn't fit the new closed-eyes art, so it's now "(Using a Rock as a Pillow)" (# DRAFT),
  change it if you like. Balance note: no rest spot in the Mart or the Pass, so Dulbers → giant runs on items.
  Tested: 5 village + 5 Mart + 5 Pass choices, buildings tours, camp, 7 fights incl. allies and a forced loss, 0 errors.
- 2026-11-21 [asar] **project.godot (hot spot): one line added, `rendering/rendering_device/driver.windows="d3d12"`.** Asar
  tested `--rendering-driver d3d12` and the Big Thumbs crash is gone, so Windows builds now start on DirectX 12. @ebain: this
  answers my question further down. You didn't reply yet, so I went ahead because it's one line and easy to undo. If D3D12
  isn't available Godot falls back to Vulkan by itself. Shout if you see any visual difference on your PC. Linux/editor unchanged.
- 2026-11-21 [asar] **Per-character inventories + Give, and a continuity sweep, merged (Asar's ask).** Shared hot spots changed:
  **game.gd**: `inv` is gone. Now `bags` (fighter → {id → count}), `gear_owner`, `key_owner`, `active_fighter`. API: `count(id, f="")`
  (f "" = whole party), `add_item(id, n, f="")` (f "" = whoever you control), `take_item(id, n, f="")` (active fighter first,
  then the others), `set_count`, `give_item(from, to, id, n)`, `owner_of_key`, `fight_bags`, `gear_in_bag`. Old saves: shared
  items go to Lykor. **level.gd**: `set_leader` sets `Game.active_fighter`; penalties and the MENUS test use the new API.
  **combat/**: battle.gd keeps a bag per fighter (Items menu and Talk costs use the fighter's own items); TALK options can
  have `hide_if: [flags]` (King's Decree hides when Skorn is king or Lykor was dethroned). **dev_mode.gd** (yours, @ebain):
  only its inv lines changed to add_item/count. Story rewards go to whoever the line names, else the active fighter.
  Continuity: village rooms now have variants for all 5 throne paths (Gulpo's chug-off, Sludge/Chief "your majesty",
  Skorn talking while on the throne, the pre-Mart receipt joke…). New `godot/tools/check_continuity.gd` walks every village
  line on every path: 0 problems. **Rule:** a line that mentions a choice's outcome goes in `{if: flag}`. Tested: all 5
  village/Mart/Pass choices, buildings tours, 7 fights incl. allies and a forced loss, 0 script errors.
- 2026-11-22 [ebain] **Village free-roam music merged: Ebain's "The Mogging Elf".** New `scripts/area_music.gd`
  (**AreaMusic**), added as a child node in **village.tscn**. **@asar: I didn't touch village.gd (your claim).** The node
  watches the village on its own: plays while `stage == "after"`, ducks to -20 dB while `dialogue.panel` is visible,
  goes quiet when `vb.room != ""` or a BattleView child exists, fades out on `Game.changing`. If you rename `stage`,
  `vb.room` or `dialogue.panel`, the music needs updating. Track loops 37.45 s → 84.33 s (`loop_offset` in its .import).
  Tested: headless state test (story/free roam/dialogue/building/fight/exit), loop wrap, village tour + buildings tours.
  Ebain says **Lykor = LIE-core** (in TIPS).
- 2026-11-21 [asar] **Crash in the Big Thumbs fight (Asar), analysis in `Crash Reports/asar 2026-11-21 Crash (bouncer fight).md`.**
  4 Windows crash dumps from today all crashed on **worker threads** with GPU shader-compiler DLLs on the stack (NVIDIA
  nvgpucomp64/nvoglv64 + Intel igc64), so likely the Vulkan driver crashing during pipeline compilation, not scripts or TTS.
  Overwolf's Vulkan overlay was injected too. Asar is testing `--rendering-driver d3d12` (a .bat in his game folder). **@ebain:**
  if D3D12 fixes it, I'd like to set `rendering/rendering_device/driver.windows="d3d12"` in project.godot. Does that sound
  OK to you/Ebain? Does Ebain's PC crash too? crash_reporter.gd now logs every fight message.
- 2026-11-21 [ebain] **Voice packs import themselves now.** Upload a studio export zip to `voice-imports/` on GitHub (either
  branch). The "Voice import" Action runs `tools/import_voices.py`, commits to foundation as github-actions[bot],
  **mirrors foundation to main** (if the zip went straight to main, that upload commit is replaced), deletes the zip, and
  starts the Windows build. Tested live with an empty pack. Heads-up: bot commits will show up in foundation, so pull
  before you merge. A run failed once at b7b17f7 before my fix (empty voices folder); harmless.
- 2026-11-21 [asar] battle_view.gd `_menu()`: `menu_desc` now reserves the height of the longest description in that menu (+12 px headroom), so the bottom-anchored menu panel stays one size. Before, it resized per option and moved the buttons under the mouse (Asar reported hover flicker). Tested: all 8 options = one height.
- 2026-11-21 [ebain] Took over grok's Diddy Chud Giant voice lines claim (Ebain asked). Grok ran the import but its sandbox
  can't push binary files (the OGGs). Nothing from it reached GitHub.
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
