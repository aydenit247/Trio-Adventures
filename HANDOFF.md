# Trio Adventures — Handoff for a New Chat

Paste this whole file into a new chat (or point the new chat to `HANDOFF.md` in the repo). It is everything a fresh Claude needs to pick up exactly where we left off. **`DESIGN.md` in the repo is the source of truth** for story, scenes, choices, lore canon, combat numbers and systems. This file is the "how we work + where things stand" companion.

---

## 1. What this is

**Trio Adventures** by **Ebain** (the user, Ayden) is a comedic, goofy, Baldur's Gate 3–toned browser RPG. It runs on desktop browsers only.

- **Characters:** Skorn, Lykor and Xylo, from Ebain's AI video series.
- **The quest:** they're looking for the **metocy**, a mystical herb in a tiny blue oval capsule.
- **Repo:** https://github.com/aydenit247/Trio-Adventures
- **Live game:** https://aydenit247.github.io/Trio-Adventures/. GitHub Pages serves it from the `main` branch.
- **Status:** Chapter 1 (about 15 minutes) is fully playable from start to finish. It has real combat, voices, sound, saves, an outcome tracker, settings, a tutorial and credits.

### The trio
- **Skorn:** a chaotic, angry purple orc and the map burner. He's dumb, proud and loud.
- **Lykor:** "the Mogging Elf." He's handsome, blond and vain about his hair and conditioner.
- **Xylo:** a mysterious red dragon and the lore guy. He reads **Deloye Lore**, a huge book about a universe with little to no lore.

### Other characters
- **Dulbers Frint:** a shapeshifting demon who runs Metocy Mart. "hey guys its your boy dulbers frint."
- **Metocin Mattias:** shows up with "You had called?"
- **Diddy Chud Giant:** the boss at the pass.
- **Chief Bogdrinker:** the goblin chief. He gives out beezy, which is beer.
- **The goblins:** unemployed.
- **Dulbmeethus:** the god behind the smoke. You reach him by smoking a Dulber's Frint Pack. His line is "Y'all could hear me doe?"

### Items
- **Midtocy:** the fake metocy.
- **Beezy:** beer. Heals 30.
- **Chipotle Bowl:** heals 60.
- **The d6:** labeled "on some dice shi."

---

## 2. How to resume in a new chat (technical)

1. Attach the repo: `add_repo` owner `aydenit247`, repo `Trio-Adventures`, access `push`. Clone it, then register the repo root.
2. Work on the **`foundation`** branch. To go live, push foundation, then push foundation to main:
   ```
   git checkout foundation
   git -c push.negotiate=true push -q origin foundation
   git push -q origin foundation:main
   ```
   (GitHub may print a "repository moved" notice about letter case. It's harmless.)
3. **Commit as** user `Claude` with email `noreply@anthropic.com`, and end each message with:
   ```
   Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
   Claude-Session: <current session url>
   ```
4. **Local testing:** run `python3 -m http.server 8765` from the repo root. Restart it with nohup if it dies. Test with Playwright Python using `executable_path='/usr/bin/google-chrome'` and `--autoplay-policy=no-user-gesture-required`.
   - Headless Chrome is very slow, roughly 8x slower game time. Wait generously, or force state with `page.evaluate`, e.g. set `TitleScene.menuReady = true`.
   - `window.game` is the Phaser game. Start a scene directly: `game.scene.getScenes(true).forEach(s=>s.scene.stop()); game.scene.start('Pass')`.
   - Start a fight directly: `game.scene.start('Combat',{fight:'giant',mods:{enraged:true},bg:'bg_giant_pass',onDone:r=>window.done=r})`.
   - Force dice 6s: `Phaser.Math.Between=(a,b)=>b`. Don't override `Math.random`, because that breaks Phaser text.
   - A paused scene isn't in `getScenes(true)`. Check `isActive() || isPaused()` instead.
5. **The workspace has no general internet.** Only package registries and GitHub are reachable. Art, video and audio must be uploaded by Ebain.

---

## 3. Tech stack and code map

- **Phaser 3.90**, vendored at `lib/phaser.min.js`. No build step; it uses plain ES modules. The canvas is 1280×720 with `Scale.FIT`.
- `index.html` loads the fonts (Cinzel, Nunito) and Phaser. It also has three small icon buttons in the top-left:
  - 🔊 mute (M)
  - 🗣 voices (V)
  - ⚙ settings (O). Opens the Settings overlay from anywhere.
- `src/main.js` lists the scenes: `Boot, Intro, Title, Goblin, Mart, Pass, Continue, Combat, Settings, Outcomes, Credits`.

### Scenes (`src/scenes/`)
- **BootScene:** the loading screen. It loads all portraits, backgrounds, `char_*` full-body cutouts (including combat poses and hurt poses), `item_*` and `vid_*` videos. It registers the ChromaKey pipeline and preloads the menu music.
- **IntroScene:** Scene 1, "The Map," at camp at night. Skorn burns the map in a cutscene, then the "Trio Adventures by Ebain" title card appears. **Ebain wants Scene 1 kept as-is, with no choice.**
- **TitleScene:** the menu row: Continue (with "Saved at: …" underneath), New Game (confirms if a save exists), Chapters (submenu: Goblin Village, Metocy Mart, The Pass, Back), Outcomes x/22, Settings, Replay Intro. The Gregorian chant menu music plays here.
- **StageScene:** the shared base for story scenes. It provides:
  - stage setup and background placement: `BG={scale:1.375,left:-64,top:-100}`, with `at(x,y)` mapping art coordinates to screen
  - characters: `makeChar`, `setCharTex`, show/hide, `setSpeaker`, hop, walk
  - lighting moods (moon, day, shop, candle, lava, fire, trip), `tripOn` and `tripOff`
  - labels: `label`, `charLabel`
  - `playCutscene(key,{keyed,...})`
  - minigames: `mashGame`
  - **`fight(key, mods)`**: pauses the scene, launches CombatScene, and resolves when you win
  - **`finish(next)`**: records outcomes, autosaves, and fades out
  - an "Outcome found" toast
  - ESC skips the scene
- **GoblinScene, MartScene, PassScene:** Scenes 2, 3 and 4. Their scripts are in `src/data/scenes/`.
- **ContinueScene:** the "End of Chapter 1" card. Space goes to the credits.
- **CombatScene:** turn-based combat (see section 6).
- **OverlayScene:** the base for overlays. It pauses everything underneath and resumes it on close.
- **SettingsScene, OutcomesScene:** overlays.
- **CreditsScene:** the credit roll with joke roles and the outcome count, then back to Title.

### UI and data
- `src/ui/DialogueBox.js`: typewriter text with per-character blips (turned off while TTS voices are on). It handles choices, thought lines and conditionals. Script steps:
  - `{who, mood, line, thought}` is a line of dialogue.
  - `{do:'hookName'}` calls a scene hook.
  - `{choice:[{text, if?, steps}]}` is a choice. An option can be hidden by a flag with `if`.
  - `{if:'flag', steps}` and `{ifNot:'flag', steps}` are conditionals.
  - The text speed comes from Settings.
  - Every picked choice is recorded in `scene.picked` and passed to `Outcomes.onChoice`.
- `src/data/scenes/scene1_the_map.js`, `scene2_goblins.js`, `scene3_metocy_mart.js`, `scene4_the_pass.js`: the dialogue scripts. Ebain's own lines are tagged `// Ebain` and my drafts `// DRAFT`.
- `src/data/characters.js`: names, portraits, moods, voice blip settings, and `PORTRAIT_FILES`.
- `src/data/combat.js`: PARTY stats and moves, ITEMS, THROWABLES, TRIP_MISFIRES, FIGHTS (enemy HP, AI, XP) and LEVELS.
- `src/data/deloyeLore.js`: five Lore Session passages. Each has `where`, `title`, `text`, one `right` continuation and two `wrong`. Ebain said to **leave it as-is** (one right answer per page).

### Systems, audio and effects
- `src/systems/save.js`: the autosave in localStorage `trio_save`. It's written when a scene finishes into Mart, Pass or Continue, and on New Game or Chapters.
- `src/systems/outcomes.js`: the 22 OUTCOMES, unlocked by choice text, by flags at scene end, or directly from combat. Stored in localStorage `trio_outcomes`.
- `src/systems/settings.js`: text speed, music, sfx and voice volume, and voice speed. Stored in localStorage `trio_settings`.
- `src/audio/Sfx.js`: every sound effect is synthesized with Web Audio. That covers blips, one-shots, background loops (night, fire, village, shop, trip) and **combat sounds**: slap, roar, hairflip, mog, zap, impactMagic, pages, chudThud, stomp, sitWarn, sitImpact, bonk, throw, hit, hurt, heal, buff, diceRoll, crit, miss, enemyDown, victory, defeat (sad trombone) and dance. Music is played through HTMLAudio: `playMusic` and `stopMusic`, with a retry on the next click or keypress.
- `src/audio/Voice.js`: **TTS character voices** through the browser's Web Speech API. Each character has a pitch, speed and preferred system voice. `clean()` fixes pronunciations ("shi" becomes "shee", "doe" becomes "dough"). V toggles it.
- `src/fx/ChromaKey.js`: a GPU green-screen shader for keyed videos.
- `src/fx.js`: effect textures (`fx_soft` and others), `coverImage` and `vignette`.

### Assets (`assets/`)
- `portraits/`: dialogue portraits for each mood.
- `characters/`: full-body cutouts, including combat and hurt poses.
- `backgrounds/`: camp_unlit and camp_lit, goblin_village, goblin_throne, mart_exterior, mart_interior, mart_interior_trip, mountain_path, giant_pass, title_trio.
- `items/`
- `video/`: map_burn, dulbers_transform, mattias_appear, giant_wake, xylo_chudout and xylo_chudout_short. Most are green-screen.
- `audio/menu_theme.mp3`

---

## 4. Story — Chapter 1 (full detail in DESIGN.md)

**Scene 1, "The Map" (IntroScene):** camp at night. Skorn grabs the sack and burns the map in a cutscene, then dawn comes. Last line: "Bet, my fault. I'm dumb as hell." Then the title card. **No choice here, by Ebain's request.**

**Scene 2, Goblin Village (Chief Bogdrinker):** there are five choices.
- **A, royal speech:** Ebain's lines. You get beezy ×3.
- **B, chug contest:** a mash minigame. A win shows "LEGEND!" A loss means Lykor passes out and wakes up outside with "METOCY MART, EAST. LOSER." written on his forehead.
- **C, crown Skorn:** sets `skornKing`. Skorn stays behind.
- **D, sneak out:** "Slow… quiet…" / "What the fuck is y'all doing?" The goblins join as allies (`goblinAllies`).
- **E, Skorn "negotiates":** a **fight** of Skorn against 3 goblins, then Lykor is dethroned.

**Scene 3, Metocy Mart (Dulbers Frint):** he offers the midtocy. There are five choices.
- **A, everyone takes it:** everyone trips, then the reveal, then a **fight** against demon Dulbers with the whole party tripping.
- **B, Skorn tries it first:** Skorn trips, then the **fight**, with only Skorn tripping.
- **C, refuse it:** you get kicked out and see the Giant's Pass sign. Dulbers escapes, setting him up as a future villain.
- **D, Xylo inspects it:** he cites Deloye Lore ch. 8,784 sec. B12. Dulbers hands over the midtocy and escapes.
- **E, goblins taste-test it:** only if you have goblin allies. A goblin brawl kills Dulbers (`dulbersDead`), then the goblins go home.

Skorn pockets the midtocy in every path except C (`hasMidtocy`).

**Scene 4, The Pass (Diddy Chud Giant asleep, Mattias appears):** there are five choices.
- **A, Skorn throws the midtocy:** needs `hasMidtocy`. The giant wakes and trips, then a **boss fight** against a Tripping giant.
- **B, sneak across:** the Snore Sneak minigame. A win steals the Chipotle Bowls and there's no fight. A loss means a **boss fight** against an Enraged giant.
- **C, Xylo reads him Deloye Lore:** the Lore Session minigame. Five epic passages, and you pick the right continuation. Get it right and he falls asleep. Get it wrong and it's the **boss fight**.
- **D, fight him:** a slap, then the **boss fight**.
- **E, let Chief Bogdrinker handle it:** needs `goblinAllies`. It turns out to be his cousin.

After the fight: "Okay, okay, okay, my fault. I ain't know y'all was some crashouts." / "Foolish..". Then Mattias's ending, then End of Chapter 1, then the credits.

**Story flags (registry):** goblinAllies, skornKing, chugWon, lykorDethroned, foreheadLoser, inv_beer, hasMidtocy, dulbersEscaped, dulbersDead, skornTripped, sneakWon, loreWon, inv_bowl, xp, level, used67, declined67.

---

## 5. Ebain's creative rules and preferences (important)

- **The tone is goofy BG3:** realistic art, dumb jokes, lots of joke labels (e.g. "Goblin (Between Jobs)").
- **Every scene needs a player choice.** Most choices should lead to different outcomes, and each major encounter keeps at least one combat option.
- **Dialogue workflow:**
  1. I lay out a scene as numbered lines, marking his characters' lines with ⭐.
  2. He replies with edits.
  3. **I apply his wording verbatim.** I only clean up grammar and spelling, never rewrite his jokes.
  4. His lines get tagged `// Ebain` and my drafts `// DRAFT`.
- **Art:** he makes images and videos with Gemini (realistic style) on green screen. I cut them out with numpy/scipy chroma-key scripts: edge flood fill, chroma distance, a spill key and dark-haze cleanup. The goblins are keyed without the spill pass.
- **Music:** Gregorian chant on the menu. **He'll add more music later**; the plan is AI-generated tracks, or a Claude-in-Chrome agent pulling from Pixabay with the handoff list in section 8.
- **Voice acting:** real voice acting is shelved. TTS robot voices are in instead, and he thinks they're funny.
- **The 6-7** happens once per game, and the dice are "on some dice shi."
- **Platform:** desktop only. Local saves are fine.

---

## 6. Combat system (Combat 2.0 — see DESIGN.md → Combat for every number)

- **Architecture:** `src/combat/engine.js` is pure rules (no Phaser) and returns event lists; `CombatScene.js` animates
  them. `tools/sim_combat.mjs` runs thousands of fights through the same engine with sloppy/average/good fake players.
  **Rebalance by editing numbers, then rerun the sim.**
- **Turn order:** speed timeline bar top-left (FFX-style). **Timed hits/blocks:** shrinking ring, SPACE.
  **Meters → ultimates** (FULL CRASH OUT, MOG SUPREME, CHUD OUT). **Team-ups** at 50% from two people (trio at 60%).
- Statuses both ways, boss Locked In after CC, telegraphs with counters, boss phase 2 at 50% (giant "Aight. Bet." +
  snack; Dulbers shapeshifts into bootleg party members), rare chaos events, banter bubbles + TTS, S–F grade with XP bonus.
- Settings: Combat difficulty (Chill/Normal/Crashout) and Timed hits (On/Auto).
- **Testing:** `window.TRIO_QTE='perfect'` auto-resolves timed presses. To script a fight, replace
  `scene.chooseAction` with an async function that returns actions (see the chat history for `test_script.py`).
- **Not yet human-tested:** how the timing window feels with a real keyboard (`qte()` in CombatScene: 850ms ring,
  PERFECT ±8px, GOOD ±22px, scaled by difficulty).

## 6b. Godot version (`godot/`) — THE MAIN GAME NOW

Ebain decided (Nov 2026) to go all-in on Godot; the Phaser version is no longer worked on.
**Target: Windows download (Ebain, Nov 2026).** The web build at https://aydenit247.github.io/Trio-Adventures/play3d/
is FROZEN at the Nov 21 village version — don't spend effort on web texture budgets anymore.
Windows build: `godot --headless --path godot --export-release "Windows" ../build/windows/TrioAdventures.exe` →
TrioAdventures.exe (the engine, never changes) + TrioAdventures.pck (the game). `build/` is gitignored (too big for
git); hand the zip to Ebain as a chat file. Updates usually only need the new .pck. Needs the Godot 4.7.2 Windows
export templates (windows_release_x86_64.exe) in ~/.local/share/godot/export_templates/4.7.2.stable/.
Desktop renders with Forward+ (SSAO, volumetric fog, glow); the sandbox screenshots use gl_compatibility, so the real
game looks a bit better than the test shots. New textures: VRAM compressed (compress/mode=2), 1K is fine.
- **Style: 2.5D.** 3D world; characters AND props are green-screen cutout cards (billboards) from Ebain's Gemini art,
  tinted per frame by `light_at()` (glows registered with `add_glow`). Photo ground textures blended by a shader
  (clearing + path points per area). Directional views: `<id>_back.png` / `<id>_side.png` (side faces right).
- **Code:** `scripts/level.gd` = shared engine (environment day/night, ground, `card()`, party/NPCs, camera,
  interactions, dialogue, HUD, joke labels `char_label()`, `knock()`, `walk_to()`, test helpers).
  Areas extend it: `camp.gd` (Scene 1, night) → `village.gd` (Scene 2, day) → `mart.gd` (Scene 3, evening) → `pass.gd` (Scene 4, lava). `game.gd` autoload = flags + items
  across areas. Dialogue data: `camp_script.gd`, `village_script.gd` (`# Ebain` / `# DRAFT`, same format as web).
- **Scene 1 (camp):** real props now too — mossy boulders and rock clusters, ferns, fallen branches, chunky sitting
  logs, a stump with an axe, firewood, pot + bowls by the fire, buckets, crates, a lantern (its light moved onto it).
  Camp close-ups: `LOOK="x,z,yaw;..." ... res://main.tscn -- --shots`. Fire out → bag → map → burn it → rest of Scene 1 → free roam → north path → "next morning" →
  village. (Mattias moved out of camp; his lines wait for Scene 4.)
- **Scene 2 (village), as Lykor:** walk in → ambush (labeled goblins) → kneel → chief → follow to throne → crowned →
  choice: A speech (+3 beezy) · B chug-off mash minigame (chugWon / foreheadLoser) · C crown Skorn (skornKing, Skorn
  stays) · D sneak — player really sneaks, gets caught, goblins follow (goblinAllies) · E Skorn fights (placeholder
  win, lykorDethroned). Then east exit → "To be continued" card.
- **Real environment art (Nov 2026):** `scripts/models.gd` (`Models.place(parent, id, pos, rot_y, scale, collide,
  recolor)`, `Models.mat(texture_id, tile_m, tint)` = world-space triplanar PBR material for any box/cylinder,
  `Models.block`, `Models.cylinder`). Assets in `godot/assets/models/<id>/` (glTF) and `godot/assets/textures/<id>/`
  (albedo/normal/rough.jpg), fetched with `tools/fetch_polyhaven.py`. Characters stay Gemini cutouts.
- **Explorable village (after the throne scene), `village_buildings.gd` + `village_rooms_script.gd`:** six places:
  round 3D huts (clay / log / stone walls, thatched roofs), a cloth tent, plank outhouse + job board, and a throne
  kitbashed from a real chair, rusty wheel rim and giant wooden spoons. Doors fade you into rooms built at x = 400/440/480/520 (sun + ambient dim indoors).
  1 Chief's Hut (Chief is home if he's not following you; belt, self-portrait, chest → Backup Conditioner, hay-bed nap) ·
  2 Unemployment Office & Bar (Sludge's **Bar Tab** quest: pay 3 Beezy / Lykor's mog → `bouncer` fight / fight; Gorbo's
  open mic: laugh or heckle; Gulpo **Chug Rematch** reusing the chug minigame; clerk window gag) · 3 Job Board + Grubnik
  (**Lucky Spoon**: the Goblin Patrol drops it → Weighted d6) · 4 Shaman's Tent (fortunes, **Lore-Off** 3-question
  quiz → Deloye Lore Vol. 9) · 5 Clank's Spoonsmithy (**Shiny Spoons**: 5 sparkly spoons around the village; 3 → Spoon
  of Destiny, 5 → Spoon Mail) · 6 Outhouse (each of the trio can go in once for a gag + loot). Quests live in
  `Game.quests` and show in the I menu. Named one-off speakers: `{ who = "goblin", name = "Sludge (Bartender)" }`.
  Test: `VILLAGE_TOUR=buildings TOUR_PART=1|2 ... res://village.tscn -- --shots`.
- **Scene 3 (Metocy Mart, `mart.gd`), as Xylo:** evening fog. Outside: Ebain's painted shop front is a stage-set
  backdrop (`backdrop()`, camera locked + flatter via `cam_locked`/`cam_height`/`cam_look_h`) → Dulbers pops out →
  go inside (room built at x=300: plank-floor shader + painted interior backdrop, swaps to the trip version) →
  choice A all trip / B Skorn trips (both → reveal, demon transform, placeholder fight) · C refuse → kicked out, pass
  sign · D Xylo's Deloye Lore inspection → deal · E (only if goblinAllies) goblins take Dulbers out. Flags: hasMidtocy,
  skornTripped, dulbersEscaped, dulbersDead; skornKing → Skorn bursts in. Exit east → The Pass.
  Test: `MART_CHOICE=0..4 ... res://mart.tscn -- --shots`.
- **Mart + Pass real art (Nov 2026):** Mart street: cobblestone ground patch (`Models.patch` = soft-edged textured
  ground decal), barrels/crates/sacks/bucket by the painted shop, two lantern posts with real light; shop room: a 3D
  counter with candlesticks in front of the painted one, barrels, sacks, crates, a bookshelf with bottles, pots.
  Pass: real rock faces + boulders (darkened, lava-lit) in front of the framing cliff cutouts, burnt-ground and
  dark-rock patches, charred logs and branches.
- **Scene 4 (The Pass, `pass.gd` + `pass_script.gd`), as Skorn:** new `lava` mood in level.gd (red ambient/fog/sky,
  burnt ground). Painted `giant_pass.jpg` backdrop with the giant asleep (floating Zzz at `GIANT_HEAD`), framed by big
  dark cliff cards. Walk up → Metocin Mattias poofs in (blue light) and vanishes → giant → choice: A throw midtocy (if
  hasMidtocy) → he wakes geeked → placeholder boss fight · B **Snore Sneak** minigame (hold E only while he snores; fill
  the snore meter and he wakes → fight) → +2 bowls · C **Lore Session** minigame (5 Deloye Lore pages, pick the true
  continuation; one miss → fight) → he rolls over · D Skorn slaps him → fight · E (goblinAllies) the chief's cousin, he
  leaves calmly. Waking swaps the backdrop to `mountain_path.jpg` and Ebain's awake giant (`giant_angry`, 7 m) stands up.
  Mattias's voice echoes → exit east → "END OF CHAPTER 1" card → back to the camp. Flags: sneakWon, loreWon.
  Test: `PASS_CHOICE=0..4 ... res://pass.tscn -- --shots`.
- **Combat (Godot, Nov 2026) — Combat 2.0 ported.** `scripts/combat/combat_data.gd` (all numbers/moves/fights/talk/gear),
  `battle.gd` (pure rules, port of engine.js), `battle_view.gd` (presentation). Ebain's picks: fights happen **right where
  you are** (party lines up left, enemies right, camera swings to a side angle, menus on top) · **XP + gear** (shared
  level, +10% HP/dmg per level; Level 3 teaches Belly Bump / Conditioner Mist / Citation Needed; one trinket per fighter,
  equip with **I**) · **visible roaming enemies** (`spawn_roamers(fight, home, radius)`: wander → notice you (walking is
  sneakier) → chase → touch = fight) · **recruited allies fight** (Chief Bogdrinker joins as a 4th fighter when
  goblinAllies) · **losing = funny penalty** (YOU GOT COOKED + sad trombone, then a goblin steals a Beezy / eats a bowl /
  writes on your forehead; story fights retry, roaming fights wake you at `checkpoint`) · **snappy side fights,
  cinematic bosses** · **Talk + Run** (Run = d6 4+, side fights only; Talk options per fight: bribe, job offer, roast,
  refund, compliment, feed the giant, lullaby) · **timed ring kept with an Auto option** (T in battle, or Esc menu).
  Level API: `await fight(key, { enemies = [units], mods = {} })`. Story fights wired: village E (`goblins`), Mart A/B
  (`dulbers`, tripping), Pass (`giant`: A tripping, B enraged). First roaming group: Goblin Patrol on the village east road.
  Esc = pause menu (difficulty, timed hits, voices, party). Balance sim: `godot --headless --path godot --script
  res://tools/sim_combat.gd`. Fight test: `FIGHT=goblins|dulbers|giant|goblin_patrol [LEVEL=2 ALLIES=1 AUTO_LOSE=1
  MENUS=1] ... res://village.tscn -- --shots`.
- **Placeholders:** goblin huts (tinted tent art) and the throne (built from shapes) until Ebain sends art.
  Mart uses painted backdrops instead of props (edges show from far back).
- **Art pipeline:** props `python3 tools/key_props.py <src> godot/assets/props`; character views
  `python3 tools/key_chars.py <src> godot/assets/characters`. Set `mipmaps/generate=true` in new `.import` files.
- **Testing here:** Godot binary from GitHub releases; `xvfb-run ... --rendering-method gl_compatibility
  [res://village.tscn] -- --shots` runs that area's `_shot_tour()` (SHOT_DIR env; VILLAGE_CHOICE=0..4 picks a path;
  `--views` walks 4 directions). Sandbox has no TTS/Forward+.

## 7. Open items / where we left off

**Big direction (Ebain, Nov 2026):** the camp, Goblin Village, Metocy Mart and the Pass are the MAIN EVENTS. He wants
lots of stuff in between and optional content: open-world-ish side areas, tents you can go inside (e.g. a goblin who
tells jokes), random interactive things, roaming enemies, gear to find. Next chapters add more main events.

0. **Friend's voice lines (in progress).** Ebain's friend is recording Metocin Mattias (3 lines) and the goblins (Chief
   Bogdrinker 25, regular goblin 3, crowd 9) as one MP3 with line numbers read out. Plan: split it, pitch-shift / voice-change
   each character, stack crowd lines into a mob, and play them instead of TTS for those characters.
1. **Pronunciation list (not answered yet).** I gave Ebain 38 words with my guessed pronunciations: names like Lykor ("LIE-kor"), Xylo ("ZY-low"), Caelid, Dulbmeethus, Metocin and Deloye; items like metocy ("meh-TOE-see"); slang like jit, aight, finna, looksmaxxin and Balright; and the abbreviations ts, mf, ngl and fw (spell them out or read them as words?).
   - He hasn't replied. My guesses aren't in the code yet; only "shi" → "shee" and "doe" → "dough" are.
   - When he answers, add respellings to `Voice.clean()` in `src/audio/Voice.js` as word-boundary regex replacements.
2. **Voice tuning:** he hasn't heard and judged the TTS voices yet. Adjust `PROFILES` (pitch and rate) in `Voice.js` based on his feedback.
3. **Music:** he'll provide tracks later. Planned slots:
   - camp/overworld
   - goblin village (goofy tavern)
   - Metocy Mart (cheesy shop music), plus a warped trip version
   - battle
   - boss
   - a mountain/pass track
   - a victory jingle
   - a "YOU GOT COOKED" sting

   Wire them up with `Sfx.playMusic`, crossfading between scenes and respecting the music volume setting.
4. **Real sound-effect files (optional):** if he sends Pixabay downloads (see section 8 for filenames), swap them in for the synthesized ones where they sound better.
5. **Credits:** I listed "Code, Cutouts & Sounds: Claude" and asked whether he wants it kept. No answer yet.
6. **Future chapters:** Dulbers comes back as a villain (he escapes in Mart paths C and D). There's room for Chapter 2 and beyond.
7. **Image ideas:** Ebain couldn't generate images for a while. More combat or emotion art can be added whenever he sends it.

---

## 8. Pixabay asset list (for a browsing agent, if Ebain uses one)

Put everything in `Downloads/trio-sfx/`. Use MP3, short and clean, under the Pixabay license only.

**Sound effects:**
- **Combat:** slap, punch, rage_roar, hair_swish, mog_sting, magic_zap, page_flip, ground_thud, giant_stomp, spoon_bonk, throw_whoosh, dice_roll.
- **Drinks and crowd:** bottle_clink, gulp, crowd_ooh, crowd_cheer.
- **Shop and world:** door_creak, shop_bell, footstep_dirt, snore, record_scratch, coins.
- **Loops:** fire_crackle, night_ambience, tavern_ambience, wind_mountain.
- **Jingles:** level_up, fail_trombone.

**Music (`music/`):** camp, goblin_village, shop, battle, boss, mountain, victory.

---

## 9. Working with Ebain

He's casual: he types fast and loose and likes things done rather than over-explained. He'll often answer with "do all of them" or "lets go." Give short, clear status updates with screenshots, and ask him for creative input, like dialogue lines, joke names and art.
