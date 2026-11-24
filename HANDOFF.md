# Trio Adventures — Handoff (read this first)

For any Claude starting fresh on this repo — including Ebain's friend's Claude. Read `CLAUDE.md` (the collaboration
rules), `COLLAB.md` (the live board) and **`TIPS.md`** (gotchas, tricks and answers our people already gave; both
Claudes add to it) too. `DESIGN.md` has the full story and combat design notes from the early
version; this file is the up-to-date picture.

**TL;DR:** a goofy, Baldur's Gate 3–toned 2.5D RPG made in **Godot 4.7.2** (`godot/`). Chapter 1 is playable start
to finish: Camp → Goblin Village → Metocy Mart → The Pass, with real turn-based combat, an explorable village with
side quests, and real 3D props. The target is a **Windows download**. The old browser (Phaser) version in `src/` is
abandoned — don't work on it.

---

## 1. The game

**Trio Adventures** by **Ebain** (Ayden, the creator). Three friends from Ebain's AI video series go on a quest for
the **metocy**, a mystical herb in a tiny blue oval capsule.

- **Skorn:** a chaotic, angry purple orc. Dumb, proud, loud. Burned the map.
- **Lykor:** "the Mogging Elf." Handsome, blond, vain about his hair and his conditioner.
- **Xylo:** a mysterious red dragon and the lore guy. Reads **Deloye Lore**, a huge book about a universe with little
  to no lore.
- **Dulbers Frint:** shapeshifting demon who runs the Metocy Mart. "hey guys its your boy dulbers frint."
- **Metocin Mattias:** shows up out of nowhere: "You had called?"
- **Chief Bogdrinker:** goblin chief, gives out beezy (beer). The goblins are all unemployed.
- **Diddy Chud Giant:** the boss blocking the Pass. Wakes up with "Aight. Bet."
- **Dulbmeethus:** god behind the smoke. "Y'all could hear me doe?"
- **Items:** Beezy (heals 30), Chipotle Bowl (heals 60), Midtocy (the fake metocy), the d6 ("on some dice shi").

### Chapter 1 flow (each main event has a 5-way choice)
1. **Camp (night, as Skorn):** fire's out → grab the bag → find the map → burn it to start the fire (oops) → roam →
   head north. No choice here — Ebain wants it that way.
   **Bedtime (Asar 11/22):** after the fire, the tents say "Sleep in": Skorn swears he'll guard the fire, Lykor and Xylo
   turn in, Skorn passes out by the fire → "The next morning…" → the camp reloads in daylight (`campSlept`) → the morning
   lines → head north. Walking out before sleeping: Lykor says "We leave at sunrise" and sends you back.
1½. **Goblin Woods Trail (morning, Asar 11/22):** a long walk between Camp and the Village to earn gold before the shop:
   6 searchable loot spots (sparkles) and Asar's **Bridge Troll** by the creek: "Y'all had said i could get some
   bussy?" → "It's good" (Xylo follows him into his hut; bridge opens) or "Bad." (troll fight, lots of gold, then loot
   his hut and chest). Flags `trailStarted`, `trollMet`, `trollDone` ("good"/"bad"), `trollHut`, `trollChest`,
   `trailLoot0..5`, `trailDone`.
2. **Goblin Village (day, as Lykor):** ambush → kneel → the Chief → crowned at the spoon throne → choice: A royal
   speech (+3 beezy) · B chug-off minigame · C crown Skorn (he stays behind, `skornKing`) · D sneak out for real,
   goblins follow (`goblinAllies`) · E Skorn fights 3 goblins (real combat). Then the village opens up (section 4).
3. **Metocy Mart (evening, as Xylo):** Dulbers offers the midtocy → A everyone trips / B Skorn trips → boss fight vs
   demon Dulbers · C refuse → kicked out · D Xylo inspects it (Deloye Lore ch. 8,784 sec. B12) · E goblins handle it
   (if allies). Skorn pockets the midtocy in most paths (`hasMidtocy`).
4. **The Pass (lava, as Skorn):** Mattias appears → the giant is asleep in the way → A throw the midtocy (giant trips)
   · B **Snore Sneak** minigame · C **Lore Session** minigame (pick the true Deloye Lore continuation) · D slap him ·
   E it's the Chief's cousin (if allies). Fights are real boss fights. The only way on is the gorge right behind where he
   sleeps (Asar 11/22), so you can't get past until he's dealt with.
5. **The Summit Path + the Wizard's Lair (night, Asar 11/22; finale built from Ebain's `SUMMIT_FINALE_PLAN.md` 11/24):
   the final event of Chapter 1.** Arriving: a slow camera dolly while Skorn/Xylo/Lykor catch their breath (Xylo's line
   changes with how this run got past the giant/troll), then a toast "Don't walk yet if you want to hear the song." and
   Asar's "The Hymn of Metocin Mattias" starts (plays once). A long climb (3 clearings saved for future events:
   `EVENT_SPOTS` overlook / shrine / cart). **Halfway** (z < 8, by the shrine): Mattias's echo "Impressive, my beloved
   trio…" (moved here from the Pass) + Lykor "Bet. Here we go, folk". **Dulbers' ambush** right after, only if he's alive
   on this run (`dulbersEscaped` and not `dulbersDead` = the Mart refuse / Xylo paths): regular-size Dulbers sprints up
   from behind (the song ducks to the background) → apologize + swear loyalty to Dulbmeethus ("Good boy.") · fight him ·
   offer him fentocy (he dies) · call for Mattias ("Get lost midget fucker!", Mattias fights as a 4th fighter). Then the
   plaza, the tower, the hall. Walking up to Mattias before the hymn ends: "Peep the song first folk" (Asar) and a step
   back. **The castle:** the music drops out, torches flare, "Welcome to da crib folk… I had heard that y'all ___. That's
   OD." (the blank = the biggest thing from this run), the metocy hovers → 5 choices: "Bet. Here we go folk." · "you had
   said u was fuckin wit one too?" (all four take it) · "Bad." ("Oh okay." → hard cut to black, END OF CHAPTER 1, silence)
   · sucker punch → near-impossible Mattias boss (**losing is its own ending**: "Y'all must be geeking off that midtocy…") ·
   ask for it in a Chipotle Bowl. After taking it: give every goblin metocy? Yes → the goblin party (dancing goblins,
   band, "The Mogging Elf", confetti, orbiting camera) → end card. No → end card. Flags `summitStarted` (set after the
   arrival lines), `summitHalfway`, `lairSeen`, `lairEntered`, `foughtWithMattias`, `tookMetocy`, `mattiasBeaten`,
   `chapter1Done`, `endingBad/Cooked/Normal/Party`, and the per-run strings `way_ambush`, `way_castle`, `way_goblins`.

**Story decisions (Ebain):**
- Beating Dulbers in the Mart boss fight counts as **killing him** (same as the goblin chase): `dulbersDead`. He only
  comes back (the summit ambush) on runs where he got away.
- **Fentocy** is a different pill from midtocy. Offering it to Dulbers kills him (he thinks it's midtocy).
- Losing the sucker-punch fight against Mattias is its own Chapter 1 ending, not a retry.

**Big direction (Ebain):** these four are the MAIN EVENTS. Between them he wants lots of optional, open-world-ish
stuff: places to walk into, joke NPCs, side quests, roaming enemies, gear to find. More chapters later; Dulbers is
set up to come back as a villain.

---

## 2. Creative rules (important)

- **Tone:** goofy BG3. Realistic-looking art, dumb jokes, lots of joke labels over people's heads
  (e.g. "Goblin (Between Jobs)", "Diddy Chud Giant (Asleep, In The Way)").
- **Every main event needs a player choice**, and each major encounter keeps at least one combat option.
- **Ebain's dialogue is used verbatim** — only fix grammar/spelling, never rewrite his jokes. Tag his lines `# Ebain`
  and Claude's drafts `# DRAFT`. When writing new scenes, lay them out as numbered lines with his characters' lines
  marked ⭐ so he can edit them.
- **Ebain has the final say** on story and characters. His friend can propose things; check big story changes with Ebain.
- **Art:** characters are Ebain's **Gemini** images (realistic, green screen), cut out into 2D cards. Environment
  props and textures come from **Poly Haven** (free, CC0). Don't download photos of real people.
- **Voices:** robot TTS voices on purpose (Ebain finds them funny). Real voice lines for Mattias + goblins may come
  from the friend later.
- **The 6-7** happens once per game (combat easter egg).


### Ebain's slang and humor (keep this list updated: add new terms as Ebain uses them)
Humor: dumb, deadpan, absurd, committed. Joke labels over people's heads. Lots of internet slang (ts/mf/ngl). Nothing is
too stupid if it's played straight. **Lykor is pronounced LIE-core** (spell it "Lie-core" for songs and voice generators).
- **Mogging / mogged:** out-looking someone. Lykor is "the Mogging Elf." **Mog** is his combat move (camera pushes onto his jawline).
- **On some type shi:** Lykor's buff move, also a chant in the title music.
- **Cooked / "YOU GOT COOKED":** the defeat screen. **Locked In, Mogged, Cooked** are combat status effects.
- **Beezy:** beer. Chief Bogdrinker hands it out. **Metocy:** the mystical herb (blue oval capsule), the whole quest.
  **Midtocy:** the fake one.
- **Big Thumbs:** the bouncer fight at the village bar. **Deloye Lore:** Xylo's huge book about a universe with almost no lore.
- The goblins are all unemployed. "Hella bad for J-O-B" (spelled out as a chant) and "The Mogging Elf" are in the village song.
- Catchphrases: "Aight. Bet." (the giant waking up) · "Y'all could hear me doe?" (Dulbmeethus) · "hey guys its your boy
  dulbers frint" · "You had called?" (Mattias).
- **"Dat bih fire mud"** and **"Y'all could get lost?"**: what you tell the goblin band to keep them playing or send them away (Ebain, notes.md).
- **Fentocy:** a deadly pill (not midtocy). Dulbers takes it thinking it's midtocy and dies.
- **OD:** over the top, crazy ("Damn that was OD to get here", "That's OD"). **Deadahh:** dead-ass, for real.
- **Da crib:** home (Mattias's castle: "Welcome to da crib folk"). **Geeking:** high, tripping ("geeking off that midtocy").
- **"Good boy."**: Dulbers, when the trio swears loyalty to Dulbmeethus. **"Bad."**: the troll answer, also Mattias's
  castle ("Oh okay.").
- **John's orb:** a lore term from the title music. Meaning not given yet. Ask Ebain before using it.

---

## 3. Working in this repo (technical setup)

### Getting started in a fresh workspace
1. Attach the repo (`aydenit247/Trio-Adventures`, push access) and clone it. Work from the **`foundation`** branch;
   **`main`** is what GitHub Pages serves. Follow `CLAUDE.md`: pull → read `COLLAB.md` → claim → work on
   `<yourtag>/<task>` → merge into `foundation` → push `foundation` and `foundation:main`.
   (GitHub may print a "repository moved" notice about letter case. Harmless.)
2. Get Godot 4.7.2 for Linux (GitHub release `godotengine/godot` tag `4.7.2-stable`,
   `Godot_v4.7.2-stable_linux.x86_64.zip`). The workspace can reach GitHub and package registries; Poly Haven/ambientCG
   are reachable only if the person allows them in their Claude settings.
3. For Windows builds, install the export templates: download `Godot_v4.7.2-stable_export_templates.tpz` (1.3 GB, same
   release) and extract `templates/windows_release_x86_64.exe` (+ `windows_debug_x86_64.exe`) into
   `~/.local/share/godot/export_templates/4.7.2.stable/`.
4. After adding new assets, run `godot --headless --path godot --import` once.

### Testing (no screen here, so everything is screenshot tours)
`xvfb-run -a -s "-screen 0 1280x720x24" godot --path godot --rendering-method gl_compatibility --rendering-driver
opengl3 --resolution 1280x720 res://<area>.tscn -- --shots` runs that area's `_shot_tour()` and writes PNGs to
`$SHOT_DIR`. Useful env vars:
- `VILLAGE_CHOICE=0..4`, `MART_CHOICE=0..4`, `PASS_CHOICE=0..4` — which choice path the tour takes
- `VILLAGE_TOUR=buildings TOUR_PART=1|2` — walks every village building and quest
- `VILLAGE_TOUR=roomswitch` — enters the bar, shaman tent and Chief's hut, switches to every character, walks into every wall; prints ALL OK if nobody leaves the room
- `VILLAGE_TOUR=band` — the goblin band: arrives, follows, waits at the bar door, keeps playing, then gets sent away
- `FIGHT=goblins|dulbers|giant|goblin_patrol|bouncer` (+ `LEVEL=2`, `ALLIES=1`, `AUTO_LOSE=1`, `MENUS=1`) — runs one fight
- `LOOK="x,z,yaw;..."` (camp) — close-up screenshots of spots with the fire lit
- `--views` instead of `--shots` walks the trio in 4 directions
- `DEV_DIALOGUE=skip|choices|only:<speaker>` (+ `DEV_PICK=1..5`) — run a tour in a dev dialogue mode (see Dev mode below)
- `DEV_MENU=1` — screenshots of the F1 dev menu + dialogue viewer
- **Fast logic-only check:** add `--headless` (no xvfb, no rendering flags). Tours run in about a minute, print
  `SHOT <name>` instead of saving pictures, and any script error shows up. Use this to check that a flow still
  finishes, and the xvfb run when you need to see it.
Tours are slow in the sandbox (5–9 min); run them one at a time or they time out. `--check-only` always reports
"Identifier not found: Game" — that's a false positive (the autoload). The sandbox has no TTS and no Forward+, so
voices are silent and the screenshots look a bit flatter than the real game.

### Dev mode (F1 in game)
F1 opens the developer menu (`scripts/dev_mode.gd`, class **DevMode**). It lets you:
- pick a **dialogue mode**: normal · choices (only choice menus) · skip (no dialogue at all; choices are auto-picked
  with option #`Skip-all pick`) · `only:skorn|lykor|xylo|goblins|dulbers|mattias_giant|narrator` (only that speaker's lines)
- open the **dialogue viewer**: read every line of a scene's script without playing it, filtered by speaker
  (A/D switch script, W/S scroll, Q back)
- **jump to a scene**, set **fights auto-win**, and use cheats (+100 XP, +items, all gear, story flags)
It works by routing `run_dialogue()` in level.gd through `DevMode.run()`, so dialogue.gd is untouched. Settings live
in `Game.dev_dialogue`, `Game.dev_pick` and `Game.dev_autowin`. Nested dialogue (village rooms) uses `lv.run_nested(steps)`.

Balance sim for combat: `godot --headless --path godot --script res://tools/sim_combat.gd`.

### Building the game
- **Windows (the real target) builds itself.** `.github/workflows/windows-build.yml` runs on every push to `main`
  that touches `godot/` (or by hand: GitHub → Actions → "Windows build" → Run workflow). It exports the game and posts
  **TrioAdventures-Windows.zip** to the Releases page under the `latest-windows` tag:
  https://github.com/aydenit247/Trio-Adventures/releases/tag/latest-windows — that link always has the newest build,
  for Ebain and Asar alike. Takes a few minutes after the push. If it fails, check the Actions tab log.
- **Voice packs import themselves too.** `.github/workflows/voice-import.yml`: a studio export zip uploaded to
  `voice-imports/` (either branch) gets imported with `tools/import_voices.py`, committed to `foundation`, mirrored to
  `main` (an upload commit made straight on `main` is replaced), and then the Windows build is started.
- **Manual Windows build** (only if you need one in the sandbox): `godot --headless --path godot --export-release "Windows"
  ../build/windows/TrioAdventures.exe` → `TrioAdventures.exe` (engine, never changes) + `TrioAdventures.pck` (the
  game). `build/` is gitignored (too big for git) — zip it and hand it to your person as a file. Updates usually only
  need the new `.pck`. Windows SmartScreen will warn ("More info → Run anyway").
- **Web build** (`play3d/`, live at https://aydenit247.github.io/Trio-Adventures/play3d/) is **frozen** at the
  Nov 21 village version. Don't re-export it unless Ebain asks.

### Commits
Commit as user `Claude`, email `noreply@anthropic.com`, ending each message with your own session's attribution lines.

---

## 4. Code map (`godot/`)

**Style: 2.5D.** A 3D world; characters are billboard cutout cards (unshaded, tinted per frame by `light_at()` from
glows registered with `add_glow`). Directional character views: `<id>.png` (front), `<id>_back.png`, `<id>_side.png`
(side faces right). Environment = real glTF models + photo textures, plus some cutout cards (trees, tents, bushes).
Every area is fully 3D now. The painted pictures in `assets/backdrops/` are reference art only. Keep scenes light:
Poly Haven boulders/trunks are 65–100k triangles each, so use `rock_07`/`rock_09`/`rock_face_01` (12–20k) for
anything repeated, and turn off shadows on far scenery (see `_no_shadow` in pass.gd).

| File | What it is |
|---|---|
| `project.godot` | autoload `Game`, main scene **`title.tscn`** (title screen), Forward+, 1280×720, icon + boot splash (`icon.png`, `icon.ico`, `splash.png`) |
| `scripts/title.gd` + `title.tscn` | title screen: the camp runs in "title mode" behind the logo (fire lit, slow camera orbit). Continue / New Game / Load / **Library** / Achievements / Settings / Quit. Gold Cinzel logo + ornament (always gold, whatever the theme). Music: Ebain's **"Prophecy of Metocy"** (`assets/music/prophecy_of_metocy.ogg`, Gregorian chant, loops, fades out when you start) |
| `scripts/goblin_band.gd` | **GoblinBand**: the village goblin band (follows you playing the village song, sets the song's `gain_db`, talk options, waits at building doors). See section 4 "The explorable village" |
| `scripts/area_music.gd` | **AreaMusic**: an area's free-roam music. Add it as a child node in the area's `.tscn` and set `track` (+ `stages`, volumes). It watches the parent Level, so the area script doesn't change: plays while `stage` is in `stages`, ducks under dialogue, goes quiet in building interiors (`vb.room`) and fights (a BattleView child), fades out on `Game.changing`. Keeps playing silently while out, so the song continues instead of restarting. `gain_db` lets the area turn it down (the village mutes it when the goblin band is gone). Village: Ebain's **"The Mogging Elf"** (`assets/music/the_mogging_elf.ogg`) in free roam |
| `scripts/achievements.gd` | **Achievements**: popup top-right + title-screen list, saved forever in `user://achievements.cfg`. Add one = one line in `LIST` with `when`: `progress:<id>` (any progress_data id), `flag:<name>` (any story flag), or `manual` (call `Game.achieve("id")`). `hidden` = shows ??? until unlocked. Lives on Game (`Game.ach`) so it survives scene changes. The 5 current ones are DRAFT examples; Ebain picks the real list |
| `scripts/menu_ui.gd` | **MenuUI**: every menu (title, pause, settings, save/load, yes/no). Keyboard, controller and mouse. `MenuUI.open(parent, title, rows, opts)`, `MenuUI.confirm()`, `open_settings()` (section list → `_settings_audio/display/dialogue/gameplay/controls` pages), `open_slots()`. Rows: `text`, `value` (shown right, with ‹ › if the row has `change`; `"arrows": false` hides them), `icon` (play/pause/lock/note), `side` (a small button, L / Y). Looks from UITheme, restyles on `Game.ui_changed` |
| `scripts/ui_theme.gd` | **UITheme**: the menu look. 3 themes (`NAMES`, colors in `T`): Gold & Night, Parchment, Wizard Arcane. `c(key)`, `panel()` (OrnateBox: chamfered, double frame, corner diamonds, top gem), `row(on)`, `lbl()`, `fs(px)` (× text size), `head_font()`/`row_font()` (Cinzel), `button()`, `bounce()/squash()/pop_in()`, `play("move/pick/back/open/page")` (synth sounds), drawn `Icon` + `Divider` |
| `scripts/library_ui.gd` + `lyrics.gd` | **LibraryUI** (Title → Library): `SONGS`, play/pause/seek, lyrics page (always parchment). Songs unlock when heard (`mark_heard()`, called by AreaMusic once audible; title song always unlocked), saved in `user://library.cfg` across playthroughs. **Lyrics** go in `lyrics.gd` `TEXT[id]` (Ebain's, verbatim). New song = add to SONGS + Lyrics.TEXT |
| `scripts/keybinds.gd` | **Keybinds** (Settings → Controls): rebind each action's main keyboard key (swaps on clash, Space/Enter always work for interact). Saved in settings.cfg `[keys]`, applied by Game before any level's `_setup_input()`. `ACTIONS` defaults must match level.gd |
| `scripts/game.gd` | **Game** autoload: story `flags`, per-character `bags`, XP/level, gear, HP between fights (`hurt`, `hp()`, `heal()`), `quests`; `goto(scene)` (shows a loading card with a joke tip); **settings** (saved in `user://settings.cfg`; F11/Alt+Enter fullscreen); **saves** (`user://saves/<auto/1/2/3>.sav`: `save_game`, `load_game`, `latest_slot`, `new_game`) |
| `scripts/level.gd` | **Level** base class every area extends: environment (night/day/lava), ground shader, `card()`, `backdrop()`, party + NPCs (`spawn_npc`, `add_to_party`, `walk_to`, `hop`, `knock`), camera (`cam_locked`, `zoom`, `cam_height`, `cam_look_h`, `focus_override`), interactions, `run_dialogue()`, HUD (`objective`, `show_toast`, `char_label`), `fight()`, roaming enemies (`spawn_roamers`), the defeat penalty, Esc pause menu, Tab inventory (`open_party_menu()` → InventoryUI), `item_icon(id)`, test helpers. Hooks: `_configure`, `_build_level`, `_after_build`, `_begin`, `_level_interactables`, `_on_action`, `_level_process`, `_shot_tour` |
| `scripts/unit.gd` | **Unit**: a character (CharacterBody3D + billboard Sprite3D), views, `set_pose`, `restore_views` |
| `scripts/dialogue.gd` | **Dialogue** box + TTS. Steps: `{who, mood, line, thought, name?, portrait?}`, `{do: "action"}` → `_on_action`, `{choice: [{text, if?, steps}]}`, `{if: flag, steps}`, `{if_not: flag, steps}`. `CHARS` = speakers, voices, pronunciation fixes. Voices: recordings play instantly; the robot TTS is never interrupted (Windows deadlock), so it reads one sentence at a time from `_tts_queue` and the newest line waits for the current sentence (skipping never mutes the next line). Test: `res://tools/test_skip_voice.tscn` |
| `scripts/crash_reporter.gd` | **CrashReporter** (started by Game): freeze watchdog thread (12 s without a frame), crash/force-close detection on next launch (session marker), `OS.add_logger` catches every error. Writes Markdown reports to `Crash Reports/` next to the exe (user:// in the editor). `CrashReporter.note("...")` adds a breadcrumb. Repo folder `Crash Reports/` collects them |
| `scripts/inventory_ui.gd` | **InventoryUI** (Tab): Deloye Lore parchment window over the blurred game. Fighter + 7 gear slots, **that fighter's own bag** (right-click → View / Give to another character) (`_bag_items()`: Beezy/Bowl, unequipped gear, key items), gold, quests page (J). Q = next fighter. Own grid input (MenuUI is list-only) but it joins `MenuUI.stack` |
| `scripts/minimap.gd` | top-left minimap (simple shapes, colored dots, fog, turns with the camera; shared draw helpers) |
| `scripts/map_ui.gd` | M: big map, Area tab (whole area + fog) and World tab (Camp → Village → Mart → Pass, fog on unvisited) |
| `scripts/job_board_ui.gd` | the village Job Board screen (pinned notes, read up close, Take job) |
| `scripts/voice_index.gd` | **VoiceIndex**: generated by `tools/import_voices.py` (studio export → OGG). Line key → file |
| `scripts/voice_lines.gd` | **VoiceLines**: line text → recorded mp3 in `assets/voices/`. `dialogue.gd` plays a recording when a line has one (matched ignoring case/punctuation), otherwise TTS. Still-to-record list: `VOICE_LINES.md`. Its own `LINES` holds Asar's narrator, Lykor and Xylo recordings (`assets/voices/narrator/`, `lykor/`, `xylo/`; only recorded lines exist for those three, see VOICE_LINES.md) |
| `scripts/camp.gd` + `camp_script.gd` | Scene 1 (`main.tscn`) |
| `scripts/trail.gd` + `trail_script.gd` | Scene 1.5 (`trail.tscn`): forest trail z +58 (camp end) → −58 (village end), creek + bridge at z 0, troll hut, loot spots (`LOOT`), `_apply_state()` rebuilds troll/hut/loot from flags |
| `scripts/shop_ui.gd` | **ShopUI**: Haggle's Stall (village, by the bedroll). `STOCK` = [id, "item"/"gear", price]; buys go to the active fighter |
| `scripts/village.gd` + `village_script.gd` | Scene 2 story (`village.tscn`); `_chug_game(rival, speed)` |
| `scripts/village_buildings.gd` + `village_rooms_script.gd` | the explorable village: huts, doors, rooms at x = 400/440/480/520, NPCs, 5 quests |
| `scripts/mart.gd` + `mart_script.gd` | Scene 3 (`mart.tscn`): modelled shop exterior (`_shop_exterior`, street houses) + stocked interior at x = 300 (`_shop_interior`); the trip recolors `room_lights`/`glow_jars` |
| `scripts/progress_data.gd` | **ProgressData**: what counts toward "Outcomes x/26 · N% complete" (title screen, end card). `Game.unlock(id)` / `outcomes_found()` / `completion_pct()`; saved in `user://progress.cfg` across playthroughs. `ProgressData.pick_outcome(id)` (called by dialogue.gd + dev mode when a choice with `"outcome"` is picked) also sets the **per-run** string flag `way_<scene>` (`village_skorn_king` → `way_village = "skorn_king"`), since outcomes themselves are saved across playthroughs |
| `scripts/summit.gd` + `summit_script.gd` | Scene 5 (`summit.tscn`): the climb (z +62 → plaza at -52), tower (`_lair_exterior`), the hall built off to the side at `INT` (x 400, `_hall`: round wall open toward the camera, pillars, dais + throne, statues, chandeliers, alchemy + study corners, floating candles/books/orb via `floaters`). Uses Ebain's wizard-lair Poly Haven pack. **Finale:** `_begin` (arrival) → `_halfway` → `_ambush` → `_finale` → `_hard_end` / `_goblin_party` (set at `PARTY_POS`, x -400) / `end_card`. Script steps with a `"dyn"` key get their line from `_dyn_line()` (tables `DYN_*` in summit_script: first matching flag wins). Trip look = `_take_metocy` + `TRIP_SHADER`. Test: `SUMMIT_TOUR=finale SUMMIT_FLAGS=… SUMMIT_PICKS=… [AUTOWIN=1]` (see the comment above `_finale_tour`) |
| `scripts/pass.gd` + `pass_script.gd` | Scene 4 (`pass.tscn`): rock-face canyon + animated lava (`_canyon`, `_lava`), giant lying across the path (`giant_lying`, Asar's `giant_sleep.png`; `_giant_wakes` crossfades sleep → sit → standing, no black cut); Snore Sneak + Lore Session minigames |
| `scripts/dev_mode.gd` | **DevMode**: the F1 developer menu, dialogue modes, line viewer (see "Dev mode") |
| `scripts/combat/combat_data.gd` | all combat numbers: party moves, fights, gear, statuses, talk options, banter |
| `scripts/combat/battle.gd` | pure combat rules (turn timeline, meters, ultimates, team-ups, statuses, boss AI, talk/flee) |
| `scripts/combat/battle_view.gd` | in-world fight presentation (line-up, menus, timed ring, dice, events, results, hoverable status words, Lykor's Mog close-up `_mog_cam`) |
| `scripts/models.gd` | **Models**: `place(parent, id, pos, rot_y, scale, collide, recolor)`, `mat(texture, tile, tint)` (triplanar PBR for any box/cylinder), `block`, `cylinder`, `patch` (soft-edged ground decal), `tint` |
| `scripts/fx.gd`, `util.gd`, `ambience.gd` | particles (flames, poof), mesh/material/sound helpers, synthesized fire + crickets |
| `assets/characters/`, `portraits/`, `props/`, `backdrops/`, `items/` | Ebain's art (cutouts; backdrops are reference only now) |
| `assets/models/<id>/`, `assets/textures/<id>/` | Poly Haven models (glTF) and textures (albedo/normal/rough.jpg) |
| `../tools/fetch_polyhaven.py` | `python3 tools/fetch_polyhaven.py model|texture <id>` downloads into the project |
| `../tools/key_chars.py`, `key_props.py` | green-screen cutters for Ebain's character / prop images |

### Saves, settings, controls
- **Saves:** the game autosaves when you enter an area and when free roam starts (camp after the fire, village after
  the throne). Esc → Save Game has 3 manual slots. An area in free roam resumes exactly where you stood (it implements
  `can_resume()` / `can_resume_saved()` / `_resume(r)`; see camp.gd and village.gd). Anywhere else, a save keeps the
  state from when you **entered** the area, so loading replays that area from its start instead of landing mid-cutscene.
  Only `Game` state is saved, so story facts that matter later must be `Game.flags`.
- **Settings** (title + Esc menu), split into pages: **Audio** (master, music, sound effects, voice volume, voices,
  area music loop/once) · **Display & UI** (menu theme, UI size = root `content_scale_factor` 80–130%, text size 85–130%,
  menu animations Bouncy/Calm, window, VSync, graphics) · **Dialogue** (text speed, buffer, go back, speed mode) ·
  **Gameplay** (camera speed, difficulty, timed hits) · **Controls** (keyboard rebinding, reset).
- **Audio buses** (made in `Game._make_buses()`, no bus layout file): `Music` and `SFX` → Master. Any new player left on
  Master is moved to SFX automatically (`Game._route_audio`), except dialogue's `_vo`. Music players must set
  `bus = &"Music"` before `add_child` (title.gd, area_music.gd, library_ui.gd do).
- **Controller:** left stick/d-pad move, right stick or LB/RB camera, A talk/confirm, B run (hold) / back in menus,
  Y switch leader, Back = party, Start = menu. Number keys 1–9 pick dialogue choices.
- **Dialogue controls** (`dialogue.gd`, Settings → Dialogue buffer / Go back / Speed mode): **E / Space / click** finishes the typing, and the next press has to wait out the **buffer** (Off/Short 0.2/Normal 0.4/Long 0.8 s) so lines can't be mashed through. **Backspace** replays the previous line (and its voice) but only if the step before it is also a plain line: it can't go back over an action (`do`) or a choice. **Speed mode** (button at the bottom-left of the dialogue box, asks Yes/No; off with one click or in Settings) removes the buffer and types 2x faster. Settings are saved in `Game.dlg_buffer/dlg_back/dlg_speed`. Keyboard/mouse only: no controller button for back.

### Combat in one paragraph
Fights happen right where you're standing: `await fight("giant", { enemies = [unit], mods = { enraged = true } })`.
FFX-style turn timeline, timed hits/blocks on a shrinking ring (Auto option: T or the Esc menu), meters → ultimates
(FULL CRASH OUT, MOG SUPREME, CHUD OUT), team-ups, statuses both ways, boss phases, rare chaos events, banter, XP +
levels (Level 3 teaches new moves), 7 gear slots per fighter (helmet/armor/shoes/shield/weapon/2 trinkets, summed by `Game.gear_stats()`), armor (flat cut per hit), permanent BOOSTS items (`Game.use_boost`), gold drops (`gold` per enemy; Talk = half), Talk + Run options, Chief Bogdrinker joins
as a 4th fighter when the goblins are allies. Losing = "YOU GOT COOKED" + a funny penalty (story fights retry,
roaming fights wake you at the area's `checkpoint`). Fights so far: `goblins`, `dulbers`, `giant`, `bouncer`,
`goblin_patrol` (roaming, village east road), `troll`, `dulbers_ambush` (summit, regular-size Dulbers; Mattias can join
as a 4th fighter, `CombatD.PARTY["mattias"]`), `mattias` (the sucker-punch boss; every number in `CombatD.MATTIAS_BOSS`,
balance with `SIM_ONLY=mattias godot --headless --path godot --script res://tools/sim_combat.gd`). `fight(key, { lose_ends
= true })` makes a loss return "lose" instead of the penalty + retry.

### Polish (Asar 11/22)
Village names are wooden signs (`Level.wood_sign`, art goes in `assets/signs/`, list in ASSETS_NEEDED.md). Esc ends optional
conversations in free roam (`dialogue.can_leave`, `Level.free_roam()`). The chapter title shows once at New Game
(`camp._chapter_card`) instead of on the title screen. Settings → Music: Loop / Play once (`Game.music_once`). The Pass has
a rest campfire near the entrance.

### Walking between areas (Asar 11/22)
Once an area is finished you can walk back: Pass → Mart → Village → Trail → Camp (each area's start edge has a "Back to …"
sign), and walking forward into a finished area drops you into free roam instead of replaying it. `Game.travel(scene,
from, leader)` sets `pending_resume` with `travel: true`; the area resumes through its normal `can_resume_saved()` /
`_resume()` and `Level._resume` places you with `arrival(from)`. Areas define `back_exit()` (only in free roam) and
`arrival(from)`. "Finished" flags: `campDone`, `villageOpen`, `martDone`, `giantDone`. The empty Mart can be entered
again (Dulbers is gone in every ending). Mart and Pass now resume from saves too.

### The explorable village (after the throne scene)
Chief's Hut (closed: outside only, Asar 11/22) with a bedroll beside it (rest spot) and a Backup Conditioner pickup ·
Unemployment Office & Bar (**Bar Tab** → bouncer fight, Gulpo **Chug Rematch**; Gorbo and his open mic were removed, Asar 11/22) · Job Board
(`scripts/job_board_ui.gd`: pinned notes you click; "Take job" starts **Lucky Spoon** / **Lore-Off** / **Chug Rematch**)
+ Grubnik (**Lucky Spoon** from the Goblin Patrol → Weighted d6) · Shaman's Tent (fortunes, **Lore-Off** → Deloye Lore
Vol. 9) · Outhouse (each of the trio goes in once) · **Haggle's Stall** (shop, `ShopUI`: beer, Chipotle Bowl, Pot Lid
Shield, Jordan 9's, Lucky Goblin Tooth, A Rock). Clank's Spoonsmithy was removed (Asar 11/22); the Goblin Patrol
now drops Spoon Mail (fight `loot` can be a list).
All this dialogue is `# DRAFT` — Ebain may rewrite it. The rooms are built from Poly Haven props.

**Goblin band** (`scripts/goblin_band.gd`, art `band_drummer/horn/lute.png`): a drummer, horn player and lute player
run in from the bar when free roam starts and follow the trio playing "The Mogging Elf" (the song only plays while
they're around). Talk to one: "Dat bih fire mud" (# Ebain) keeps them playing; "Y'all could get lost?" (# Ebain) sends
them into the bar and the song fades out. They're back on the next visit or a loaded save (not saved). While you're
in a building they wait by its door. Their replies and joke labels are # DRAFT.

---

## 5. Open items

Grab-able work is on the board in `COLLAB.md` ("Up next"). Longer-running items:
- **Village extras:** the Goblin Pit (fight arena), personal quests (Lykor's hair contest, Xylo's lore class for
  goblin kids, Skorn's job interviews).
- **Character art from Ebain (Gemini):** new named goblins (bartender, bouncer, shaman, smith) — right now
  they're recolored goblin cutouts. Cut new art with `tools/key_chars.py` into `godot/assets/characters/`.
  Wishlist: `godot/ASSETS_NEEDED.md`. Top of the list: a **sleeping giant** (lying down) for the Pass. Right now
  it's his standing art turned on its side.
- **Voice lines:** all voices will be AI-generated with Ebain's Emberstage studio (see VOICE_LINES.md). Asar's recordings
  were removed 2026-11-21. Lines without a generated voice use the robot TTS.
  The rest are numbered in `VOICE_LINES.md`; Asar records them by number. Mattias lines may come later.
- **Pronunciations:** Lykor = **LIE-core** (Ebain, 2026-11-22). Still unanswered: Xylo, metocy, Deloye, slang like ts/mf/ngl.
  TTS respellings live in `dialogue.gd`.
- **Music:** title = "Prophecy of Metocy" (title.gd), village free roam = "The Mogging Elf" (AreaMusic node in
  village.tscn). Ebain makes tracks in Google Flow Music. Loop points go in the track's `.import` (`loop=true`,
  `loop_offset` = where the loop restarts, so an intro plays once). Still wanted: camp, Mart (+ warped trip version),
  battle, boss, mountain/pass, victory jingle, "YOU GOT COOKED" sting. A new area track = add an AreaMusic node to
  that area's .tscn, and add it to `LibraryUI.SONGS` + `Lyrics.TEXT` so it shows in the Library.
- **Lyrics:** Ebain will send lyrics for all 3 songs. Paste them into `scripts/lyrics.gd` as-is.
- **Credits:** asked Ebain whether to keep "Code, Cutouts & Sounds: Claude". No answer yet.
- **Chapter 2+:** Dulbers returns as a villain.

---

## 6. Working with your person

- **Ebain** types fast and loose, likes things done rather than explained, and often answers "do all of them" or
  "lets go." Give short updates with screenshots, and ask him for creative input (lines, joke names, art).
- **If you're the friend's Claude:** you're working for Ebain's friend, not Ebain. Use your person's name as your tag
  on the board, follow `CLAUDE.md`, and leave Log notes so Ebain's Claude knows what changed. Story/character
  decisions still go through Ebain.
- **If you're Grok (tag `grok`):** Ebain added you for documentation hygiene and light tasks. See "Grok's lane" in
  `CLAUDE.md`. Same workflow as everyone: pull, read the board, claim, branch `grok/<task>`, log. The Claudes write the
  code. Your job is keeping these docs true, tidy and short.

---

## Appendix: the old browser version (abandoned)

`index.html`, `src/` and `lib/phaser.min.js` are the original Phaser 3 web game (live at the GitHub Pages root). Its
combat engine (`src/combat/engine.js`) was ported to Godot as `battle.gd`, and its story scripts
(`src/data/scenes/`) to the `*_script.gd` files. Leave it alone unless Ebain asks.
