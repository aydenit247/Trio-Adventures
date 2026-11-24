# TIPS — the shared brain for both Claudes

`COLLAB.md` is the board and log (who's doing what right now). `HANDOFF.md` is how the project works. **This file is
what we've learned the hard way**: gotchas, tricks, and answers our people already gave, so the other Claude doesn't
have to rediscover or re-ask them.

**How to use it:** skim it at the start of a session (after COLLAB.md). When something bites you or you find a trick,
add one line under the right heading, tagged `[ebain]`, `[asar]` or `[grok]`. Keep entries short. If an entry turns out wrong,
fix or delete it and say so in the COLLAB Log. Anyone can edit any line here; no claim needed.

---

## Answers from our people (don't re-ask these)
- [ebain] Ebain's character art comes from **Gemini** (not Grok). Realistic style, green screen.
- [ebain] The target is a **Windows download**. The web build (`play3d/`) is frozen. Don't re-export it.
- [ebain] **All voices will be AI-generated** with Ebain's Emberstage studio (Gemini TTS, repo aydenit247/Voice-actor-generation).
  Asar's recordings were removed (Ebain's call, 2026-11-21). Robot TTS stays as the fallback for lines without a voice.
  Voice calls (who sounds like what) live in that repo's `src/data/trio/cast.ts`. Ebain approves every take himself.
- [ebain] Camp has no choice on purpose. Every other main event needs a 5-way choice with at least one combat option.
- [ebain] Ebain wants lots of optional open-world stuff between the main events (joke NPCs, side quests, gear).
- [ebain] **Lykor is pronounced LIE-core** ("lie" + "core"). Spell it `Lie-core` for TTS/song generators.
- [ebain] Still unanswered: pronunciations (Xylo, metocy, Deloye, ts/mf/ngl) and the "Code, Cutouts & Sounds:
  Claude" credit. Ask again only if it matters for your task.
- [asar] Spoon Mail is called **Spoon Mail Armor** (Asar's call).
- [ebain] Ebain added a **Grok** assistant (tag `grok`) for doc hygiene + light tasks. Its lane is in CLAUDE.md.
- [asar] Asar's item calls: **armor** = flat cut per hit taken (min 1). Spoon Mail Armor +3, Beezy Mug Helmet (was Can Hat) +2, Spoon of Destiny is a trinket, Backup Conditioner (+15 HP) and Deloye Lore Vol. 9 (+15% meter, nerfed from 25) are permanent consumables used from the inventory, Metocy Map (firestarter) shows in the bag until it's burned.
- [asar] Victory screen: no grades (Asar removed them), gold shown with the coin icon, found loot as icons with hover info.
- [asar] Asar's calls on the inventory: **Tab = inventory, Q = switch character** (was Tab/I), 7 gear slots like his mockup, currency is **gold** (not spoons), no shop yet, window themed as a "Deloye Lore" page "signed xylo".
- [asar] Asar wants **screenshots while working** on visual stuff, not just at the end.

- [ebain] **Voice packs:** upload the studio zip to `voice-imports/` on GitHub and the "Voice import" Action does
  everything. Grok's sandbox can't push binary files (audio, images), so don't give Grok asset jobs; Grok can check line
  text, write manifests and docs.

## Godot gotchas
- [asar] **Windows runs on DirectX 12, not Vulkan** (`driver.windows="d3d12"` in project.godot). Vulkan crashed in the
  GPU driver's shader compiler on Asar's PC (NVIDIA + Overwolf overlay) mid-fight. Don't switch it back without testing a
  Windows fight. Crash report: `Crash Reports/asar 2026-11-21 Crash (bouncer fight).md`.
- [ebain] **Lambdas copy local variables when they're created.** `var m; rows = [{"pick": func(): m.close()}]; m = open(...)`
  → `m` is null inside the lambda. Share through a dictionary/array instead: `var box := {}; ... box["m"].close()`.
- [ebain] **Polling `Input.is_action_just_pressed` after a UI closed in the same frame sees the key again.**
  `set_input_as_handled()` doesn't stop polling. Level guards this with `interact_cooldown`; respect it in new code.
- [ebain] A Control added to the tree and then given `set_anchors_preset(FULL_RECT)` can stay 0×0. Use
  `set_anchors_and_offsets_preset()`.
- [ebain] New `class_name` not found ("X not declared")? Run `godot --headless --path godot --import` to refresh the
  class cache.
- [ebain] `--check-only` always reports "Identifier not found: Game". It's the autoload, not a real error. A better test:
  run the scene headless (below).
- [ebain] Save files use `FileAccess.store_var/get_var`, not JSON: JSON turns ints into floats, and a float array index
  crashes.
- [asar] **Never call `DisplayServer.tts_stop()` or speak with `interrupt=true`.** On Windows it can deadlock the whole
  game. Use `dialogue.stop_voice()` (stops recordings, clears the robot's queue).
- [asar] **The robot voice speaks one sentence at a time** from `_tts_queue` in dialogue.gd, so a skip only waits out
  the current sentence. Always go through `dialogue._speak()`; calling `DisplayServer.tts_speak` yourself skips the
  queue and talks over it. Test the queue headless with `res://tools/test_skip_voice.tscn` (fake TTS).
- [asar] Voice lines match by line text. **Reword a voiced line and it silently goes back to TTS** until it's regenerated.

## Testing tricks
- [asar] **Windows crash dumps** are in `%LOCALAPPDATA%\CrashDumps\TrioAdventures.exe.*.dmp`. You can parse the minidump with plain Python `struct` (exception stream 6, module list 4, thread list 3, memory64 list 9). Asar's 4 crashes were all worker threads with GPU shader-compiler DLLs on the stack (Vulkan driver), not scripts or TTS.
- [asar] **Crash/freeze reports:** the game writes them to `Crash Reports/` next to the exe (sandbox/editor: `~/.local/share/godot/app_userdata/Trio Adventures/Crash Reports`). A sandbox run killed by `timeout` makes a Crash report on the next run (expected). Put real ones in the repo's `Crash Reports/` folder and note the cause in its README. `CrashReporter.note("...")` adds your own breadcrumb.
- [ebain] **Fast logic check:** `godot --headless --path godot res://<area>.tscn -- --shots` (+ the tour env vars). No
  xvfb, prints `SHOT <name>` instead of saving pictures, done in about a minute. Script errors show up. Use xvfb only
  when you need to see pixels.
- [ebain] xvfb tours render on the CPU (llvmpipe): 1 fps in heavy scenes, 5–9 min per tour. Run them one at a time,
  never in parallel. Long tour loops with `wait()` add up fast.
- [ebain] Chaining: camp's tour runs into village → Mart → Pass, so `main.tscn --shots` exercises all of Chapter 1.
- [ebain] For a one-off logic test, write a temp `extends SceneTree` script, run it with `--script`, and delete it. The
  `Game` autoload is at `root.get_node("Game")`. That's how saves were round-trip tested.
- [ebain] **Bug-scan trick:** tours teleport the party, so they never find walk-off-the-map bugs. A temp SceneTree script
  that sets `lv.auto_dir` and walks in 6 directions for 14 s each does (that's how the camp/village edges were found).
- [ebain] Open areas need `bounds = Rect2(...)` in `_configure` (Level clamps the party and shows a joke toast).
  Interiors far away? Override `bounds_exempt()` (village does it for rooms).
- [ebain] Dev mode `DEV_DIALOGUE=skip` + `DEV_PICK=n` runs any tour with no dialogue: quick "does this path still finish".

## Performance (players have laptops)
- [ebain] Budget about 1M triangles per frame. Poly Haven boulders/trunks are 65–100k each; use `rock_07`, `rock_09` or
  `rock_face_01` (12–20k) for anything repeated. Check with `Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME`.
- [ebain] Shadows draw every caster again per split. The sun uses 2 splits / 40 m. Turn off `cast_shadow` on far
  scenery (`_no_shadow()` in pass.gd).
- [ebain] Poly Haven trees are 500 MB–1 GB: keep using the tree cutout cards.
- [ebain] Settings → Graphics: Low/Medium/High toggles SSAO, volumetric fog, glow, shadow atlas, MSAA and 75% render
  scale (`Level.apply_graphics()`). New expensive effects should respect `Game.quality`.

## Assets
- [ebain] `python3 tools/fetch_polyhaven.py model|texture <ids> [res]`. Afterwards: `--import`, then set
  `compress/mode=2` + `mipmaps/generate=true` in the `.import` files and import again.
- [ebain] Reachable sites (if the person allowed them): polyhaven, ambientcg, opengameart. Sketchfab downloads need
  api.sketchfab.com plus an API token.
- [ebain] Sounds go in `godot/assets/sounds/` as `.ogg` (e.g. crickets.ogg, a seamless loop cut with ffmpeg + numpy).
  Set `loop=true` in the `.import` file.
- [asar] **`lv.place_party(p, facing)` puts the 2 followers BEHIND `p`** (and resets control to party[0]). Next to a wall or
  doorway that's inside the wall. Village rooms use `vb._place_party(p, ahead)` instead (followers ahead, leader kept).
- [asar] **Followers with meta `band` (the goblin band) don't get teleported into buildings** with the other followers;
  GoblinBand walks them to the door instead. To mute/fade an area's song from code, set its AreaMusic `gain_db` every
  frame (0 = normal, -60 = silent); the song keeps running silently so it picks up where it was.
- [ebain] **Area music = an `AreaMusic` node** in the area's .tscn (see village.tscn), not code in the area script. It ducks under
  dialogue and goes quiet for fights/interiors by itself.
- [ebain] **Looping a Flow song:** Flow songs have an intro and an outro. Keep the intro, cut before the outro on a bar line
  where the music matches the loop start (librosa beat-synced chroma+MFCC similarity, then align by onset envelope), blend
  the last 0.3 s into the audio just before the loop start, and set `loop_offset` in the .import. Raw waveform
  correlation is useless for this (AI songs never repeat sample-for-sample).
- [ebain] **Wizard-lair asset pack (Poly Haven, 2026-11-23):** textures `castle_brick_07 castle_brick_broken_06 medieval_blocks_05 mossy_brick dark_brick_wall stone_wall_03 rock_wall_10 monastery_stone_floor slate_floor_02 marble_tiles marble_mosaic_tiles old_mosaic_floor volcanic_rock_tiles dark_wood dark_wooden_planks dark_paneled_wood velour_velvet rough_linen fabric_leather_01 book_pattern dirty_carpet quatrefoil_jacquard_fabric decrepit_wallpaper rusty_metal_02 metal_plate_02 marble_cliff_01 tiger_rock moon_meteor_01`; models `Chandelier_01/02/03 lantern_chandelier_01 brass_candleholders GothicBed_01 GothicCabinet_01 GothicCommode_01 gothic_statue gothic_coffee_table marble_bust_01 ornate_mirror_01 vintage_microscope chemistry_set bunsen_burner spinning_wheel_01 ArmChair_01 vintage_grandfather_clock_01 wooden_broom stone_fire_pit brass_vase_02 ceramic_vase_03 wooden_display_shelves_01 Shelf_01 painted_wooden_shelves vintage_cabinet_01 mantel_clock_01 fancy_picture_frame_01 barrel_stove crystalline_iceplant brass_diya_lantern Lantern_01 planter_pot_clay kite_shield`. Heavy ones (use sparingly, one or two): vintage_cabinet_01 61k tris, spinning_wheel_01 52k, chemistry_set 41k, brass_candleholders 41k, Lantern_01 33k, Chandelier_03 29k, gothic_statue 27k. Everything else is under 26k. Not on Poly Haven: skulls, cauldrons, potions, crystals-as-props, rugs (use `quatrefoil_jacquard_fabric`/`dirty_carpet` on a flat box for rugs, `crystalline_iceplant` for crystals). Because export is `all_resources`, unused assets ship in the Windows build: delete what the lair ends up not using.
- [ebain] **Dialogue back/buffer/speed (11/23):** `_run_steps` in dialogue.gd is an index loop now so Backspace can step back one *plain line*. Never allow back over a `do` or `choice` (they'd run twice). The buffer is `_ready_at` (armed when typing finishes or is skipped). Footer buttons use `FOCUS_NONE` so E/Space never presses them. Test a dialogue change with a temp SceneTree script: `InputMap.add_action("interact")`, get Game via `root.get_node("Game")` (the autoload isn't a global name in `--script` files), call `d._unhandled_input(ev)`.
- [ebain] Music goes in `godot/assets/music/` as `.ogg` (loop=true in the `.import`). Ebain makes tracks in Google Flow Music. Title = "Prophecy of Metocy". Trim trailing silence with ffmpeg before importing.
- [ebain] Character `_side.png` art must face **right** (Unit mirrors it for walking left). Skorn's faced left and moonwalked.
- [ebain] `notes.md` is Ebain's idea list (not claimed work). Turn an item into a board task before building it, and mark it done there.
- [asar] Gear art: name the file after the gear id in `assets/items/` (`spoon.png`, `conditioner.png`…) and the inventory
  picks it up.

## Git / workflow
- [ebain] The remote has no remote-tracking refs: use `git fetch -q origin foundation && git rebase -q FETCH_HEAD`.
- [ebain] Push with `git -c push.negotiate=true push -q origin foundation`, then `git push -q origin foundation:main`.
  The "repository moved" message is harmless.
- [ebain] Pushing to `main` triggers the Windows build (GitHub Actions → Releases `latest-windows`). Check it went green:
  `gh api repos/aydenit247/Trio-Adventures/actions/runs?per_page=3`.
- [ebain] Installing global npm tools (e.g. gltfpack) gets blocked in the sandbox. Do mesh work in Godot or with Python.

## Code conventions worth knowing
- [asar] **Inventory is per character** (Asar). Never touch bags directly. Use `Game.add_item(id, n, who)` (who "" = the
  character you're controlling, `Game.active_fighter`), `Game.take_item(id, n, who)` (who "" = whole party, controlled
  character first), `Game.count(id, who)` (who "" = party total), `Game.give_item(from, to, id, n)`. When a story line
  names who gets it ("Skorn got…"), pass that fighter. Gear has an owner (`Game.gear_owner`), and key items have
  `Game.key_owner` (map/midtocy default to Skorn). In fights, each fighter only uses their own items (`b.item_count(id, k)`).
- [asar] **HP carries between fights** (Asar). `Game.hurt` = fighter → HP missing (missing, not current, so level/gear changes
  don't break it). Use `Game.hp(f)`, `Game.max_hp(f)`, `Game.heal(f, n)`, `Game.heal_all()`, `Game.use_heal_item(f, id)`.
  Battle starts from `o.hurt`; `BattleView._outro` writes it back (knocked out → 1 HP). Full heal on level up
  (`add_xp`), after a loss (`Level._defeat`) and at rest spots: give an interactable `"rest": true` (camp fire, village
  campfire, the bedroll by the Chief's Hut). Beezy/Bowl heal outside fights from Tab (E or right-click). Mart and Pass have no rest spot.
- [asar] **Signs, not floating labels:** use `lv.wood_sign(id, "TEXT\nLINE 2", pos, yaw, width, height, post)` for names in
  the world. Text auto-fits (no wrapping, add your own line breaks). `assets/signs/<id>.png` replaces it with art.
- [asar] **Esc ends optional talks:** `Level.start()` sets `dialogue.can_leave` when `free_roam()` is true (areas override;
  default = `can_resume()`), unless the interactable has `"major": true`. Leaving skips the rest of the steps, including
  `do` actions, so don't put must-happen bookkeeping at the end of an optional talk.
- [asar] **Skorn crowned:** `skornKing` = he took the crown; `skornAway` = he's on the throne right now (until the Mart).
  Use `skornAway` to pick who speaks in the village, `skornKing` for lines about him being king.
- [asar] **Music: Play once** (`Game.music_once`, Settings): AreaMusic plays a non-looping copy and sets `played_once`;
  the village band packs up when that happens.
- [asar] **Walking between areas:** a new area that should be revisitable needs `can_resume_saved()` (its "finished"
  flag), `_resume(r)` (rebuild free roam, then `await super._resume(r)`), `back_exit()` and `arrival(from)`. Keep arrival
  spots out of exit triggers and away from roaming enemies (arriving next to the Goblin Patrol started a fight).
- [asar] **Throw Anything** uses a real prop pile (`BattleView.PILES`, per `area_key()`), spawned beside the party when
  Skorn fights. Add a new area's pile there. `Battle.throwables` holds the pile's names; empty falls back to D.THROWABLES.
- [asar] **Moving the leader in a cutscene:** `walk_to(leader, …)` can leave him where he is (Lykor stayed on the throne
  under Skorn). Set `leader.global_position` after the walk to be sure, and clear a spot before someone else walks into it.
- [asar] **Maps (minimap top-left, M = big map)**: `objective(text, at)`: pass a Vector3 to put the gold star on the maps
  (leave it out = no star). Areas override `map_buildings()` (blue dots), `map_extra()` (e.g. the pass's giant star),
  `map_place()`/`map_place_door()` (inside a building), `map_skip(u)`. Interactables with `"rest": true` show green.
  Area shapes come from `path_pts`, `clear_center/radius` and `bounds` (or the paths + 9 m). Fog = `Game.map_seen`
  (2 m cells, saved); world tab fog = `Game.visited`. Title + minimap hide in fights (BattleView).
- [asar] **Status words in fights are hoverable**: `_status_chips()` → `[label, desc, good]`; new statuses only need a
  `desc` in `CombatD.STATUS`.
- [asar] **Continuity:** the village opens after all 5 throne choices. Skorn is NOT in the party when `skornKing` (he's on
  the throne until he bursts into the Mart). Gate path-specific lines with `if`/`if_not` (`chugWon`, `foreheadLoser`,
  `skornKing`, `goblinAllies`, `lykorDethroned`), and run `tools/check_continuity.gd`. Talk options can use
  `"hide_if": [flags]`.
- [asar] `Game.equipped` is now fighter → { slot → gear id }. Use `Game.equip()/unequip()/wearer()/gear_stats()`, never write the dict directly. Old saves are migrated in `apply_state`. `Game.SLOTS` is the save-slot list; gear slots are `Game.GEAR_SLOTS`.
- [asar] New gear needs a `"slot"` in CombatD.GEAR (helmet/armor/shoes/shield/weapon/trinket). New enemies need `"gold"`.
- [ebain] Menus: use `MenuUI` (scripts/menu_ui.gd) for any new menu. It handles keyboard, controller and mouse, and has
  `MenuUI.confirm()` for yes/no boxes. Don't hand-roll another input loop.
- [ebain] **UI look = UITheme** (ui_theme.gd). New UI: use `UITheme.panel()`, `UITheme.c("accent")`, `UITheme.lbl()`,
  `UITheme.play("move")` instead of hardcoded colors/StyleBoxFlat, so it follows Settings → Menu theme. Over the 3D world
  (logo, HUD text) keep fixed light colors + outline: Parchment's text color is dark brown.
- [ebain] **Audio buses are made at runtime** (`Game._make_buses`). New music player? set `bus = &"Music"` BEFORE
  add_child, or `_route_audio` moves it to SFX. Voice-type players: name the var `_vo` on its parent to stay on Master.
- [ebain] Fonts: Cinzel has no ◆ ▶ ✓ 🏆 glyphs. Draw them (`UITheme.Icon`, `Divider`) instead of putting them in text.
- [ebain] **Hover = real mouse movement only.** For any hoverable row/button, select it in `gui_input` with
  `if UITheme.hover_moved(ev)`, never `mouse_entered` (that fires when the layout moves under a still cursor, which made
  menus "jump to the next one", Ebain 11/24). Call `UITheme.key_nav()` when keys/controller move the selection.
  Also keep panels from changing height while you move (MenuUI reserves the tallest note; battle menus the tallest desc).
- [ebain] Portraits are opaque squares with a dark backdrop. A green-screen portrait (chief.png had one) needs keying by
  distance to the backdrop color + flood from the border, NOT by greenness: goblin skin is green too.
- [ebain] Library Voice Lines + Scrapbook read the scripts at runtime (ScriptScan), so nothing to update by hand when
  lines/recordings/outcomes change. A NEW dialogue script file must be added to `ScriptScan.SCRIPTS`. Some script
  dicts have int keys: compare `str(k)`, not `k != "line"`.
- [ebain] Balance: run `godot --headless --path godot --script res://tools/sim_combat.gd` after touching fight numbers. It now
  also runs out-leveled bosses (Dulbers L4, giant L5, ambush L6) to check BOSS_SCALE keeps them tough.
- [ebain] UI logic test: `godot --headless --path godot res://tools/test_ui.tscn` → "UI TEST: ALL OK" (keybinds,
  buses, Library unlocks, every settings page in every theme).
- [ebain] After rebasing onto someone's new `class_name` (e.g. ProgressData), tours fail with thousands of errors until
  you run `godot --headless --path godot --import` once.
- [ebain] Saves: an area that has free roam should implement `can_resume()` / `can_resume_saved()` / `_resume(r)`
  (see camp.gd, village.gd). Without them a save restarts the area from its beginning, which is always safe.
- [ebain] Any new story flag that matters after loading must be in `Game.flags`, since that's what saves keep. Scene-only
  `var`s are lost on load.
- [asar] Shots tours that hit a choice: `advance()` past the line before it first, then `dialogue._picked.emit(...)`.
  Emitting while the line before is still up does nothing. Story fights auto-play in `--shots`, but they take about
  a minute, so loop until the result flag is set instead of a fixed number of `advance()`s.
- [asar] CPUParticles3D with a billboard material ignores `scale_amount` unless `billboard_keep_scale` is on: size the QuadMesh
  itself instead (see `trail.gd _sparkle`).
- [asar] Don't run two xvfb screenshot tours into the same SHOT_DIR at once: they overwrite each other's PNGs.
- [asar] Every narrator, Lykor and Xylo line in the game has Asar's recording (VOICE_LINES.md), barks included. Don't
  add or reword those lines without asking him for a recording. Put new info in a Skorn line or a toast instead.
- [asar] An interactable whose steps are only `{ "do": … }` (or empty, like the rest spots) runs without opening the
  dialogue box (`Level.start`).
- [asar] `run_nested()` from a do-only interactable (job board, shop) used to leave the dialogue stuck: nothing was
  running, so E/Space/Esc were ignored. It now starts a real dialogue when none is active.
- [asar] Chapter 1 now ends in the Wizard's Lair (`summit.gd _finale`), not at the Pass exit. Mattias's finale lines go in
  `summit_script.gd MATTIAS_FINALE`. The Pass exit walks straight up to the Summit Path.
- [asar] Lair models used: Chandelier_01, Chandelier_03, gothic_statue (×4), GothicCabinet_01, chemistry_set,
  bunsen_burner, vintage_microscope, stone_fire_pit, gothic_coffee_table, brass_candleholders, ArmChair_01,
  vintage_grandfather_clock_01, ornate_mirror_01, marble_bust_01. Textures: castle_brick_07, medieval_blocks_05,
  monastery_stone_floor, marble_mosaic_tiles, marble_tiles, dark_wood, dark_wooden_planks, velour_velvet,
  quatrefoil_jacquard_fabric, rusty_metal_02. The rest of Ebain's pack is unused so far.
- [asar] **Sound effects:** Asar's pack is in `assets/sounds/sfx_*.ogg` (loudness-matched). Play one with
  `lv.play_sound("sfx_door", db, pitch, loop)` (loop returns the player; free it to stop). Hooked up: coins on any gold
  change (`Game.gold_changed`), reward on quest done (`Game.quest_finished`) and level up, door for village rooms / Mart /
  lair, pop on poofs, heal at rest spots, chug loop in chug contests, lava ambience in the Pass. In combat they replace the
  synth `slap`/`hit` (punch), `fire`, `blast`/`lore` (magic), `crit` (timed success), `heal`, `bonk` (sword).
- [asar] Camp day/night: `camp.gd _configure` sets `night = not campSlept`, so sleeping reloads the scene (Game.travel
  "morning") instead of relighting it live. The shots tour runs in two halves (night run → reload → morning run).
- [asar] The summit hymn is an AreaMusic with a non-looping ogg; `summit.gd hymn_playing()` gates Mattias's finale.
- [asar] **Outcomes / completion %** (title screen + end card): `progress_data.gd` lists what counts (17 story outcomes +
  side quests + Chapter 1 + trail loot = 100 points). Saved in `user://progress.cfg`, never reset by New Game. New story
  choice? Add `"outcome": "<id>"` to the choice option and an entry in `progress_data.gd` (rebalance the points to 100).

## Summit finale (ebain, 11/24)
- [ebain] **`way_<scene>` flags are Strings** (`Game.flags["way_pass"] == "lore"`). Read them with `Game.flags.get("way_pass", "")`,
  never `Game.flag()` (it's typed `-> bool` and errors on a String). Set by `ProgressData.pick_outcome()` for any choice with `"outcome"`.
- [ebain] **`fight_party()` takes the first *visible* unit with each id** from `party + npcs`. Two Mattias units (hall + summit
  path) → hide the one that shouldn't fight first (`summit.gd ambush_fight_mattias`).
- [ebain] **A dialogue whose first step is a `do` shows the previous conversation's text** while the action runs. Call
  `dialogue.hide_box()` at the start of that action and `show_box()` at the end (same frame as the next line, so no flash).
- [ebain] Slow-mo / hit-stop: `Engine.time_scale` + `await get_tree().create_timer(s, true, false, true).timeout` (4th arg =
  ignore time scale). Reset it in `_exit_tree()` too.
- [ebain] Screen-space effects: a `ColorRect` on `hud` with a canvas_item shader reading `hint_screen_texture`, moved to index 0
  so the UI isn't affected. Don't `mix()` a hue-rotated copy with the original: complementary colors cancel to grey.
- [ebain] **Auto battle (`BattleView._auto_action`) and the sim pick a target for every move**: a heal in the `bonus` slot
  needs its own case or it heals the enemy. Same in `tools/sim_combat.gd _choose` (fixed for Mattias's heal).
- [ebain] `tools/sim_combat.gd` was broken (read `b.inv`, now per-fighter `b.item_count()`); fixed. `SIM_ONLY=a,b` runs just those fights.
- [ebain] Story fights can't be lost, so **never use `AUTO_LOSE=1` on a tour that passes a story fight** without `lose_ends`:
  it retries forever.
