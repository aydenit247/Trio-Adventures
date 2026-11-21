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
- [ebain] Still unanswered: pronunciations (Lykor, Xylo, metocy, Deloye, ts/mf/ngl) and the "Code, Cutouts & Sounds:
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
  game. Use `dialogue.stop_voice()` (stops recordings only).
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
- [asar] `Game.equipped` is now fighter → { slot → gear id }. Use `Game.equip()/unequip()/wearer()/gear_stats()`, never write the dict directly. Old saves are migrated in `apply_state`. `Game.SLOTS` is the save-slot list; gear slots are `Game.GEAR_SLOTS`.
- [asar] New gear needs a `"slot"` in CombatD.GEAR (helmet/armor/shoes/shield/weapon/trinket). New enemies need `"gold"`.
- [ebain] Menus: use `MenuUI` (scripts/menu_ui.gd) for any new menu. It handles keyboard, controller and mouse, and has
  `MenuUI.confirm()` for yes/no boxes. Don't hand-roll another input loop.
- [ebain] Saves: an area that has free roam should implement `can_resume()` / `can_resume_saved()` / `_resume(r)`
  (see camp.gd, village.gd). Without them a save restarts the area from its beginning, which is always safe.
- [ebain] Any new story flag that matters after loading must be in `Game.flags`, since that's what saves keep. Scene-only
  `var`s are lost on load.
