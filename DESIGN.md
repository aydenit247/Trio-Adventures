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
(marked `// DRAFT` in `src/data/scenes/`) waiting for Ebain's versions. Fights are placeholders until the
combat system is built. **Scene 4 (The Pass)** is foundation-only: art and staging in place, dialogue slots empty.
Title menu: Continue Story (Scene 2), Metocy Mart, The Pass, Replay Intro.


1. **The Map (camp, night) — play as Skorn.** Lykor warns nobody to touch his bag (the map is in
   it). Skorn is cold, finds "paper" in the bag, can't read, feeds the map to the campfire.
   → **Title card: "Trio Adventures" by Ebain.**
2. **Goblin Village — play as Lykor.** The goblins see Lykor and start **worshipping** him ("the Mogging Elf"),
   and the party asks them where the metocy is. The chief will only tell him once he's crowned. On the junk
   throne the goblins bring him beer ("beezy"), then reveal the catch: they'll only tell if he stays king forever. **Player choice, three different results:**
   - **Royal speech** ("My chopped goblins…" / "Bet dat.") → the chief just gives the directions.
   - **Sneak out** → the goblins tiptoe right behind him, then come along to Metocy Mart as an entourage
     (story flag `goblinAllies`; they show up and help in Scene 3).
   - **Let Skorn "negotiate"** → Diddy Slap → first fight → the goblins worship Skorn too → directions.
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
- **Scene 3:** TBD (ideas: everyone takes the midtocy / only Skorn / refuse it / goblins taste-test it).
- **Scene 4 — getting past Diddy Chud Giant:**
  - **A. Skorn throws something** (leftover midtocy) → wake-up cutscene → fight, but the giant is tripping (chaotic, a bit easier).
  - **B. Sneak across him** → interactive sneaking with a **snore meter** (don't wake him). Success: skip the fight and
    steal his snacks (Chipotle Bowls). Fail: he wakes up enraged → harder fight.
  - **C. Read him Deloye Lore** → an **interactive lore-reading session** (silly mechanic, not mic). Success: he sinks
    deeper asleep and rolls over, path opens. Fail: he wakes → fight.
  - **D. Fight him** → the full boss fight (guaranteed combat option).
  - **E. Secret, only if the goblins came along:** Chief Bogdrinker is his cousin and yells at him to move.

## Combat

**Simple, Pokémon-style turn-based combat** with set damage. Minor leveling up.
Goofy BG3 flavor through the moves, labels and dialogue — not BG3's mechanics.

Each character has a **Main**, **Special** and **Bonus** move:

| | Main | Special | Bonus |
|---|---|---|---|
| **Skorn** | **Diddy Slap** | **Crash Out** — intense rage | **Throw Anything** |
| **Lykor** | **Hair Flip** | **Mog** — giga chad face blinds enemies with his beauty + damage | **"on some type shi"** — screams it, buffs everyone |
| **Xylo** | **Eldritch Blast** | **Deloye Lore** — pulls out a huge book and reads at length about a vast universe (there is little to no actual lore); the godly energy damages the enemy | **Chud Out** — gets really big and sits on the enemy |

Damage numbers, cooldowns and leveling curve: **TBD** (placeholders in `src/data/characters.js`).

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

## Items

- **Metocy:** glowing blue capsule (`assets/items/metocy.png`), shown floating over the counter as "Metocy (100% Real)"
- **Midtocy:** cracked, moldy purple capsule (`assets/items/midtocy.png`), revealed big on screen when they realize it's fake
- Both are ready to use as inventory icons once items/combat exist.
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
appearing (green screen, Scene 4), the giant waking (Scene 4). Saved for combat: Xylo's Chud Out (green screen).

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

## Voiceline workflow

We walk through each scene beat by beat. Each beat has context and a slot. Ayden writes the
lines; blank slots get a Claude draft for approval. Lines live in `src/data/scenes/`.

## Open questions (TBD)

- Goblin village: how Lykor escapes (choices and outcomes)
- What Dulbers Frint's demon form looks like
- What Metocin Mattias wants / who he is
- Damage values, leveling, items
- Map sprites: pixel-art vs. using the realistic images in-world
