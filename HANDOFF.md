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
- **Dulbmeethus:** god behind the smoke. "Y'all could hear me doe?" Sometimes pulls up mid-fight and lightning-strikes the whole enemy side (Ebain 11/24; 6.7% of fights since 11/25).
- **King Nibbsworth III** (Rat King), **Scrounge** (rat trader), **Lil Nibbs** (pet rat): the Rat Cave. All three names
  are Claude DRAFTs (Ebain said "you draft names"), so he may rename them.
- **Deloye:** wrote Deloye Lore. Floats and twirls in the middle of the secret library, earbuds in, chill, surprised
  anyone actually read it (Ebain 11/24; his art = Ebain's pictures: grey hoodie, wired earbuds). Gives Xylo the
  **Deloye Lore Neuralink**.
- **Charis:** lives in the house right of the Metocy Mart. Ebain's art is in (11/24); one DRAFT greeting until he writes her lines.
- **Items:** Beezy (heals 30), Chipotle Bowl (heals 60), Midtocy (the fake metocy), the d6 ("on some dice shi").

### Chapter 1 flow (each main event has a 5-way choice)
1. **Camp (night, as Skorn):** fire's out → grab the bag → find the map → burn it to start the fire (oops) → roam →
   head north. No choice here — Ebain wants it that way.
   **Bedtime (Asar 11/22):** after the fire, the tents say "Sleep in": Skorn swears he'll guard the fire, Lykor and Xylo
   turn in, Skorn passes out by the fire → "The next morning…" → the camp reloads in daylight (`campSlept`) → the morning
   lines → head north. Walking out before sleeping: Lykor says "We leave at sunrise" and sends you back.
1½. **Goblin Woods Trail (morning, Asar 11/22):** a long walk between Camp and the Village to earn gold before the shop:
   6 searchable loot spots (sparkles) and Asar's **Bridge Troll** by the creek: "Y'all had said i could get some
   bussy?" → "It's good" (Xylo follows him into his hut: Ebain's Gemini video `troll_hut_in.ogv` (troll waves him in, door
   slams), then Asar's three "love and light" clips play over `troll_hut_love.ogv`, the hut shaking (Ebain's clip looped
   with crossfades to 49 s + camera shake that follows the audio's loudness; black screen + separate clips if it's missing),
   Hold [E] to skip with a ring that fills while held and drains when let go, `trail.gd _love_and_light()`; bridge opens; then it's just Lykor and Skorn, exits blocked, until you
   knock on the hut and Xylo walks out: "Damn he was digging in me, folk"). On the doorstep, before Xylo goes in (Ebain
   11/26): Lykor "I always knew you were on that type timing", Xylo "Shut up Lykor" (`troll_walk` → lines → `troll_enter`).
   The troll talks as speaker `troll` (`dialogue.gd CHARS`): **Chief Bogdrinker's voice, lowered** (robot: the Chief's
   voice via `voice_as`, pitch 0.55; clones: refs from the Chief's takes, `FX["troll"]` -4 semitones in `tts_batch.py`) or "Bad." (troll fight, lots of gold, then loot
   his hut and chest). Flags `trailStarted`, `trollMet`, `trollDone` ("good"/"bad"), `trollHut`, `trollChest`, `xyloInHut`,
   `trailLoot0..5`, `trailDone`.
2. **Goblin Village (day, as Lykor):** ambush → kneel → the Chief → crowned at the spoon throne → choice: A royal
   speech (+3 beezy) · B chug-off minigame · C crown Skorn (he stays behind, `skornKing`) · D sneak out for real,
   goblins follow (`goblinAllies`) · E Skorn fights 3 goblins (real combat). Then the village opens up (section 4).
3. **Metocy Mart (evening, as Xylo):** walking up the street only gets Xylo's "I can feel it" line; **Dulbers pops out
   when you try the shop door** (Ebain 11/24, `MS.ARRIVE` → `MS.DULBERS_OUT`). Dulbers offers the midtocy → A everyone trips / B Skorn trips → boss fight vs
   demon Dulbers · C refuse → kicked out · D Xylo inspects it (Deloye Lore ch. 8,784 sec. B12) · E goblins handle it
   (if allies). Skorn pockets the midtocy in most paths (`hasMidtocy`).
3½. **Side path: Old Ruins → Rat Cave → Rat Colony (RUINS_PLAN.md, built 11/24).** Optional, never blocks the story. A
   path WEST off the Metocy Mart street (sign "OLD RUINS", open before and after the Mart scene) leads to `ruins.tscn`
   (day): 3 loot spots and THE BIG SHINY CHEST on a dais. Opening it: the floor gives way → `cave.tscn` (dark, torches,
   light around the leader). The cave: landing chamber (rope out of reach) → tunnel (2 loot spots, 2 roaming "Rat
   Patrol" groups) → **The Three Seals** puzzle → the colony. **Puzzle:** a 7×6 grid; boulders slide until they hit a
   pillar/wall/boulder; each boulder (spoon / book / bowl) must stop on the plate with its symbol. Only **Skorn** can push the
   big spoon boulder, only **Lykor** fits through the crack into the side room (lever → the rubble drops and the bowl
   boulder rolls out of its alcove), only **Xylo** can read the wall carving, which makes the plates' symbols glow, and
   the door won't open until it's been read. A rope resets the boulders. **Help (Ebain 11/24, he
   couldn't figure it out):** Xylo explains the carving in plain words; a blue "stops here" ring shows where the boulder
   you're next to would slide; a hint every 30 s stuck (first the general one, then an exact next move from a solver,
   `cave.gd solve_next()`, or "pull the reset rope" when the boulders are in a dead end: ~35% of states are); after
   3 min a **skip** is offered (and stays on the reset rope); the other two wait by the entrance while you're in the
   chamber (`_followers_wait`). Solution
   (7 pushes): book W, S · spoon W, N · bowl N, E, N. **The colony:** King Nibbsworth III on a junk pile, Scrounge's stall,
   12 joke-labelled rats → 5-way choice: fight (boss fight `rat_colony`, Corncob Scepter drop, no trader) · Skorn
   crowned Rat King (Bottle-Cap Crown, trader half price) · business (trader's "good shelf": Lucky Crumb + Corncob
   Scepter) · Xylo out-lores the King (+40 gold, secret tunnel straight to the Mart street) · Lykor mogs them (**Lil
   Nibbs**, a tiny rat, follows the party in every area: `ratPet`, `Level.spawn_pet()`). Then a tunnel up to the ruins
   (and back down). Flags: `ruinsStarted`, `ruinsLoot0..2`, `ruinsFell`, `caveEntered`, `caveLoot0..1`, `sealsRead`,
   `sealsLever`, `sealsSolved`, `ratsDone` (string: fight/king/trade/lore/mog), `ratPet`, `charisMet`. All lines DRAFT
   in `ruins_script.gd`.
   **Charis's house:** the house right of the Mart (yard behind a gap in the back wall) can be entered **before and after**
   the Mart scene (Ebain 11/24), no sign over the door. Inside: her **gaming setup** (desk, two glowing monitors, RGB
   tower, pink gaming chair; `_gaming_setup`, "Look at" → `RS.CHARIS_PC`, DRAFT). Interior built off to the side at x 340 (`mart.gd _charis_house`). Talking to Charis: `charisMet`. His stuff is `charis_props.gd` (Asar 11/25): driveway + red car out front, Morgana (Bahgoots) the cat, collector shelf on the back wall (figures, holo card, manga).
🔒 **Secret: the Deloye Lore library (DELOYE_PLAN.md, built 11/24).** Never on the main route, no markers. 5 **Lost Deloye
   Lore Pages**, one per area (`lost_pages.gd SPOTS`: camp behind Skorn's tent, trail at the north end of the troll bridge,
   village behind the outhouse, Mart in the shop's back-left shelf corner, Pass in the rocks left of the sleeping giant).
   Prompt only within 1.5 m; Xylo murmurs "…I smell parchment." when he leads within 8 m. Found pages are saved in
   `Game.progress` (`lostpage_<area>`, across playthroughs, not part of the 100 points); Tab → Quests lists them with
   their snippets. With 5/5 a **flush chain** appears on the outhouse's east side (`village.gd FLUSH_POS`, the outhouse
   itself is Asar's village_buildings.gd) → everyone squeezes in, the outhouse spins, FLUSH, white → **the pipe ride**
   (Ebain's Gemini video `assets/video/pipe_ride.ogv`, 10 s, screams only, skippable, ends on white) → `deloye_library.tscn`:
   **a big library you walk through** (Ebain 11/24: "much bigger place you have to walk around in", Deloye at the end).
   You drop out of a pipe into the **Atrium** (south) → the **Grand Stacks** (long hall north) → side wings: **Hall of
   Wind** (west, open window, blowing pages) → **Restricted Section** (velvet rope), **Rock Room** (east, THE ROCK on a
   pedestal) → **Reading Corner** (table, SAVED SEAT, and a **radio** that plays Ebain's Deloye song from there:
   `assets/music/deloye_lore.ogg`, on when you arrive, E toggles; until the file exists it's static).
   **Ebain's script (11/25, `deloye_script.gd`, his lines tagged `# Ebain`):** landing → Lykor "What the fuck folk? T S is
   massive…", Xylo "On dulbmeethus" → **Metocin Mattias teleports in** ("Y'all had said Deloye Lore easter egg?…") and
   follows you. Walking banter plays as speech bubbles (the game keeps going), ending with Mattias "My fault folk, Look
   over here. Follow me." → he walks you to the first **joint piece**. Three pieces, one per lectern: **the cannabis plant**
   (Hall of Wind), **RAW papers** (Restricted Section), **a lighter** (Rock Room). First piece → "I think we need to find all
   the materials for T S…" + Lykor "Shlooks folk." Talk to Mattias → "You could help me?" ("Bet.", he walks you to the rest,
   then to Deloye's room) or Leave. All 3 → Deloye from his room: "You had let's burn it? Pull up my trio." → the rune
   curtain opens. Walking in: Deloye "You could pass that shit?" → **A** "Here you go folk." → "Thank you. Here you go, mud." +
   the Neuralink · **B** "You had said puff puff pass?" → everyone smokes (placeholder smoke + haze; Ebain may make a real
   cutscene) → **Faded** for the next 3 fights + the Neuralink · **C** "Bad." → "Aight. Im not trippin i got da plug on the
   way", you keep the **Joint** (fight item: whole party Faded for that fight) and Deloye disapproves of Xylo: his Deloye
   Lore moves (Deloye Lore, Lore Slap) **fizzle 50%** for the rest of the run. Then "Aight imma catch
   yall" → everyone poofs back to the goblin village. Coming back later: no Mattias, Deloye's room open.
   **Faded** (Ebain: "chill healing"): heal 4×level-scale every turn, take 10% less damage (`combat_data FADED`,
   `battle.gd faded_ids`). Flags (per run): `libEntered`, `libMattias`, `libBanter`, `libGuided1`, `libGuideAll`,
   `libPiece_plant/papers/lighter`, `libGateOpen`, `deloyeMet`, `deloyeGift`, `deloyeBad`, `fadedFights` (int).
   **Readable books (Ebain 11/25):** 6 lore books on stands/shelves (glow + sparkles), "Read" opens a two-page parchment
   book screen (`book_ui.gd`, A/D turn, Esc closes; the narrator reads each page aloud via `VoiceLines.read_aloud`, voice files keyed by the page text, so a reworded page goes silent until regenerated), text in `library_books.gd` (Ebain OK'd the drafts): The Prophecy of
   the Three (Grand Stacks), Vol. 3,112 On Metocy (Hall of Wind), The Book of Dulbmeethus Ch. 1 (Restricted), Mattias's
   Library Card (Reading Corner bookshelf), Vol. 6,700 The Giant (Rock Room), The Prophecy of Death (Deloye's room).
   Arriving unlocks `deloye_found` (hidden achievement "Lore Accurate" + the secret last Scrapbook page). The EXIT door
   (rotunda) or the pipe (Atrium) also go back to the village by the outhouse. Free roam resumes from saves where you
   stood (Mattias too). Room/look-at lines are DRAFT.
4. **The Pass (lava, as Skorn):** first time only, **"The Tale of Diddy Chud" music video** (Asar's idea, Ebain's song, 11/25: camera cuts, volcano eruptions, lava bombs, geysers and screen shake synced to the song, Hold [E] to skip, flag `chudMusical`, `pass_musical.gd`) → Mattias appears → the giant is asleep in the way → A throw the midtocy (giant trips)
   · B **Snore Sneak** minigame · C **Lore Session** minigame (pick the true Deloye Lore continuation) · D slap him ·
   E it's the Chief's cousin (if allies). Fights are real boss fights. The only way on is the gorge right behind where he
   sleeps (Asar 11/22), so you can't get past until he's dealt with.
5. **The Summit Path + the Wizard's Lair (night, Asar 11/22; finale built from Ebain's `SUMMIT_FINALE_PLAN.md` 11/24):
   the final event of Chapter 1.** Arriving: a slow camera dolly while Skorn/Xylo/Lykor catch their breath (Xylo's line
   changes with how this run got past the giant/troll), then (no toast since 11/25, Asar)
   Ebain's "The Hymn of Metocin Mattias" starts (plays once; hearing it once counts for good: `hymnHeard` flag + progress
   id `hymn_heard`, it never restarts and Mattias is talkable from then on, `summit.gd _hymn_watch`). A long climb (3 clearings saved for future events:
   `EVENT_SPOTS` overlook / shrine / cart). **Halfway** (z < 8, by the shrine): Mattias's echo "Impressive, my beloved
   trio…" (moved here from the Pass) + Lykor "Bet. Here we go, folk". **Dulbers' ambush** right after, only if he's alive
   on this run (`dulbersEscaped` and not `dulbersDead` = the Mart refuse / Xylo paths): regular-size Dulbers sprints up
   from behind (the song ducks to the background) → apologize + swear loyalty to Dulbmeethus ("Good boy.") · fight him ·
   offer him fentocy (he dies) · call for Mattias ("Get lost midget fucker!", Mattias fights as a 4th fighter). Then the
   plaza, the tower, the hall. Walking up to Mattias before the hymn ends: "Peep the song first folk" (Asar) and a step
   back. In the study: the **OG Metocy** (Asar 11/23), his orange pill in a glass case on the old bust's pedestal with a
   brass "OG Metocy" plaque; E Inspect hides the party, swings the camera to the south-west (`OG_YAW`,
   clear of the study's armchairs; Ebain 11/24 couldn't see it), glides in, blurs the background and shows "OG Metocy / Dis shi was ahh
   folk, blue one way better" (Asar, `summit_script.gd OG_METOCY_*`, `summit.gd _inspect_og`). The hall's round wall is solid all the way round (doorway
   too: you leave with E), the camera pulls in near the walls so it never ends up outside (`_hall_camera`), and the star
   points at Mattias inside / the lair door outside (`_lair_objective`). Same idea in the Mart: inside the shop or
   Charis's house the star points at the door out (`mart.gd _star_indoors/_star_outdoors`). **The castle:** the music drops out, torches flare, "Welcome to da crib folk… I had heard that y'all ___. That's
   OD." (the blank = the biggest thing from this run), the metocy hovers → 5 choices: "Bet. Here we go folk." · "you had
   said u was fuckin wit one too?" (all four take it) · "Bad." ("Oh okay." → hard cut to black, END OF CHAPTER 1, silence)
   · sucker punch → near-impossible Mattias boss (**losing is its own ending**: "Y'all must be geeking off that midtocy…") ·
   ask for it in a Chipotle Bowl. After taking it: give every goblin metocy? Yes → the goblin party (dancing goblins,
   band, "The Mogging Elf", confetti, orbiting camera) → credits. No → credits. **Every ending ("Bad." too, after its silent END OF CHAPTER 1) rolls the same end credits** (`credits.gd`, Ebain 11/26). Flags `summitStarted` (set after the
   arrival lines), `summitHalfway`, `lairSeen`, `lairEntered`, `foughtWithMattias`, `tookMetocy`, `mattiasBeaten`,
   `chapter1Done`, `endingBad/Cooked/Normal/Party`, and the per-run strings `way_ambush`, `way_castle`, `way_goblins`.

**Story decisions (Ebain):**
- Beating Dulbers in the Mart boss fight counts as **killing him** (same as the goblin chase): `dulbersDead`. He only
  comes back (the summit ambush) on runs where he got away.
- **Fentocy** is a different pill from midtocy. Offering it to Dulbers kills him (he thinks it's midtocy).
- Losing the sucker-punch fight against Mattias is its own Chapter 1 ending, not a retry.
- **The land is called Chudmoor** (Ebain 11/25).
- **Death** (Ebain 11/25) is a real character: a really nice, personable guy who is also the Grim Reaper. He isn't after
  the metocy; he only shows up to be there for people who died. He has taken metocy with Dulbmeethus.
- **Dulbmeethus** was a god from the start and **made metocy**; he gave Mattias the metocy spells and made him its
  wielder in this reality (he keeps it from the unworthy). They've been metocy and smoking buddies for ~500 years.
- **Deloye** is just some guy who ended up in the library and is forced to write about the universe forever by
  **John and John's orb**; some see him as a god and all-knowing prophet. (What John is: not given yet.)
- **Game 2 (Ebain 11/25):** the trio meet Dulbmeethus and get put on a mission for him, plus lots of other mishaps.
  Book 1 hints at it; book 10 hints they'll meet Death.
- **Metocin Mattias** (Ebain 11/25): almost 500 years old, a wise, resilient wizard (no special reason he's that old), has spent it learning Deloye Lore and taking metocy with
  Dulbmeethus, and fears that one day he'll succumb to Death himself. He knows the Deloye library and guides the trio there.
- **Deloye** smokes; the library's final room is about passing him a joint (A/B/C above). Telling him "Bad." makes him
  disapprove of Xylo for the rest of the run.

- **Combat direction (Ebain 11/26):** keep the current turn-based system (he tried a BG3 grid test and an Expedition
  33 dodge/parry test and passed on both) and make it harder with close calls: the balance pass in "Combat in one
  paragraph". **Dying only lasts for that fight** (back up at 1 HP after); the Death waiting room idea is scrapped
  because lasting deaths would break dialogue.
- **Summit Dulbers with Mattias helping stays easy on purpose (Ebain 11/26: "it's funny").** Don't rebalance it.
- **Strategy direction (Ebain 11/26, built the same day, see "Combat in one paragraph"):** setup-and-payoff combos between all three (one fighter's status
  powers up another's move), a **break bar** for bosses (break it = stunned window + extra damage), **enemy
  weaknesses/resistances that the game tells you** (shown on the enemy), **enemy intents only through Xylo's
  Neuralink** (not always on), **Skorn stays pure dice chaos** (no rerolls or HP scaling), **no meter choices** (no
  EX specials, meter is for ults/team-ups), and **victory grades are back with rewards** for good play (Ebain's call
  over Asar's 11/25 removal). Plus a replayable combat tutorial.

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
**Deloye is pronounced da-loy** (spell it "Duh-loy" for songs and voice generators). **Dulbmeethus** → "Dulb-mee-thus", **Metocy** → "Meh-toe-see", and "dough" (as in "Y'all could hear me dough?") for the TTS/song tools (Ebain 11/25).
- **Jit:** kid/young guy. "Wizard jit?" is Skorn's greeting to Mattias in the camp and the Pass (Ebain 11/25).
- **Mogging / mogged:** out-looking someone. Lykor is "the Mogging Elf." **Mog** is his combat move (camera pushes onto his jawline).
- **On some type shi:** Lykor's buff move, also a chant in the title music. Ebain also names achievements this way ("On Some Sneaky Shi", "On some metocy shi", "On Some Ladle Shi"); spell it **shi**, not chi (Ebain 11/25).
- **Crunk** (3 beezy), **Slopbowl Consumer** (3 Chipotle Bowls), **"U had said drip?"** (buy the Jordan 9's): Ebain's achievement names (11/25).
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
- **T S:** "this shit" (Lykor: "T S is massive like the low taper fade meme"). **Folk:** what they call each other.
  **On dulbmeethus:** swearing on it (like "on god"). **Peep:** check out ("I gotta peep T S"). **Shlooks folk.**: Lykor's
  answer when Mattias helps (Ebain 11/25, meaning not spelled out). **"in de bih"**: Skorn ("you ain't gonna make it sad
  in de bih"). **Mud:** what Deloye calls you ("Here you go, mud."; also "Dat bih fire mud"). **Pull up:** come over.
  **Got da plug:** has a dealer coming. **Faded:** high (the buff). (All from Ebain's Deloye library script, 11/25.)
- **John's orb:** a lore term from the title music. **John and John's orb** make Deloye write forever (Ebain 11/25). What John is: not given yet, ask Ebain before saying more.

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
- `RUINS_CHOICE=0..4` (cave tour: solves the puzzle with scripted pushes, then picks the rat choice; run `cave.tscn`, or
  `ruins.tscn` with `SHOTS_CHAIN=1` to fall in from the ruins first) · the Mart tour ends with Charis's house
- `FIGHT=goblins|dulbers|giant|goblin_patrol|bouncer` (+ `LEVEL=2`, `ALLIES=1`, `AUTO_LOSE=1`, `MENUS=1`) — runs one fight
- `LOOK="x,z,yaw;..."` (camp) — close-up screenshots of spots with the fire lit
- `--views` instead of `--shots` walks the trio in 4 directions
- `DEV_DIALOGUE=skip|choices|only:<speaker>` (+ `DEV_PICK=1..5`) — run a tour in a dev dialogue mode (see Dev mode below)
- `DEV_MENU=1` — screenshots of the Alt+F1 dev menu + dialogue viewer
- **Fast logic-only check:** add `--headless` (no xvfb, no rendering flags). Tours run in about a minute, print
  `SHOT <name>` instead of saving pictures, and any script error shows up. Use this to check that a flow still
  finishes, and the xvfb run when you need to see it.
- **Explorer bot (Asar 11/23):** plays the game on its own at random: wanders, presses E on things, reads every line,
  picks random choices, mashes through minigames, auto-plays fights, area after area (it can finish Chapter 1 and start
  over). Reports script errors, softlocks, stuck dialogue, falling through the floor, endless fights and freezes, each
  with a screenshot + what it did just before. `godot --headless --path godot --audio-driver Dummy --script
  res://tools/explorer_bot.gd` (fast, no pictures) or the xvfb command with `--script res://tools/explorer_bot.gd` for
  screenshots. Env: `BOT_MINUTES`, `BOT_SEED` (same seed = same picks), `BOT_START=res://summit.tscn`, `BOT_SPEED=10`
  (headless only; physics ticks scale with it so nothing walks through walls; 10x really runs ~8–10x and covers camp →
  summit in ~3.5 min; 25x starts glitching the fight camera, so 10 is the sweet spot; the report shows the effective speed), `BOT_DIR` (report.md + shots/). Code: `tools/explorer_bot.gd` (launcher) + `explorer_bot_player.gd`.
  It overwrites user:// saves/progress, so not on your own PC. **On GitHub** it runs by itself after every push to main
  (`.github/workflows/explorer-bot.yml`, 20 min **at 10x headless** since 11/24 = ~3 hours of play, no screenshots; red =
  it found something; report on the run page + `explorer-bot-report` download), or by hand: Actions → "Explorer bot" →
  Run workflow (minutes / seed / start area / **speed**: 1 = the old normal-speed run with screenshots).
Tours are slow in the sandbox (5–9 min); run them one at a time or they time out. `--check-only` always reports
"Identifier not found: Game" — that's a false positive (the autoload). The sandbox has no TTS and no Forward+, so
voices are silent and the screenshots look a bit flatter than the real game.

### Dialogue map (Asar 11/24)
A page with **every line, choice and outcome** in the game, drawn as a branching script (choices drop off a gold bracket
into their outcomes), each line marked **mp3 / no mp3** and Ebain / Asar / draft, with a shared **approve tick** per line
(approved lines fold away; the line right before something still unapproved stays as dimmed context; "keep showing"
pins one). Filters: missing an mp3, not approved, drafts, speaker, search; "Copy lines missing an mp3" gives a recording list.
Live at https://claude.ai/artifact/TVQYniLFUFbsRBkhpb62aV (artifact slug `d684f157-0ae8-4e3a-b0d7-31aec6733b82`, owned
by Asar; approvals are in its database, collection `approvals`, keyed by speaker + text, so rewording a line resets it).
Every line with a recording has a ▶ play button (the recordings sit beside the page as `v/<hash>.<ext>`).
**After you change any dialogue or add recordings:** `GODOT=<godot> tools/dialogue_map/build.sh`, then republish
`build/dialogue_map/index.html` + `dialogue.json` + any `v/` file the artifact's list_files doesn't have yet to that slug
(publish_files, mode patch, max 256 files per call; copy the folder to a short path like /home/claude/m first). Asar's Claude does this; it
also rebuilds nightly. Ebain's Claude can do it only if Asar shares the page with Ebain as an Editor.
New dialogue script or level file → add it to `SCENES` in `tools/dialogue_map/build.py` (and `ScriptScan.SCRIPTS`).

### Dev mode (Alt+F1 in game)
**Alt+F1** opens the developer menu (plain F1 does nothing since 11/24: players were finding it, and mashing in it broke runs) (`scripts/dev_mode.gd`, class **DevMode**). It lets you:
- pick a **dialogue mode**: normal · choices (only choice menus) · skip (no dialogue at all; choices are auto-picked
  with option #`Skip-all pick`) · `only:skorn|lykor|xylo|goblins|dulbers|mattias_giant|narrator` (only that speaker's lines)
- open the **dialogue viewer**: read every line of a scene's script without playing it, filtered by speaker
  (A/D switch script, W/S scroll, Q back)
- **jump to a scene**, set **fights auto-win**, force **Dulbmeethus every fight** (his strike + cutscene on the first enemy turn; turn auto-win off or the fight is skipped), and use cheats (+100 XP, +items, all gear, story flags)
It works by routing `run_dialogue()` in level.gd through `DevMode.run()`, so dialogue.gd is untouched. Settings live
in `Game.dev_dialogue`, `Game.dev_pick`, `Game.dev_autowin` and `Game.dev_dulbmeethus` (passed into the fight as the `dulbmeethus` option). Nested dialogue (village rooms) uses `lv.run_nested(steps)`.

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
| `scripts/video_cutscene.gd` | **VideoCutscene.play(parent, "res://assets/video/x.ogv", end_color)**: any full-screen video cutscene (skip with E/Esc/Enter/click, music ducks, returns the cover in `end_color`; nothing headless or under NO_CUTSCENE). Ebain's Gemini videos: `map_burn` (camp `_burn_map`, cropped so Lykor isn't in it: he doesn't know yet), `pipe_ride` (village flush → library; cut at 8.95 s with a white flash before a glitch at the end), `pipe_exit` ("Climb back up the pipe" → village), `neuralink` (library `_gift`, before Xylo gets it). Tours skip them (`shots_mode`). Convert mp4 first: `ffmpeg -i in.mp4 -c:v libtheora -q:v 8 -c:a libvorbis -q:a 5 out.ogv` |
| `scripts/area_music.gd` | **AreaMusic**: an area's free-roam music. Add it as a child node in the area's `.tscn` and set `track` (+ `stages`, volumes). It watches the parent Level, so the area script doesn't change: plays while `stage` is in `stages`, ducks under dialogue, goes quiet in building interiors (`vb.room`) and fights (a BattleView child), fades out on `Game.changing`. Keeps playing silently while out, so the song continues instead of restarting. `gain_db` lets the area turn it down (the village mutes it when the goblin band is gone). Village: Ebain's **"The Mogging Elf"** (`assets/music/the_mogging_elf.ogg`) in free roam |
| `scripts/achievements.gd` | **Achievements**: popup top-right + title-screen list, saved forever in `user://achievements.cfg`. Add one = one line in `LIST` with `when`: `progress:<id>` (any progress_data id), `flag:<name>` (any story flag), or `manual` (call `Game.achieve("id")`). also `all:<id>,<id>` (every progress id found: Trail Mix, Deloye Lore Specialist), `count:<key>:<n>` (a counter, bump it with `Game.ach.bump("beer")`, saved across playthroughs: Crunk, Slopbowl Consumer, Tactical retreat), `pct:100` (every progress item found). `hidden` = shows ??? until unlocked. Lives on Game (`Game.ach`) so it survives scene changes. **Ebain's list (11/25, 27 total):** names are his, descriptions DRAFT. Hooks outside this file: `battle_view.gd` (6-7, Dulbmeethus' lightning, fled, lost fight, eating/drinking in a fight), `inventory_ui.gd` (eating/drinking from Tab), `shop_ui.gd` (sets flag `bought_<item id>` on every purchase), `mart.gd` (`dulbersMet`), `pass.gd` (`giantWoke`). Hidden: Good boy, Neuralinked, Deloye Lore Specialist, 6-7!!!!!, Yall could hear me doe?, Geeking off that midtocy, Slayer of Metocin Mattias, On some metocy shi, 100%. Test: `godot --headless --path godot res://tools/test_achievements.tscn` (clears the saved achievements first) |
| `scripts/menu_ui.gd` | **MenuUI**: every menu (title, pause, settings, save/load, yes/no). Keyboard, controller and mouse. `MenuUI.open(parent, title, rows, opts)`, `MenuUI.confirm()`, `open_settings()` (section list → `_settings_audio/display/dialogue/gameplay/controls` pages), `open_slots()`. Rows: `text`, `value` (shown right, with ‹ › if the row has `change`; `"arrows": false` hides them), `icon` (play/pause/lock/note), `side` (a small button, L / Y). Looks from UITheme, restyles on `Game.ui_changed` |
| `scripts/ui_theme.gd` | **UITheme**: the menu look. 3 themes (`NAMES`, colors in `T`): Gold & Night, Parchment, Wizard Arcane. `c(key)`, `panel()` (OrnateBox: chamfered, double frame, corner diamonds, top gem), `row(on)`, `lbl()`, `fs(px)` (× text size), `head_font()`/`row_font()` (Cinzel), `button()`, `bounce()/squash()/pop_in()`, `play("move/pick/back/open/page")` (synth sounds; "move" is Ebain's `ui_switch.ogg`, see `FILES`), drawn `Icon` + `Divider` |
| `scripts/library_ui.gd` + `lyrics.gd` | **LibraryUI** (Title → Library, and pause menu → Library in game: area music goes silent while it's open, group `library_open`): a hub (`hub`) → **Soundtrack** (`_soundtrack()`), **Voice Lines**, **Scrapbook**. Soundtrack: `SONGS`, play/pause/seek, lyrics page (always parchment). Songs unlock when heard (`mark_heard()`, called by AreaMusic once audible; title song always unlocked), saved in `user://library.cfg` across playthroughs. **Lyrics** go in `lyrics.gd` `TEXT[id]` (Ebain's, verbatim). **Save** button (unlocked songs only, K / controller X) copies the .ogg to Downloads/Trio Adventures Soundtrack and opens the folder (browser build: normal download); raw .ogg files ship because export_presets.cfg has `include_filter="assets/music/*.ogg"`. New song = add to SONGS + Lyrics.TEXT |
| `scripts/voice_lines_ui.gd` | **VoiceLinesUI** (Library → Voice Lines): every recorded line, a tab per character (`ScriptScan.CATS`), search box (all words must match text or speaker), Enter/click plays. Plays on Master at Voice volume |
| `scripts/scrapbook_ui.gd` | **ScrapbookUI** (Library → Scrapbook, always parchment): a page per story outcome (`ProgressData.ITEMS` with story = true), grouped by `SECTIONS`. Found: what you did, the choice text, the line said after it (+ Play). Not found: "? ? ?" + `HINTS` (# DRAFT, Ebain rewrites) |
| `godot/tools/dialogue_map_dump.gd` + `tools/dialogue_map/` | **Dialogue map** builder (see "Dialogue map"): the dump runs in Godot (every script constant + the mp3 the game would play), `build.py` adds tags, where each conversation plays and the level-code lines, `index.html` is the page |
| `scripts/script_scan.gd` | **ScriptScan**: reads the dialogue scripts at runtime (`SCRIPTS`). `voice_lines()` = every recorded line with its speaker + file (recordings no script uses still show, by folder); `outcome(id)` = the choice option + first line after it. New dialogue script → add it to `SCRIPTS` |
| `scripts/keybinds.gd` | **Keybinds** (Settings → Controls): rebind each action's main keyboard key (swaps on clash, Space/Enter always work for interact). Saved in settings.cfg `[keys]`, applied by Game before any level's `_setup_input()`. `ACTIONS` defaults must match level.gd |
| `scripts/game.gd` | **Game** autoload: story `flags`, per-character `bags`, XP/level, gear, HP between fights (`hurt`, `hp()`, `heal()`), `quests`; `goto(scene)` (shows a loading card with a joke tip); **settings** (saved in `user://settings.cfg`; F11/Alt+Enter fullscreen); **saves** (`user://saves/<auto/1/2/3>.sav`: `save_game`, `load_game`, `latest_slot`, `new_game`) |
| `scripts/level.gd` | **Level** base class every area extends: environment (night/day/lava), ground shader, `card()`, `backdrop()`, party + NPCs (`spawn_npc`, `add_to_party`, `walk_to`, `hop`, `knock`), camera (`cam_locked` = stage-set area: arrow keys/right-drag turn only `LOCKED_TURN` ~30° each way; `zoom`, `cam_height`, `cam_look_h`, `focus_override`), interactions, `run_dialogue()`, HUD (`objective`, `show_toast`, `char_label`), `fight()`, roaming enemies (`spawn_roamers`), the defeat penalty, Esc pause menu, Tab inventory (`open_party_menu()` → InventoryUI), `item_icon(id)`, test helpers. Hooks: `_configure`, `_build_level`, `_after_build`, `_begin`, `_level_interactables`, `_on_action`, `_level_process`, `_shot_tour` |
| `scripts/unit.gd` | **Unit**: a character (CharacterBody3D + billboard Sprite3D), views, `set_pose`, `restore_views`; the trio also get a `body3d` (Char3D) for walking |
| `scripts/char3d.gd` | **Char3D**: the trio's rigged 3D bodies (Meshy GLBs in `assets/characters3d/`), idle/walk/run only |
| `scripts/dialogue.gd` | **Dialogue** box + TTS. Steps: `{who, mood, line, thought, name?, portrait?}`, `{do: "action"}` → `_on_action`, `{choice: [{text, if?, steps}]}`, `{if: flag, steps}`, `{if_not: flag, steps}`. `CHARS` = speakers, voices, pronunciation fixes. Voices: recordings play instantly; the robot TTS is never interrupted (Windows deadlock), so it reads one sentence at a time from `_tts_queue` and the newest line waits for the current sentence (skipping never mutes the next line). Test: `res://tools/test_skip_voice.tscn` |
| `scripts/crash_reporter.gd` | **CrashReporter** (started by Game): freeze watchdog thread (12 s without a frame), crash/force-close detection on next launch (session marker), `OS.add_logger` catches every error. Writes Markdown reports to `Crash Reports/` next to the exe (user:// in the editor). `CrashReporter.note("...")` adds a breadcrumb. Repo folder `Crash Reports/` collects them |
| `scripts/inventory_ui.gd` | **InventoryUI** (Tab): Deloye Lore parchment window over the blurred game. Fighter + 7 gear slots, **that fighter's own bag** (right-click → View / Give to another character) (`_bag_items()`: Beezy/Bowl, unequipped gear, key items), gold, quests page (J). Q = next fighter. Own grid input (MenuUI is list-only) but it joins `MenuUI.stack` |
| `scripts/minimap.gd` | top-left minimap (simple shapes, colored dots, fog, turns with the camera; shared draw helpers) |
| `scripts/map_ui.gd` | M: big map, Area tab (whole area + fog) and World tab (Camp → Village → Mart → Pass, fog on unvisited). `SIDE` = side paths drawn as a dotted branch, hidden until visited (Old Ruins & Rat Cave off the Mart) |
| `scripts/job_board_ui.gd` | the village Job Board screen (pinned notes, read up close, Take job) |
| `scripts/voice_index.gd` | **VoiceIndex**: generated by `tools/import_voices.py` (studio export → OGG). Line key → file |
| `scripts/voice_lines.gd` | **VoiceLines**: line text → recorded mp3 in `assets/voices/`. `dialogue.gd` plays a recording when a line has one (matched ignoring case/punctuation), otherwise TTS. Still-to-record list: `VOICE_LINES.md`. Its own `LINES` holds Asar's narrator, Lykor and Xylo recordings (`assets/voices/narrator/`, `lykor/`, `xylo/`; only recorded lines exist for those three, see VOICE_LINES.md) |
| `scripts/camp.gd` + `camp_script.gd` | Scene 1 (`main.tscn`) |
| `scripts/trail.gd` + `trail_script.gd` | Scene 1.5 (`trail.tscn`): forest trail z +58 (camp end) → −58 (village end), creek + bridge at z 0, troll hut, loot spots (`LOOT`), `_apply_state()` rebuilds troll/hut/loot from flags |
| `scripts/shop_ui.gd` | **ShopUI**: Haggle's Stall (village, north side of the east road to the Metocy Mart). `STOCK` = [id, "item"/"gear", price]; buys go to the active fighter. Other shops pass `open_shop(lv, { stock, title, broke, discount })` (Scrounge in the cave). "item" ids can be heal items or BOOSTS |
| `scripts/ruins.gd` + `ruins_script.gd` | Side path (`ruins.tscn`): the Old Ruins, loot (`LOOT`), the trap chest (`_trap`), the hole, the tunnel to the colony. `ruins_script.gd` holds ALL the side path's lines (ruins, cave, puzzle, colony, Charis), every one # DRAFT |
| `scripts/cave.gd` | Side path (`cave.tscn`): the Rat Cave. Own `light_at()` (dark + torches + leader light). Puzzle: `PZ`/`CELL` grid, `PILLARS`, `PLATES`, `B_START`, `slide_target()`/`push()`, `_apply_puzzle_state()` rebuilds it from flags. Colony: `_build_colony`, `_colony_scene` (RS.COLONY), `_open_shop()` (Scrounge's stock). Walls on the camera side are low lips with full-height collision |
| `scripts/village.gd` + `village_script.gd` | Scene 2 story (`village.tscn`); `_chug_game(rival, speed)` |
| `scripts/village_buildings.gd` + `village_rooms_script.gd` | the explorable village: huts, doors, rooms at x = 400/440/480/520, NPCs, 5 quests |
| `scripts/mart.gd` + `mart_script.gd` | Scene 3 (`mart.tscn`): modelled shop exterior (`_shop_exterior`, street houses) + stocked interior at x = 300 (`_shop_interior`); the trip recolors `room_lights`/`glow_jars` |
| `scripts/lost_pages.gd` | **LostPages** (static): the 5 Lost Deloye Lore Pages. `SPOTS` (area key → position), `SNIPPETS` (# DRAFT), `spawn/interactable/process/pickup` (Level calls them for every area; the "lost_page" action is routed in `Level.do_action`), `count()/has_all()`, `quest_text()` (Tab → Quests) |
| `scripts/deloye_library.gd` + `deloye_script.gd` + `deloye_library.tscn` | The secret library: rotunda at the origin (R 11.5), the rest built south of it (`ROOMS` rects, `_build_rooms`, walls with `_wall(p0, p1, h, face, both)`: tall = north/outer walls, `LOW_H` bookcases = any east-west wall with floor north of it, `LIP_H` = the rooms' south edge; fixed camera facing north). Overdue volumes `BOOKS` + `_lectern`, rune curtain `_build_gate`/`_gate_open`, `_rotunda_moment`. Test: `deloye_library.tscn --shots` walks every room (`ROUTE`, prints `LIB ROUTE ALL OK`), takes the books, opens the gate, meets Deloye. Deloye = a billboard that cycles front/side/back(/mirrored side) as `spin` turns (`_set_view`), eases to front while talking (`spin_speed` 0). Book shelves are QuadMeshes with the drawn `textures/book_spines` (2 m tile). Music: `SONG` (Ebain's `assets/music/deloye_lore.ogg`) becomes an AreaMusic automatically once the file exists, else the synthesized `library_hum`. Test: `deloye_library.tscn --shots` (+`DELOYE_EXIT=1`), or `VILLAGE_TOUR=flush` on village.tscn for the whole chain |
| `scripts/progress_data.gd` | **ProgressData**: what counts toward "Outcomes x/31 · N% complete" (story outcomes 2 points each, quests 5, Chapter 1 6, Three Seals 3, Charis 3, trail loot 1 = 100) (title screen, end card). `Game.unlock(id)` / `outcomes_found()` / `completion_pct()`; saved in `user://progress.cfg` across playthroughs. `ProgressData.pick_outcome(id)` (called by dialogue.gd + dev mode when a choice with `"outcome"` is picked) also sets the **per-run** string flag `way_<scene>` (`village_skorn_king` → `way_village = "skorn_king"`), since outcomes themselves are saved across playthroughs |
| `scripts/summit.gd` + `summit_script.gd` | Scene 5 (`summit.tscn`): the climb (z +62 → plaza at -52), tower (`_lair_exterior`), the hall built off to the side at `INT` (x 400, `_hall`: round wall open toward the camera, pillars, dais + throne, statues, chandeliers, alchemy + study corners, floating candles/books/orb via `floaters`). Uses Ebain's wizard-lair Poly Haven pack. **Finale:** `_begin` (arrival) → `_halfway` → `_ambush` → `_finale` → `_hard_end` / `_goblin_party` (set at `PARTY_POS`, x -400) → `_credits()` (every ending). Script steps with a `"dyn"` key get their line from `_dyn_line()` (tables `DYN_*` in summit_script: first matching flag wins). Trip look = `_take_metocy` + `TRIP_SHADER`. Test: `SUMMIT_TOUR=finale SUMMIT_FLAGS=… SUMMIT_PICKS=… [AUTOWIN=1]` (see the comment above `_finale_tour`; waits for the credits), `SUMMIT_TOUR=credits` (just the roll, made-up run) |
| `scripts/credits.gd` | **Credits**: the end credits roll (see section 5 "End credits"). `ROLL` = the scrolling text as data, `RUN_SCENES` / `ENDING_NAMES` for the run recap. CanvasLayer 96. Tours and headless runs (explorer bot) skip through it in a few frames |
| `scripts/pass_musical.gd` | **ChudMusical**: the Diddy Chud music video. Everything runs off the song's clock (`t` = playback position, capped to real time): `_build_shots()` = camera shots (a new shot = a cut; `_cuts()` makes the fast drop cuts from `_drop_set()` on beat multiples), `_build_events()` = timed hits (drops, bass-cut returns), `_on_beat()` = per-section beat stuff (lava pulse, shake, geysers, lava bombs). `BEATS` = librosa beat times of the song; re-run the beat track if the song is re-rendered. `build_volcanoes()` makes the 3 background volcanoes for the whole Pass. The giant is a flat Sprite3D: keep cameras in front of him (z > -10). Test: `CHUD_SHOTS="27.8,88,125"` on a Pass `--shots` run under xvfb (screenshots at those song times, then quits) |
| `scripts/pass.gd` + `pass_script.gd` | Scene 4 (`pass.tscn`): rock-face canyon + animated lava (`_canyon`, `_lava`), giant lying across the path (`giant_lying`, Asar's `giant_sleep.png`; `_giant_wakes` crossfades sleep → sit → standing, no black cut); Snore Sneak + Lore Session minigames |
| `scripts/dev_mode.gd` | **DevMode**: the Alt+F1 developer menu, dialogue modes, line viewer (see "Dev mode") |
| `scripts/combat/combat_data.gd` | all combat numbers: party moves, fights, gear, statuses, talk options, banter. Rat cave: fights `rats` (roaming) + `rat_colony` (boss, `lvl` 3), ai `rat`/`rat_king` (battle.gd), rat gear (thimble_helm, toothpick_spear, bottlecap_mail, lucky_crumb, bottlecap_crown, corncob_scepter), boost `cave_cheese`, talk `cheese_bribe` |
| `scripts/combat/battle.gd` | pure combat rules (turn timeline, meters, ultimates, team-ups, statuses, boss AI, talk/flee) |
| `scripts/combat/battle_view.gd` | in-world fight presentation (line-up, menus, timed ring, dice, events, results, hoverable status words, Lykor's Mog close-up `_mog_cam`) |
| `scripts/models.gd` | **Models**: `place(parent, id, pos, rot_y, scale, collide, recolor)`, `mat(texture, tile, tint)` (triplanar PBR for any box/cylinder), `block`, `cylinder`, `patch` (soft-edged ground decal), `tint` |
| `scripts/fx.gd`, `util.gd`, `ambience.gd` | particles (flames, poof), mesh/material/sound helpers, camp fire loop + crickets + Scene 1 night bed |
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
- **UI looks everywhere** (UI overhaul part 2): the dialogue box, choices, HUD plates (objective, toasts, leader
  portrait), minimap frame and combat menus/cards/results all use UITheme and restyle on `Game.ui_changed`. Fights
  follow the menu theme too, Parchment included (Ebain 11/24): text inside fight panels goes through
  `battle_view._pl()`/`_ink()` (dark ink, no outline on Parchment). Text size also grows the dialogue box.
  Mouse hover only moves a highlight on real mouse movement (`UITheme.hover_moved` / `key_nav`), see TIPS.
- **Settings** (title + Esc menu), split into pages: **Audio** (master, music, sound effects, voice volume, voices,
  area music loop/once) · **Display & UI** (menu theme, UI size = root `content_scale_factor` 80–130%, text size 85–130%,
  menu animations Bouncy/Calm, window, VSync, graphics) · **Dialogue** (text speed, buffer, go back, dialogue speed) ·
  **Gameplay** (camera speed, difficulty, timed hits, battle speed Normal/Fast/Very fast = `Game.BATTLE_SPEED`
  multiplier on `BattleView.speed`; timed-hit rings unchanged) · **Controls** (keyboard rebinding, reset).
- **Audio buses** (made in `Game._make_buses()`, no bus layout file): `Music` and `SFX` → Master. Any new player left on
  Master is moved to SFX automatically (`Game._route_audio`), except dialogue's `_vo`. Music players must set
  `bus = &"Music"` before `add_child` (title.gd, area_music.gd, library_ui.gd do).
- **Ebain's SFX pack (11/26)** in `assets/sounds/` (from his `Downloads\sfx`; converted with trimmed silence, one-shots
  peak -1 dB, loops crossfaded so they repeat seamlessly). Helpers in `level.gd`: `play_sound(id)` (one-shot or loop),
  `play_sound_at(id, pos)` (one-shot from a spot in the world), `amb_loop(id, db, pos?)` (looping bed, 3D if given a pos).
  - **Footsteps:** `step_<grass|wood|hall>_1..8.ogg` cut from his recordings, one per footfall (`Level._on_step`, random
    pick + pitch). Each area says its floor with `floor_kind` or `floor_at(pos)`: grass outside, **wood** in village
    buildings, the Mart shop + Charis's house and on the trail bridge, **hall** (stone) in the cave, Mattias's tower and
    the Deloye library.
  - **Ambience:** `amb_campfire` (camp fire, replaces the synth crackle) + `amb_night` (Scene 1 at night, his "background
    of scene 1"), `amb_river` (trail creek, 3D), `amb_wind` (Giant's Pass, summit climb, light in the ruins), `amb_cave`
    (rat cave), `amb_aura` (hum at each Lost Page and the OG Metocy case), `amb_engine` (rises as the outhouse spins).
  - **Moments:** church bell at the coronation (lower when Skorn takes the crown) and when Mattias is beaten; goblin crowd
    cheer at the coronation, dethroning and the summit goblin party; heartbeat before the Mattias fight and in any fight
    while someone on our side is at 25% HP or less; tiger roar for the angry giant waking (slowed) and at the start of
    every rat fight (the joke); goblin evil laugh before goblin fights, playful laughs from village goblins every
    ~30 s; burp after the chug-off; fart in the outhouse; cough when the map burns at camp; boing for the troll squeezing
    into his hut, a failed run and any dice that land on 1; record scratch (`sfx_vinyl_awkward`) when Talk fails;
    record rewind when you get away; rat squeaks when rats get hit; real dice roll; cloth rustle opening the bag and
    equipping; pen scratch on a new objective and when the Scrapbook opens; `ui_switch` for menu moves (UITheme "move")
    and switching characters.
  - **Pack 2 (11/26):** `sfx_page_flip` is UITheme "page" (book pages, menus that flip), `sfx_book_close` when a lore
    book closes, `sfx_pages_rewind` (UITheme "rewind") on dialogue Backspace, `sfx_item_pickup` whenever anything lands
    in a bag (`Game.item_got` from `add_item`/`give_gear`; a burst only plays once), `sfx_level_up` on any level up
    (`Game.leveled_up` from `add_xp`), `sfx_giant_steps` when the Giant stands and walks off (and pitched up, quieter,
    for the Bridge Troll walking to his hut).
  - **Deloye library:** a magic hum on each joint piece (stops when you take it), lighter flick when Deloye sparks it
    (A) and at the start of puff puff pass (B, plus a cough), engine hum booting the Neuralink.
- **Controller:** left stick/d-pad move, right stick or LB/RB camera, A talk/confirm, B run (hold) / back in menus,
  Y switch leader, Back = party, Start = menu. Number keys 1–9 pick dialogue choices.
- **Dialogue controls** (`dialogue.gd`, Settings → Dialogue buffer / Go back / Speed mode): **E / Space / click** finishes the typing, and the next press has to wait out the **buffer** (Off/Short 0.2/Normal 0.4/Long 0.8 s) so lines can't be mashed through. **Backspace** replays the previous line (and its voice) but only if the step before it is also a plain line: it can't go back over an action (`do`) or a choice. **Dialogue speed** (Ebain 11/24: a slider at the bottom-left of the dialogue box, 0.5x–3x in 0.25 steps, no Yes/No; also Settings → Dialogue) speeds up **voices and text typing** together; the buffer is divided by it. Recorded lines play at `pitch_scale` = speed on a runtime `VoiceFast` bus whose pitch-shift is 1/speed, so they keep their pitch; the robot voice gets `rate` × speed. `Game.dlg_speed` is a float now (old ON/OFF saves load as 1.5 / 1.0). Settings are saved in `Game.dlg_buffer/dlg_back/dlg_speed`. Keyboard/mouse only: no controller button for back.

### Leveling, boss scaling, gear (Ebain 11/24)
- **Optional fights give more XP** (patrol 50, bar fight 70, troll 85) so you level before Diddy Chud. `LEVELS` curve unchanged.
- **Bosses keep up:** each boss fight has `"lvl"` (expected level: Dulbers 2, giant 3, ambush 4, Mattias 5). Every level
  you're above it gives the boss +12% HP and +6% damage, up to 4 levels (`CombatD.BOSS_SCALE`, `battle.gd boss_dmg`).
  The sim shows out-leveled bosses win/lose about the same as on-level ones.
- **Boss buffs** (`battle.gd enemy_plan`, texts # DRAFT): every boss once goes HYPED at 30% HP ("refuses to lose"), and
  every 5th turn (Mattias 7th) gets **BRACED** (new status: takes 30% less damage for 2 turns).
- **Haggle's top shelf** (`shop_ui.gd STOCK`, gear in `CombatD.GEAR`, names/descs # DRAFT): Crispy Jordan 9s 220,
  Haggle's Gold Chain 280, Goblin King's Helm 320, Designer Spoon Mail 400, The Golden Ladle 650 (the first weapon).
  No item pictures yet (placeholder crate). The shop list scrolls now.
- **Deloye Lore Neuralink** (trinket `neuralink`, the secret library's gift): `foresee` = at the start of each party turn
  battle.gd plans the next enemy's move early and shows "NEURALINK: Goblin is about to use Spoon Bonk on Xylo."
  (`_foresee()`; `enemy_plan()` hands that exact plan back unless its target died or a phase change cut in; a skipped
  enemy turn drops it), `dodge` 0.15 (a dodged hit = no damage), `start` 20. `dodge`/`foresee` aren't summed by
  `Game.gear_stats()` (game.gd was claimed), so `battle.gd _gear_perks()` reads them from the equipped gear.

### Combat in one paragraph
Fights happen right where you're standing: `await fight("giant", { enemies = [unit], mods = { enraged = true } })`.
FFX-style turn timeline, timed hits/blocks on a shrinking ring (Auto option: T or the Esc menu), meters → ultimates
(FULL CRASH OUT, MOG SUPREME, CHUD OUT), team-ups, statuses both ways, boss phases, rare chaos events (+ **Dulbmeethus' lightning**, 6.7% of fights (`BOLT_CHANCE` in battle.gd): "Y'all could hear me doe?" on the first enemy
turn, then **Ebain's 10 s cutscene** (`assets/video/dulbmeethus_strike.ogv`, full-screen, music ducked, E/Esc skips after 0.6 s, `battle_view.gd _strike_cutscene()`; skipped in headless runs / env `NO_CUTSCENE`) that ends on a white-out which fades into a bolt on every enemy (Ebain's lightning art in `assets/vfx/`: additive bolt + impact burst + scorch on the ground, `battle_view.gd _bolt_art()`, plain `_bolt()` if the pictures are missing) with Ebain's attack clip (`assets/sounds/dulbmeethus_attack.ogg`), regular ones drop, bosses lose 40%; `battle.gd _dulbmeethus_bolt`, `BOLT=1` forces it), banter, XP +
levels (Level 3 teaches new moves), 7 gear slots per fighter (helmet/armor/shoes/shield/weapon/2 trinkets, summed by `Game.gear_stats()`), armor (**a % cut per hit since 11/26**: 3% per point, max 30%, `D.ARMOR_PCT/ARMOR_CAP`; gear damage bonuses stack with falloff, `D.POWER_FALLOFF`), Normal difficulty ×1.1 enemy HP / ×1.15 damage (11/26), roaming fights scale harder with a full party,
**Balance pass (Ebain 11/26)**, numbers in `CombatD.BALANCE` / `SALE` / `STAMPEDE`: **Downed, not out** (0 HP = Downed;
on their turn they roll a d20 death save with the dice popup, 10+ passes: 3 passes = up at 1 HP, nat 20 = up at half HP
and they act, nat 1 = two fails, 3 fails = **dead for the rest of that fight**; AoE hits on a Downed fighter = a failed
save; Items/heals revive the Downed but not the dead; new menu option **Help Up** spends your turn to bring one back at
20% HP; `battle.gd downed()`, `_death_save`, `help_up`; after the fight everyone is back at 1 HP as before, **no
lasting death and no Death area: Ebain scrapped it, it would break dialogue**), **boss tempo** (phase-2 bosses get a
free second action at 40% strength, `enemy_actions()` + `begin_action()`; the view and the sim loop on it; Mattias has
`no_tempo`; the Giant's old phase-2 speed-up is gone), **Dulbers' shapeshifts are free** (`"free": true` intents),
**big telegraphed hits** (`_telegraph()`: wind up on his 3rd turn then every 5th/4th, lands on his NEXT turn, never on
the bonus action; Defend, a timed block or a stun/charm during the windup answers it: Dulbers' **CLEARANCE SALE →
EVERYTHING MUST GO**, the Rat King's **stampede**, on top of the Giant's SIT), **adds** (a fight's `adds` list joins at
the boss's phase 2, `_summon()`: two goblins in Metocy Mart vests at the Mart Dulbers fight, ai `employee`; they leave
when the boss drops; `battle_view._add_enemy()` spawns them), **every boss scales with your gear** (milder than
Mattias: `boss_drip_hp/dmg`), **comeback power** (under 25% HP the meter fills 2×), **no emergency Beezy in boss
fights**. Dulbers (Mart) got hp 300 → 240, Price Gouge 34 → 30, Bootleg Slap 36 → 30, NO REFUNDS 21 → 18 to make room.
**Strategy pass (Ebain 11/26)**: **setups & payoffs** (Hair Flip → DISTRACTED: next hit from anyone +50%;
Diddy Slap slaps twice on Mogged/Distracted/Charmed; Eldritch Blast adds LORE STACKS (max 3) that Deloye Lore cashes in
for +25% each + a sure Lore-pill; Dragon Breath on an already Cooked target explodes for 20; "on some type shi" HYPED is
now +25% damage + double break damage + the next team-up at half meter (`b.shi_discount`, `combo_cost()`)), **Throw
Sum Shi is a d6** (`D.THROW_TABLE`: boot hits Skorn, rock, conditioner/Down Bad, Beezy keg/Cooked, goblin/big break,
shopping cart/stun), **damage types + shown weaknesses** (`D.DTYPE` Skorn physical / Lykor aura / Xylo lore,
`D.WEAKNESS` by enemy ai, ×1.3 / ×0.7, WEAK/RESISTS chips on the enemy panel, "WEAK SPOT!" floats), **boss break bar**
(`D.BREAK`, gold bar under boss HP: full = BROKEN, loses the next turn even Locked In, cancels wind-ups, ×1.25
damage taken till then, +15 meter to everyone, each break needs ×1.5 more; `battle.gd _break()`), **victory grades are
back** (`battle.gd grade()`, `D.GRADES`: HP left 40 + timing 25 + no knockouts 15 + style 20 (team-ups, breaks,
payoffs, weak hits) → S +50% gold/+25% XP, A +25%/+10%, B +10% gold), and a **Combat Tutorial**
(`combat/combat_tutorial.gd`, 11 one-idea pages; offered before the first fight of a save via flag
`combatTutorialSeen`, replay from the Esc menu → Combat Tutorial or **H** in a fight). Bosses got more HP to make room
(Mart Dulbers 280, Giant 600, summit Dulbers 560, Rat King 520, Mattias 2700 with no weak spot). Sim (Normal, Mart
Dulbers): sloppy ~67% win, average ~94% with ~60% HP left, good ~100%.
**Polish pass (Ebain 11/26)**: **damage preview** in the target picker (`battle.gd estimate()` → `_est_text`: "~18-30
damage · WEAK SPOT · slaps TWICE · +12 break (40 to BREAK)"), **turn-order preview** (hovering a move re-draws the
turn bar with its effect on the likely target: delays, Chud Out stun, a break; changed portraits get a gold border;
`preview_with()`, `_tl_for()`), **battle log** (L or the log line: every line of the fight, `_log_lines`), **enemy
roles** (ai `shaman` heals, `shield` GUARDS a buddy for half damage, `bomber` lights a fuse that hits everyone next
turn (`D.BOMB`), `plague_rat` poisons (4/turn, never knocks out); goblin patrols, rat patrols and the rat colony use
them; role tints via the enemy's `tint`), **smarter enemies** (lean harder on the hurt; regular enemies kick a Downed
fighter 20% of the time = 2 failed saves; `D.ROLES`), **impact** (`_hitstop` on perfect/30+ hits, `_punch` camera
on breaks and nat 20s, `_squash` on boss hits, bigger gold PERFECT numbers), **roaming fights scale with level and
party size harder** (`D.ROAMING`), **Mattias is shorter** (hp 2200 / bolt 60 / rain 36, same odds), **new fight items**
at Haggle's Stall (`D.FIGHT_ITEMS`: Gas Station Energy Drink +50 meter, Mouthwash cleanse + 10, Bubble Wrap soaks 30;
need icons in assets/items/, the shop shows a placeholder), **S-rank trinkets** (first S on Mart Dulbers / Giant /
Rat Colony / summit Dulbers: `D.S_RANK_LOOT`, flag `srank_<fight>`), and a **sim move report** (`SIM_MOVES=1`: uses,
share of damage and damage per use for every move, plus breaks per fight). Then (11/26) a tune: roaming patrols ×0.8 HP / ×0.7 damage per extra
fighter (`D.ROAMING`), the shaman heals every other turn at most, the Rat Colony is tougher (King 640, guards 48/60,
stampede 38), and the first fight is kinder (the three goblins 26 → 22 HP; sim: sloppy Skorn wins 85%, was 70%).
**AAA polish (Ebain 11/26)**: **layered combat sounds** `assets/sounds/cmb_*.ogg` (mixed with numpy from CC0 packs on
OpenGameArt: Kenney RPG + Interface Sounds, rubberduck's "75 breaking/falling/hit" + "100 SFX" + "25 bangs", StarNinjas'
"10 impact/shield blocks"; each hit = sub thump + transient + body: `cmb_hit_phys_1-3` / `cmb_hit_aura_1-2` /
`cmb_hit_lore_1-2` picked by the attacker's damage type (`dmg` events carry `by`), `cmb_hit_big` on 30+, `cmb_perfect`,
`cmb_weak`, `cmb_whoosh_1-3` on every swing, `cmb_block`/`cmb_block_perfect`, `cmb_break`, `cmb_explode`, `cmb_downed`,
`cmb_revive`, `cmb_meter_full`, `cmb_grade_slam`, `cmb_ui_move/select/back` for the fight menu; `_impact()`),
**camera** (leans toward whoever acts, `_lean`/`_unlean`; shake scales with damage), **effects** (`_burst()` particles
per damage type: dust / sparkles / runes, sparks on blocks, gold shards on a break; `_crack_screen()` on BROKEN; a
gold flash on weak spots), **UI** (HP bars drain with a pale ghost bar, `_drain()` + `_bar(..., ghost)`; the meter
bar flashes when full; the turn bar slides in when the turn moves on; the grade letter slams in, `_slam_in()`). The
mixing script is in TIPS (re-run it to tweak a sound).
**Metocin Mattias** (11/26 rebalance, Asar beat him item-less; the balance pass made him ~2× easier, so now hp 2400 /
bolt 50 / rain 30, back to the old win rates): `MATTIAS_BOSS` hp 2100 / bolt 40 / rain 24 / heal 200 and
"Out-Mogs your drip" (`drip_scale` on the fight: HP and hits grow with the party's gear score, `drip_hp`/`drip_dmg`). Sim
targets (`tools/sim_combat.gd`, `SIM_GEARED=1 SIM_PRO=1`): full gear, no items: good player ~6%, near-perfect ~40%; with items ~20% / ~80%. permanent BOOSTS items (`Game.use_boost`), gold drops (`gold` per enemy; Talk = half), Run option (Talk is off in fights since 11/25: `BattleView.TALK_IN_FIGHTS`; the TALK data stays), Chief Bogdrinker joins
as a 4th fighter when the goblins are allies. Losing = "YOU GOT COOKED" + a funny penalty (story fights retry,
roaming fights wake you at the area's `checkpoint`). **Roaming patrols** you beat or talk down stay gone for the run
(flag `roamDone_<area>_<fight>_<n>`, `level.gd spawn_roamers`; Ebain 11/24: the goblin patrol came back). Running from
one steps you back along your own trail (`_retreat_from`), not 4 m sideways (that went through the cave tunnel wall).
The battle lineup squeezes/slides to fit between walls (`battle_view.gd _fit_lineup`, raycasts), so tunnel fights
don't put anyone inside the rock. Party members' "Talk to" never wins E over anything else in reach. Fights so far: `goblins`, `dulbers`, `giant`, `bouncer`, `rats` (roaming, cave), `rat_colony` (cave boss),
`goblin_patrol` (roaming, village east road), `troll`, `dulbers_ambush` (summit, regular-size Dulbers; Mattias can join
as a 4th fighter, `CombatD.PARTY["mattias"]`), `mattias` (the sucker-punch boss; every number in `CombatD.MATTIAS_BOSS`,
balance with `SIM_ONLY=mattias godot --headless --path godot --script res://tools/sim_combat.gd`). `fight(key, { lose_ends
= true })` makes a loss return "lose" instead of the penalty + retry. Enemies show **HP x/x** in the top-right panel and a
small red bar over their heads (Asar 11/23, `battle_view.gd _head_bar/_place_head_bars`, hidden during close-up cams).

### 3D trio for walking (Asar 11/24)
Skorn, Lykor and Xylo walk around as rigged 3D models (`assets/characters3d/<id>.glb`, made in Meshy from the
arms-out references in `art_refs/3d/`, Mixamo skeleton). `Char3D` plays the GLB's `Idle` / `Walking` / `Running`
clips matched to speed and turns toward movement. Look: `shaders/char_grade.gdshader` (Meshy textures re-graded darker/punchier, no fog, faint rim; tweak its uniform defaults). Standing still it holds a pose; after 15 s of free walking time (not during dialogue) the idle clip plays once every 5 s (`IDLE_AFTER`, `IDLE_GAP`). **In fights the trio stands in 3D, moves are 2D** (Asar 11/25): `Unit._sync_body`
shows the billboard during a move (meta `attacking`, battle_view `_windup` → end of `_recover`) and faces the 3D body along meta `fight_face` (set in `_intro`); `in_fight` is still set for the fight,
when a pose picture is up (`views.front != base_tex`), or when knocked over. Everything else that pokes `u.sprite`
still works: the sprite is just hidden while the 3D body shows; hops (`sprite.position.y`) and squash are mirrored.
Night areas (`level.night`) give the models a soft glow of the `light_at` colour (`Char3D.FILL`) since the billboards
are lit that way, not by real lights. The GLBs hold only those three clips (`tools/glb_keep_anims.py` strips the rest; the combat clips we made are still in Asar's Meshy account). No GLB for an id =
plain billboard as before, so NPCs are untouched. **Sitting:** give a unit meta `sitting` = local Vector3 offset and it sits
(`Char3D.set_sitting`: the GLB's `Chair_Sit_Idle_M` clip if present (Lykor and Skorn have it), else a bent-leg bone pose); remove the meta to stand.
Village throne uses it (`SIT_ON_THRONE`, `_off_throne`). Lore book model for later: `assets/props/lore_book.glb`. Dialogue lines that run long shrink to fit the box (`Dialogue._fit_text`).

### Polish (Asar 11/22)
Village names are wooden signs (`Level.wood_sign`, art goes in `assets/signs/`, list in ASSETS_NEEDED.md). Esc ends optional
conversations in free roam (`dialogue.can_leave`, `Level.free_roam()`). The chapter title shows once at New Game
(`camp._chapter_card`) instead of on the title screen. Settings → Music: Loop / Play once (`Game.music_once`). The Pass has
a rest campfire near the entrance. Interiors (village buildings, Mart shop, Charis's house, Mattias's hall) have side walls
that run on past the door toward the camera, so walking back to the exit never shows the void (Asar 11/23).

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
- **100% song:** Ebain will make a song that unlocks with the "100%" achievement (`hundred`, `pct:100`). Not made yet: when it arrives, add it to `LibraryUI.SONGS` and unlock it from `Game.ach.give()` / the achievement.
- **Music:** title = "Prophecy of Metocy" (title.gd), village free roam = "The Mogging Elf" (AreaMusic node in
  village.tscn). Ebain makes tracks in Google Flow Music. Loop points go in the track's `.import` (`loop=true`,
  `loop_offset` = where the loop restarts, so an intro plays once). Still wanted: camp, Mart (+ warped trip version),
  battle, boss, mountain/pass, victory jingle, "YOU GOT COOKED" sting. A new area track = add an AreaMusic node to
  that area's .tscn, and add it to `LibraryUI.SONGS` + `Lyrics.TEXT` so it shows in the Library.
- **Lyrics:** Ebain's lyrics for all four songs (Prophecy of Metocy, The Mogging Elf, The Hymn of Metocin Mattias, Deloye Lore) are in `scripts/lyrics.gd`, as he sent them (`# Ebain`).
- **Songs with an ending:** `<id>.ogg` is the loop-trimmed in-game track; if `<id>_full.ogg` exists (The Mogging Elf has one, with "On some type shit, you feel me? Hehe."), the Library and Settings → Music: Play once use it instead.
- **Every song is Ebain's** (Prophecy of Metocy, The Mogging Elf, The Hymn of Metocin Mattias, Deloye Lore, The Tale of Diddy Chud), made in Google Flow Music.
- **The Tale of Diddy Chud** (`assets/music/the_tale_of_diddy_chud.ogg`, 2:31, doom trap metal with a Gregorian monk choir): plays once as the Pass music video, then lives in the Library. Lyrics not in `lyrics.gd` yet (waiting on Ebain's final version).
  Older notes that call the hymn "Asar's track" are wrong: Asar wired it into the summit, Ebain made it.
- **Secret Deloye Lore library (built, see section 1):** the **Deloye Lore song is in** (`godot/assets/music/deloye_lore.ogg`,
  a phonk house track Ebain made in Google Flow Music; plays from the Reading Corner radio, unlocks in the Library, lyrics in
  `lyrics.gd`). Still wanted from Ebain: his real lines (all of
  `deloye_script.gd`, the page snippets and Xylo's barks in `lost_pages.gd` are DRAFT), a voice for Deloye, and whether
  the shaman should hint at the pages (her tent is Asar's file).
- **End credits (Ebain 11/26):** one roll for every ending, `scripts/credits.gd` (`Credits.roll(level, {ending, facts})`). Part 1 is this run: END OF CHAPTER 1 + the ending's name (`ENDING_NAMES`, DRAFT), a card per story choice picked this run (`way_<scene>` flags → ProgressData text + the line said after it, its recording plays with the music ducked), an "Also, this run" card (`summit._run_facts()`), and a stats card (level, gold, gear, Lost Pages, achievements, outcomes, %, difficulty). Part 2 is a classic scroll (logo, cast with portraits, crew, music, voices, art, tools/licenses, thanks) timed to end with the song (Prophecy of Metocy, played once; `SONG`) and stop on "Thanks for playing!". E skips a run card / hold E = 4x scroll, Esc twice skips, E at the end → title. **All roll text is DRAFT data in `ROLL`**, including the "Code, cutouts & sounds: Claude (Anthropic)" line (still waiting on Ebain's answer on that one). The old `end_card` recap screen isn't used by the summit any more (`_end_lines()` is only printed by the finale tour).
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
