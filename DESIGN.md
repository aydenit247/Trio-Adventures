# Trio Adventures — Design Doc

*"Trio Adventures" by Ebain.* A goofy, semi-open-world browser RPG starring the Caelid trio.
This file is the single source of truth for decisions. Anything marked **TBD** is still open.

---

## The pitch

Skorn, Lykor and Xylo set out to find **the metocy**. They never get there cleanly — every step
turns into a mishap: unfortunate, silly, and funny. Tone: **BG3 drama + goofy comedy**.

**The metocy:** a magical, mystical herb that gives profound insight and godlike, immersive,
euphoric feelings — all packed into a tiny, oval, blue object.

## Structure

- **Semi-open world** — or at least the illusion of one. Areas feel explorable (optional NPCs,
  chests, side jokes), but there's a guided, staged route for the story.
- **Player switches characters** depending on the current part of the story.
- **Chapter 1 ≈ 15 minutes**, with room to keep adding chapters.
- **Title card comes after the intro:** once the opening scene ends, cut to
  **"Trio Adventures" by Ebain**.
- **Labels everywhere** — labeling things is a core joke (see *Labels* below).

## Characters

| Character | Who they are | Personality |
|---|---|---|
| **Skorn** | Purple orc in gold armor | Angry, **chaotic** |
| **Lykor** | Handsome blond elf | Funny, tamer |
| **Xylo** | Red dragon | Mysterious, funny, tamer |
| **Dulbers Frint** | Metocy Mart owner — actually a **shapeshifting demon** | "Hey guys, it's your boy Dulbers Frint!" |
| **Metocin Mattias** | Mysterious figure tied to the metocy | Appears abruptly: *"You had called?"* |
| **Diddy Chud Giant** | Giant asleep across the path | Chapter 1 boss |
| **Goblins** | Village to the north | Worship Lykor ("the Mogging Elf") |
| **Chief Bogdrinker** | Goblin chief | Spoon crown, curtain cape |

Later chapters (not in the foundation yet): **Dulbmeethus** and others.

**Looks (from Ebain's Grok images, in `assets/portraits/`):**
- Lykor: long blond hair, pointed ears, purple and gold high-collar coat
- Xylo: red dragon head, brown horns, blue eyes, ruffled white cravat, dark vest
- Skorn: lavender skin, slicked black hair, tusks, goatee, dark and gold armored coat
- Dulbers Frint: grey-blue skin, blond swept-up hair, big pointed ears, silver armor
- Metocin Mattias: grinning wizard, long grey beard, pointed hat, staff topped with a purple crystal
- Dulbmeethus: grey-blue cosmic elf, spiky silver hair, galaxy and lightning aura

## Chapter 1 — scene list

**Build status:** Scenes 1–3 are playable with real art. Scene 2–3 dialogue is mostly Claude DRAFT lines
(marked `// DRAFT` in `src/data/scenes/`) waiting for Ebain's versions. All three fights use the real combat system
(`src/scenes/CombatScene.js`, data in `src/data/combat.js`). **Scene 4 (The Pass)** is foundation-only: art and staging in place, dialogue slots empty.
Title menu: Continue Story (Scene 2), Metocy Mart, The Pass, Replay Intro.


1. **The Map (camp, night) — play as Skorn.** Lykor warns nobody to touch his bag (the map is in
   it). Skorn is cold, finds "paper" in the bag, can't read, feeds the map to the campfire.
   → **Title card: "Trio Adventures" by Ebain.**
2. **Goblin Village — play as Lykor.** The goblins see Lykor and start **worshipping** him ("the Mogging Elf"),
   and the party asks them where the metocy is. The chief will only tell him once he's crowned. On the junk
   throne the goblins bring him beer ("beezy"), then reveal the catch: they'll only tell if he stays king forever. **Player choice, five different results:**
   - **Royal speech** ("My chopped goblins…" / "Bet dat.") → directions + **Beezy ×3** (healing item).
   - **Chugging contest** vs. Chief Bogdrinker (button-mash minigame). Win → directions, the goblins call him a
     legend. Lose → he passes out and wakes up outside with "METOCY MART, EAST. LOSER." on his forehead
     (it's still there in Scene 3, and Dulbers clowns him for it). Flags: `chugWon`, `foreheadLoser`.
   - **Offer Skorn as king** → the goblins crown "The Purple King," the party leaves without him, and he bursts
     into Metocy Mart mid-scene: "THEY KICKED ME OUT." Flag: `skornKing`.
   - **Sneak out** → the goblins tag along to Metocy Mart as an entourage and help in the fight. Flag: `goblinAllies`.
   - **Let Skorn "negotiate"** → real fight → the goblins worship Skorn, Lykor is dethroned and loses his beezy
     to Skorn (callback in Scene 3). Flag: `lykorDethroned`.
   The goblin chief is **Chief Bogdrinker**.
3. **Metocy Mart — play as Xylo.** Shop sign: **"For all yo metocy needs n shi folk."**
   "Hey guys, it's your boy Dulbers Frint!" The party buys and takes his metocy… it's fake.
   Everyone starts experiencing **disorienting disarray** symptoms. Once they figure out it's
   fake, its real name is revealed: **midtocy**. Dulbers reveals he's a shapeshifting demon
   → fight.
4. **Metocin Mattias interrupts** — abrupt dialogue: *"You had called?"* He tells them to come
   find him by getting past the path that the giant is inconveniently sleeping on.
5. **Boss: Diddy Chud Giant** (see *Boss design*). Cutscene: a purple vial lands on him and the smoke wakes him
   up (idea: Skorn throws his leftover midtocy at him — TBD).

## Choices (rule)

**Every scene has a player choice, and most choices lead to a different outcome.** Each boss/major
encounter keeps at least one option that leads to a fight.

- **Scene 1:** a choice of what Skorn burns (the map / Xylo's lore book / Lykor's conditioner) — every option
  still ends with the map in the fire (that's the joke). Lines TBD.
- **Scene 2:** see the scene list (being reworked).
- **Scene 3 — the metocy (built):**
  - **A. Everyone takes it** → the whole party trips → demon fight (party tripping).
  - **B. Skorn tries it first** → only Skorn trips → demon fight (Skorn as a chaotic wildcard).
  - **C. Refuse it** → "Y'all could get the fuck out my store doe? Fo' I call up Dulbmeethus." → kicked out, the
    "GIANT'S PASS →" sign was there the whole time → Dulbers escapes (villain later). Skorn gets no midtocy.
  - **D. Xylo inspects it** (Deloye Lore, chapter 8,784, section B12: true metocy is NEVER moist) → Dulbers cuts a
    deal, hands over midtocy, flashes demon-red and escapes (villain later).
  - **E. Secret (goblins came along): the goblins taste-test it** → "BOGDRINKER KNOWS HIS DRUGS" → cartoon chase and
    dust-cloud brawl → Dulbers is never seen again (dead, off-screen) → the goblins go home.
  - Skorn pockets midtocy in every path except C (flag `hasMidtocy`, used for the Scene 4 throw option).
  - Flags: `hasMidtocy`, `dulbersEscaped`, `dulbersDead`.
- **Scene 4 — getting past Diddy Chud Giant (built):**
  - **A. Skorn throws the midtocy** (only if he has it) → wake cutscene → fight, giant tripping.
  - **B. Sneak across him** → **Snore Sneak** minigame: hold → / Space to move only while he snores (yellow warning
    before he stops, short grace window); moving during the quiet inhale fills the snore meter. Win: no fight +
    Chipotle Bowls ×2. Lose: enraged fight.
  - **C. Xylo reads him Deloye Lore** → **Lore Session** minigame: five pages from different chapters of Deloye Lore
    (`src/data/deloyeLore.js`), each a short mystical-epic story that stops mid-sentence; pick the continuation that
    stays true to the lore. Diddy Chud is secretly a lore nerd — accurate lore soothes him,
    wrong lore wakes him ("THAT AIN'T CANON."). Win: he rolls over. Lose: fight.
  - **D. Fight him** → "Aight, fuck allat. WAKE UP, CHUD!" → full boss fight.
  - **E. Secret (goblins still with you):** Chief Bogdrinker is his cousin and makes him move.
  - After any fight: "Okay, okay, okay, my fault. I ain't know y'all was some crashouts." / Lykor: "Foolish.."
  - Chapter ends with Mattias's voice, then the **End of Chapter 1** card.

## Combat

**Simple, Pokémon-style turn-based combat** with set damage. Minor leveling up.
Goofy BG3 flavor through the moves, labels and dialogue — not BG3's mechanics.

Each character has a **Main**, **Special** and **Bonus** move:

| | Main | Special | Bonus |
|---|---|---|---|
| **Skorn** | **Diddy Slap** | **Crash Out** — intense rage | **Throw Sum Shi** |
| **Lykor** | **Hair Flip** | **Mog** — giga chad face blinds enemies with his beauty + damage | **"on some type shi"** — screams it, buffs everyone |
| **Xylo** | **Eldritch Blast** | **Deloye Lore** — pulls out a huge book and reads at length about a vast universe (there is little to no actual lore); the godly energy damages the enemy | **Chud Out** — gets really big and sits on the enemy |

**Built — Combat 2.0.** Rules: `src/combat/engine.js` (pure logic, no Phaser). Numbers: `src/data/combat.js`.
`CombatScene.js` only animates what the engine decides. Balance sim: `node tools/sim_combat.mjs 3000`.

**Turn order:** a speed timeline (FFX-style), shown top-left. Speed: Skorn 9, Lykor 12, Xylo 10, goblins 7,
Dulbers 16, giant 14 (×1.25 in phase 2), goblin backup 9. Stuns/charms show as SKIP on the bar.

Each turn: **Main / Special (cd) / Bonus (cd) / ★ Ultimate / Team-Up / Items / Defend.**

| | HP label | Main | Special (cd) | Bonus (cd) | Ultimate (100% meter) |
|---|---|---|---|---|---|
| **Skorn** 90 | HP (Hit Points) | Diddy Slap 14 | Crash Out: d6 (3) | Throw Sum Shi 10, 40% Down Bad (2) | FULL CRASH OUT: 2 dice, 7 per pip, Humbled; 6+6 = double or the 6-7, 1+1 = hurts himself |
| **Lykor** 70 | Aura | Hair Flip 10, 30% charm (+15% on PERFECT) | Mog 20 + Mogged (3) | "on some type shi": next 3 attacks ×1.5 (3) | MOG SUPREME: 36 to all + Mogged + Blinded |
| **Xylo** 75 | Lore Points | Eldritch Blast 13 | Deloye Lore 24, 50% Lore-pilled (100% on PERFECT) (3) | Dragon Breath 15 + Cooked (2) | CHUD OUT: 45 + loses a turn (plays the video) |

- **Timed hits:** a ring shrinks onto a gold circle, press SPACE. PERFECT ×1.5, GOOD ×1.2, MID ×0.9.
- **Timed blocks:** same ring on enemy attacks. PERFECT ×0.35, BLOCKED ×0.7. AoE = "EVERYONE BRACE".
- **Meter:** dealing damage (up to 15), PERFECT +8 / GOOD +4, taking damage, blocks (+15/+8), Defend (+12), hype.
- **Team-ups** (each member spends meter; partners' next turn is pushed back a bit): Elf Toss (Skorn+Lykor, 48 +
  Mogged), Lore Slap (Skorn+Xylo, 6×8 + Lore-pilled), Mogging Fireball (Lykor+Xylo, 28 to all + Cooked), ON SOME TRIO
  SHI (all three, 60% each, 85 + everyone heals 15).
- **Defend:** half damage (a quarter from the sit), enemies aim at you 70% of the time, +12 meter, cooldowns tick 1 extra.
- **Items:** Beezy heals 30 + Buzzed (25% misfire next move), Chipotle Bowl 60. Both revive a knocked-out ally.
  Emergency Beezy only when someone is down and you have nothing. Losing a fight and retrying restores your items.
- **Statuses on enemies:** Mogged (+25% dmg taken), Lore-pilled (50% skip), Down Bad (half dmg), Cooked (6/turn),
  Blinded (60% miss), Charmed (skip; with other enemies alive he's Glazed and bonks a buddy), Sat On (skip), Humbled (buffs stripped).
- **Enemy buffs:** Locked In (bosses, after losing a turn to CC: immune to charm/stun/lore-pill for ~2 turns), Hyped Up
  (goblin "LET'S GOOO": next hit ×2), Copium (Dulbers heals 8/turn, a 25+ hit breaks it), Aura Shield (Dulbers steals
  Lykor's aura: absorbs 35), Second Wind (Goblin (Between Jobs) gets up once: "I NEED THIS JOB").
- **Party debuffs:** Price Gouged (heals halved), Flattened (lose a turn), Bricked (special cd +1), Item Stolen.
- **Enemies:**
  - **Goblins ×3:** 26 HP, Spoon Bonk 9, hype each other.
  - **Dulbers:** 300 HP (×0.75 without Skorn). Price Gouge 34 + Price Gouged, NO REFUNDS 21 to all + Bricked, steals a
    beezy (max 2), Aura Shield. **Phase 2 at 50%:** shapeshifts into bootleg party members (red tint): Bootleg Skorn slap
    36, Knockoff Lykor hair flip 18 + may Flatten, Generic Xylo blast 20 to all; Copium once.
  - **Diddy Chud Giant:** 520 HP. Stomp 28 (aims at the healthiest), Ground Pound 17 to all, every 3rd move a telegraph:
    SIT (44 to all + Flattened unless you defend or block). Charm/stun him during the telegraph = he sits on his own foot
    (35). **Phase 2 at 50%:** "Aight. Bet." Faster, and alternates the sit with a Chipotle Bowl snack (heals 60 unless
    you hit him for 30+ or stun him first).
- **Chaos events** (1.5% per enemy turn, max once per fight): goblin throws a beezy, Dulbmeethus fills a meter,
  Mattias says "Impressive." (+15 meter), a rock falls on the enemy, or (goblin fight) a job-hunting goblin walks by.
- **Banter:** speech bubbles + TTS on perfects, ults, low HP, KOs, phase changes, enemy taunts (`BANTER` in combat.js).
- **Grade:** S–F from damage taken, KOs, items, perfect-press rate and turns vs par. S = ×1.25 XP, A = ×1.1.
  Best grade per fight saved in localStorage `trio_grades`.
- **Difficulty (Settings):** Chill (×0.75 enemy dmg, ×0.9 HP, wider timing window), Normal, Crashout (×1.25 dmg,
  ×1.1 HP, tighter window). **Timed hits & blocks:** On, or Auto (always GOOD).
- **Choices change fights:** tripping (22% misfire / 20% crit), goblin backup (in the turn order, bonk 10),
  enraged (+15% HP, ×1.1 dmg), giant tripping (30% he hurts himself or forgets).
- **Balance (sim, Normal):** average player wins ~95–99% with about half HP left; sloppy players lose the boss about
  half the time; Crashout is a real challenge; Chill rescues sloppy players (~85%).
- **Leveling:** XP 30/60/100 per fight (× grade bonus); levels at 50/120/220/350. Each level = +10% HP and damage.
- **Lose:** "YOU GOT COOKED" + tip → Space to retry. **Win:** "VICTORY (on some winning shi)" + grade + XP.
- **Tutorial:** "How To Fight" card once (localStorage `trio_tut_combat2`). Test hook: `window.TRIO_QTE = 'perfect'`.

### Dice — "on some dice shi"

Combat stays set-damage; the dice only appear for special moments (Crash Out outcomes, the
giant's talk check, certain story choices).

- Dice overlay header reads **"on some dice shi"**. It's a **d6**.
- **The 6-7:** once in the entire game, when you roll a 6, a **"+1?"** button appears. Accept
  it and the 6 becomes a 7 — the party does the **6-7 dance** as a special attack.
  If you pass on it, the game remembers (possible callback joke later).

## Boss design — Diddy Chud Giant

Mostly the same goofy turn-based combat, plus bonus layers:

1. **The giant is the map.** Phase 1: sneak across his sleeping body to reach a weak spot with a
   **snore meter** — every action raises it; fill it and he wakes up early and angry.
2. **Lullaby minigame.** Mid-fight, a rhythm/timing minigame to sing him back to sleep for free hits.
3. **Talk your way out.** A dice check mid-fight (Skorn can only Intimidate). Win the roll and
   the fight can end early with a funny outcome.

## Deloye Lore (the "canon")

- **The First Metocy** (Ch. 8,784 · Sec. B12 · Pg. 3): fell from the sky like a tear from a bored star; true metocy
  is dry as bone, blue as heaven, never moist.
- **The Sneeze of the Dragon Mama** (Ch. 112 · Sec. A7 · Pg. 9): the first dragon was sneezed out; why dragons swear
  "On my Dragon Mama."
- **The Throne Beyond the Smoke** (Ch. 6,006 · Sec. Z1 · Pg. 44): **Dulbmeethus** is a god in a dimension behind the
  smoke. You reach him by smoking a **"Dulber's Frint Pack"** and astral projecting. His greeting: **"Y'all could hear me doe?"**
- **The Spoon That Became** (Ch. 4,040 · Sec. C3 · Pg. 12): a bored Dulbmeethus made the first goblin from a spoon.
- **The Prophecy of the Three** (Ch. 9,999 · Sec. Q2 · Pg. 1): the purple one who cannot read will feed the only map
  to the fire.

## Items

- **Metocy:** glowing blue capsule (`assets/items/metocy.png`), shown floating over the counter as "Metocy (100% Real)"
- **Midtocy:** cracked, moldy purple capsule (`assets/items/midtocy.png`), revealed big on screen when they realize it's fake
- **Healing items:** **Beer** ("beezy") and **Chipotle Bowls** (replacing bread/soup).
- **Dice:** wooden d6 with gold pips (`assets/items/dice.png`) for the "on some dice shi" overlay.

## Labels (running joke)

- Title: **"Trio Adventures" by Ebain**
- Dice overlay: **"on some dice shi"**
- Loading screen: **"Loading… (on some loading shi)"**
- Metocy Mart sign: **"For all yo metocy needs n shi folk"**
- Ideas to approve: Lykor's bag "DO NOT TOUCH (Skorn)", campfire "Fire (needs food)",
  enemy taglines like "Goblin (Unemployed)", "Diddy Chud Giant (Asleep, Do Not Disturb)",
  Lykor's HP bar labeled "Aura".

## Art & audio

**Videos in the game:** map burn (Scene 1), Dulbers's demon transformation (green screen, Scene 3), Mattias
appearing (green screen, Scene 4), the giant waking (Scene 4). Xylo's Chud Out (green screen) plays in combat (trimmed `xylo_chudout_short.mp4`).

**Scene 1 art (live):** painted camp backgrounds (unlit + lit), full-body green-screen cutouts of the trio,
and the map-burning cutscene video (`assets/video/map_burn.mp4`). Scene presentation style: **painted scenes
with full-body characters** (Darkest Dungeon / Disco Elysium feel); the speaker is highlighted, others dim.


- **Art style: realistic**, from Ayden's Grok images.
  - Portraits: chest-up, facing camera, plain solid background, square, same lighting/style.
  - Extra expressions per character (normal, angry, shocked, + Lykor's Mog face).
  - Drop files in `assets/portraits/` named `skorn.png`, `skorn_angry.png`, etc.
- **Voice audio:** shelved for now (text dialogue). Can add later.
- **Sound effects:** synthesized live in code (`src/audio/Sfx.js`), so there are no audio files yet.
  - Each character has a dialogue "voice blip" while their text types out (Skorn low and buzzy, Lykor bright, Xylo low and breathy, and so on)
  - UI clicks/ticks/confirm, label pops, an "item get" jingle, whooshes, fire ignite, a camera-shake boom, a "wait what" sting, and a title chord
  - Ambience loops: night (wind + crickets), campfire (roar + crackles), and birds at dawn
  - **M** or the top-left button toggles mute
- **Main menu music:** Gregorian chant track (`assets/audio/menu_theme.mp3`), looping on the title screen.
- **Other music:** later. Real recorded/licensed sounds can replace any synthesized one later.
- **Platform:** desktop only.

## How they talk

Everyone talks in casual slang, with profanity. Signature phrases so far:

- **Lykor:** "on the absolute", "say you swear to the absolute", "aight bet", "good shit"
- **Xylo:** "On my Dragon Mama"
- **Skorn:** calls people "mud" and "jit", has a lot of inner-monologue rage, and his logic is unhinged but delivered with total confidence

## Systems

- **Autosave** (`src/systems/save.js`): a checkpoint is saved whenever a story scene ends (flags, items, XP, level).
  Title menu: **Continue (scene name)** · **New Game** (asks to confirm if a save exists) · **Chapters** (jump to any scene
  with default progress) · **Outcomes x/22** · **Settings** · **Replay Intro**.
- **Outcome tracker** (`src/systems/outcomes.js`): 22 outcomes (every choice, minigame win/loss, and combat moments like
  the 6-7 and getting cooked). Found ones persist across playthroughs; unfound ones show a hint. A "📜 Outcome found" popup
  appears when you unlock one.
- **Settings** (⚙ button or **O**, works anywhere): text speed (Slow/Normal/Fast/Instant), music, sound effects and voice
  volume, voice speed, voice test.
- **Combat tutorial:** a "How To Fight" card before your first fight ever.
- **Credits:** after "End of Chapter 1", a credit roll with joke roles and your outcome count, then back to the title.

## Character voices (text-to-speech)

Every dialogue line is read aloud by the browser's built-in TTS (`src/audio/Voice.js`). Robotic on purpose.
Each character has their own pitch/speed: Skorn deep and fast, Lykor high and smooth, Xylo low and slow,
Dulbers squeaky salesman, demon/giant as low as it goes, goblins chipmunk. Toggle with **V** or the 🗣 button.
Which actual voices you get depends on the browser/OS (Chrome: Google voices; Windows: David/Mark/Zira).

## Voiceline workflow

We walk through each scene beat by beat. Each beat has context and a slot. Ayden writes the
lines; blank slots get a Claude draft for approval. Lines live in `src/data/scenes/`.

## Open questions (TBD)

- Goblin village: how Lykor escapes (choices and outcomes)
- What Dulbers Frint's demon form looks like
- What Metocin Mattias wants / who he is
- Damage values, leveling, items
- Map sprites: pixel-art vs. using the realistic images in-world
