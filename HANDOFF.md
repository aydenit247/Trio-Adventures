# Trio Adventures — Handoff (read this first)

For any Claude starting fresh on this repo — including Ebain's friend's Claude. Read `CLAUDE.md` (the collaboration
rules) and `COLLAB.md` (the live board) too. `DESIGN.md` has the full story and combat design notes from the early
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
2. **Goblin Village (day, as Lykor):** ambush → kneel → the Chief → crowned at the spoon throne → choice: A royal
   speech (+3 beezy) · B chug-off minigame · C crown Skorn (he stays behind, `skornKing`) · D sneak out for real,
   goblins follow (`goblinAllies`) · E Skorn fights 3 goblins (real combat). Then the village opens up (section 4).
3. **Metocy Mart (evening, as Xylo):** Dulbers offers the midtocy → A everyone trips / B Skorn trips → boss fight vs
   demon Dulbers · C refuse → kicked out · D Xylo inspects it (Deloye Lore ch. 8,784 sec. B12) · E goblins handle it
   (if allies). Skorn pockets the midtocy in most paths (`hasMidtocy`).
4. **The Pass (lava, as Skorn):** Mattias appears → the giant is asleep in the way → A throw the midtocy (giant trips)
   · B **Snore Sneak** minigame · C **Lore Session** minigame (pick the true Deloye Lore continuation) · D slap him ·
   E it's the Chief's cousin (if allies). Fights are real boss fights. → END OF CHAPTER 1 → back to camp.

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
- `FIGHT=goblins|dulbers|giant|goblin_patrol|bouncer` (+ `LEVEL=2`, `ALLIES=1`, `AUTO_LOSE=1`, `MENUS=1`) — runs one fight
- `LOOK="x,z,yaw;..."` (camp) — close-up screenshots of spots with the fire lit
- `--views` instead of `--shots` walks the trio in 4 directions
Tours are slow in the sandbox (5–9 min); run them one at a time or they time out. `--check-only` always reports
"Identifier not found: Game" — that's a false positive (the autoload). The sandbox has no TTS and no Forward+, so
voices are silent and the screenshots look a bit flatter than the real game.
Balance sim for combat: `godot --headless --path godot --script res://tools/sim_combat.gd`.

### Building the game
- **Windows (the real target):** `godot --headless --path godot --export-release "Windows"
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
(side faces right). Environment = real glTF models + photo textures, plus some cutout cards (trees, tents, bushes)
and painted backdrops (Mart, Pass).

| File | What it is |
|---|---|
| `project.godot` | autoload `Game`, main scene `main.tscn` (camp), Forward+, 1280×720 |
| `scripts/game.gd` | **Game** autoload: story `flags`, `inv`, XP/level, gear, `quests`, settings, `goto(scene)` |
| `scripts/level.gd` | **Level** base class every area extends: environment (night/day/lava), ground shader, `card()`, `backdrop()`, party + NPCs (`spawn_npc`, `add_to_party`, `walk_to`, `hop`, `knock`), camera (`cam_locked`, `zoom`, `cam_height`, `cam_look_h`, `focus_override`), interactions, `run_dialogue()`, HUD (`objective`, `show_toast`, `char_label`), `fight()`, roaming enemies (`spawn_roamers`), the defeat penalty, Esc pause menu + I party/gear/quest menu, test helpers. Hooks: `_configure`, `_build_level`, `_after_build`, `_begin`, `_level_interactables`, `_on_action`, `_level_process`, `_shot_tour` |
| `scripts/unit.gd` | **Unit**: a character (CharacterBody3D + billboard Sprite3D), views, `set_pose`, `restore_views` |
| `scripts/dialogue.gd` | **Dialogue** box + TTS. Steps: `{who, mood, line, thought, name?, portrait?}`, `{do: "action"}` → `_on_action`, `{choice: [{text, if?, steps}]}`, `{if: flag, steps}`, `{if_not: flag, steps}`. `CHARS` = speakers, voices, pronunciation fixes |
| `scripts/voice_lines.gd` | **VoiceLines**: line text → recorded mp3 in `assets/voices/`. `dialogue.gd` plays a recording when a line has one (matched ignoring case/punctuation), otherwise TTS. Still-to-record list: `VOICE_LINES.md` |
| `scripts/camp.gd` + `camp_script.gd` | Scene 1 (`main.tscn`) |
| `scripts/village.gd` + `village_script.gd` | Scene 2 story (`village.tscn`); `_chug_game(rival, speed)` |
| `scripts/village_buildings.gd` + `village_rooms_script.gd` | the explorable village: huts, doors, rooms at x = 400/440/480/520, NPCs, 5 quests |
| `scripts/mart.gd` + `mart_script.gd` | Scene 3 (`mart.tscn`); shop room at x = 300 |
| `scripts/pass.gd` + `pass_script.gd` | Scene 4 (`pass.tscn`); Snore Sneak + Lore Session minigames |
| `scripts/combat/combat_data.gd` | all combat numbers: party moves, fights, gear, statuses, talk options, banter |
| `scripts/combat/battle.gd` | pure combat rules (turn timeline, meters, ultimates, team-ups, statuses, boss AI, talk/flee, grade) |
| `scripts/combat/battle_view.gd` | in-world fight presentation (line-up, menus, timed ring, dice, events, results) |
| `scripts/models.gd` | **Models**: `place(parent, id, pos, rot_y, scale, collide, recolor)`, `mat(texture, tile, tint)` (triplanar PBR for any box/cylinder), `block`, `cylinder`, `patch` (soft-edged ground decal), `tint` |
| `scripts/fx.gd`, `util.gd`, `ambience.gd` | particles (flames, poof), mesh/material/sound helpers, synthesized fire + crickets |
| `assets/characters/`, `portraits/`, `props/`, `backdrops/`, `items/` | Ebain's art (cutouts, painted backdrops) |
| `assets/models/<id>/`, `assets/textures/<id>/` | Poly Haven models (glTF) and textures (albedo/normal/rough.jpg) |
| `../tools/fetch_polyhaven.py` | `python3 tools/fetch_polyhaven.py model|texture <id>` downloads into the project |
| `../tools/key_chars.py`, `key_props.py` | green-screen cutters for Ebain's character / prop images |

### Combat in one paragraph
Fights happen right where you're standing: `await fight("giant", { enemies = [unit], mods = { enraged = true } })`.
FFX-style turn timeline, timed hits/blocks on a shrinking ring (Auto option: T or the Esc menu), meters → ultimates
(FULL CRASH OUT, MOG SUPREME, CHUD OUT), team-ups, statuses both ways, boss phases, rare chaos events, banter, S–F
grade, XP + levels (Level 3 teaches new moves), one trinket per fighter, Talk + Run options, Chief Bogdrinker joins
as a 4th fighter when the goblins are allies. Losing = "YOU GOT COOKED" + a funny penalty (story fights retry,
roaming fights wake you at the area's `checkpoint`). Fights so far: `goblins`, `dulbers`, `giant`, `bouncer`,
`goblin_patrol` (roaming, village east road).

### The explorable village (after the throne scene)
1 Chief's Hut (belt, self-portrait, chest → Backup Conditioner, hay-bed nap) · 2 Unemployment Office & Bar (**Bar
Tab** → bouncer fight, Gorbo's open mic, Gulpo **Chug Rematch**) · 3 Job Board + Grubnik (**Lucky Spoon** from the
Goblin Patrol → Weighted d6) · 4 Shaman's Tent (fortunes, **Lore-Off** → Deloye Lore Vol. 9) · 5 Clank's Spoonsmithy
(**Shiny Spoons**, 5 hidden around → Spoon of Destiny / Spoon Mail) · 6 Outhouse (each of the trio goes in once).
All this dialogue is `# DRAFT` — Ebain may rewrite it. The rooms are built from Poly Haven props.

---

## 5. Open items

Grab-able work is on the board in `COLLAB.md` ("Up next"). Longer-running items:
- **Village extras:** the Goblin Pit (fight arena), personal quests (Lykor's hair contest, Xylo's lore class for
  goblin kids, Skorn's job interviews).
- **Character art from Ebain (Gemini):** new named goblins (bartender, comedian, bouncer, shaman, smith) — right now
  they're recolored goblin cutouts. Cut new art with `tools/key_chars.py` into `godot/assets/characters/`.
  Wishlist: `godot/ASSETS_NEEDED.md`.
- **Voice lines:** 37 goblin + Chief lines recorded by Asar are in (`assets/voices/goblins/`, `voice_lines.gd`).
  The rest are numbered in `VOICE_LINES.md`; Asar records them by number. Mattias lines may come later.
- **Pronunciations:** Ebain hasn't answered the pronunciation list (Lykor, Xylo, metocy, Deloye, slang like ts/mf/ngl).
  TTS respellings live in `dialogue.gd`.
- **Music + real sound effects:** none yet (all sounds are synthesized). Planned tracks: camp, goblin village, Mart
  (+ warped trip version), battle, boss, mountain/pass, victory jingle, "YOU GOT COOKED" sting. There's no music
  system in the Godot version yet.
- **Credits:** asked Ebain whether to keep "Code, Cutouts & Sounds: Claude". No answer yet.
- **Chapter 2+:** Dulbers returns as a villain.

---

## 6. Working with your person

- **Ebain** types fast and loose, likes things done rather than explained, and often answers "do all of them" or
  "lets go." Give short updates with screenshots, and ask him for creative input (lines, joke names, art).
- **If you're the friend's Claude:** you're working for Ebain's friend, not Ebain. Use your person's name as your tag
  on the board, follow `CLAUDE.md`, and leave Log notes so Ebain's Claude knows what changed. Story/character
  decisions still go through Ebain.

---

## Appendix: the old browser version (abandoned)

`index.html`, `src/` and `lib/phaser.min.js` are the original Phaser 3 web game (live at the GitHub Pages root). Its
combat engine (`src/combat/engine.js`) was ported to Godot as `battle.gd`, and its story scripts
(`src/data/scenes/`) to the `*_script.gd` files. Leave it alone unless Ebain asks.
