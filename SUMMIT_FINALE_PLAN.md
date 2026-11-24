# Summit finale plan (Ebain's spec, 11/24)

**Status: BUILT 11/24 (ebain).** Everything in sections 1–3 is in the game; section 4 is in ASSETS_NEEDED.md; from
section 5 only the Chipotle Bowl pitch is in (as the castle's 5th choice). How it works now: HANDOFF.md section 1, item 5.
Choices made while building: the hymn still makes you wait before Mattias talks (Asar's "Peep the song first"); the
ambush ducks the song instead of a hard music cut (section 1 wins over section 3); the goblin party is a little set
built inside the summit scene (the real village is Asar's file); no boss music exists yet.

Answers from Ebain (11/24): **beating Dulbers in the Mart boss fight counts as killing him** (same as the goblin chase), so he only ambushes if the trio never fought him; Ebain and Asar build this together.

Planning doc for the end of Chapter 1: Summit arrival → Dulbers ambush → Mattias's castle → ending. Ebain's quoted
lines are verbatim (`# Ebain`). Everything Claude wrote is **DRAFT**. Scene files are Asar's (`summit.gd`,
`summit_script.gd`), so check the board before building.

---

## 0. What the game actually remembers (checked in the code 11/24)

**Important catch:** story *outcomes* (`village_chug`, `pass_lore`...) are saved **across all playthroughs** for the
title-screen %, not per run. Only `Game.flags` are per run. So right now the game **can't tell how this run got past
the giant or the troll.**

**Fix (1 line, dialogue.gd, hot spot):** where `_run_steps` unlocks an outcome, also store it as a per-run flag:
`Game.set_flag("way_" + id.get_slice("_", 0), id)` → `way_village`, `way_mart`, `way_pass`, `way_troll` hold this
run's pick. Every dynamic line below uses these plus the existing flags.

Per-run facts available after that fix:

| Moment | Flag | Means |
|---|---|---|
| Throne | `way_village` = speech / chug / skorn_king / sneak / negotiate | how Lykor got off the throne |
| | `chugWon`, `skornKing`, `goblinAllies`, `has3Beezy` | won the chug-off · crowned Skorn · goblins follow · got beezy |
| Village extras | `thumbsBeaten`, `loreOffWon`, `chugRematchWon` | beat Big Thumbs · won the Lore-Off · beat Gulpo |
| Troll | `way_troll` = good / bad | what they told the bridge troll |
| Mart | `way_mart` = everyone / skorn_first / refuse / xylo / goblins | what they did with Dulbers' pill |
| | `dulbersDead` | goblins chased Dulbers down (only the goblins path) |
| | `dulbersEscaped`, `skornTripped`, `hasMidtocy` | Dulbers got away · Skorn tripped · someone still has the midtocy |
| Pass | `way_pass` = midtocy / sneak / lore / fight / bogdrinker | how they got past Diddy Chud Giant |

---

## 1. Scene flow (Ebain's spec, with build notes)

**A. Arriving at the summit**
- Toast before the song: "Don't walk yet if you want to hear the song." If they walk on, duck the song to background
  volume when Dulbers shows up (same ducking trick as the village music).
- Skorn: "Woah.. I think we made it boys" `# Ebain`
- Xylo: "Damn that was OD to get here, **<line from 2a>**" `# Ebain` + DRAFT ending
- Lykor: "Deadahh." `# Ebain`

**B. Halfway down the trail**
- Move Mattias's "Impressive, my beloved trio, come closer" (already recorded) here.
- Lykor: "Bet. Here we go, folk" `# Ebain`

**C. Dulbers ambush (only if Dulbers is still alive)**
- He's dead if the goblins chased him (`dulbersDead`) or the trio beat him in the Mart boss fight (`way_mart` = everyone /
  skorn_first; that fight can't be lost for good). Build note: have the Mart boss-fight win set `dulbersDead` too, so the
  check is just one flag. That leaves the ambush for `way_mart` = refuse / xylo.
- Right after Lykor's line, normal Dulbers (`dulbers.png`, not the demon) sprints up from the Pass behind them and says
  **<line from 2b>**.
- Choices (Ebain's answers 11/24):
  1. **Apologize + swear loyalty to Dulbmeethus** → Dulbers: "Good boy." `# Ebain` and he leaves.
  2. **Fight him** (normal Dulbers, not the demon).
  3. **"Offer him fentocy"** `# Ebain` → he takes it thinking it's midtocy, and dies. Sets `dulbersDead`. (Available on
     every run, since it's a different pill from the midtocy.)
  4. **Call for Mattias** → "Get lost midget fucker!" `# Ebain` → fight normal Dulbers, with Mattias fighting alongside the
     trio as a 4th fighter (same slot Chief Bogdrinker uses).
- Store the pick as `way_ambush` so Mattias can mention it.

**D. The castle**
- Mattias: "Welcome to da crib folk, you had said you was looking for metocy? You have earned it. I had heard that y'all
  **<line from 2c>**. That's OD." `# Ebain`
- Mattias: "Here yall go folk, have at it." `# Ebain` (the glowing blue pill)
- Choices: 1 "Bet. Here we go folk." · 2 "you had said u was fuckin wit one too?" → "Bet." (all 4 take it) · 3 "Bad." →
  "Oh okay." → hard end · 4 sucker punch → near-impossible boss (new `mattias` fight in combat_data.gd, numbers kept
  in one place so new items/levels can be balanced against it later). **Losing it is its own ending**, not a retry:
  Mattias: "Y'all must be geeking off that midtocy to think you could defeat me." `# Ebain` → END OF CHAPTER 1.
  **Winning:** Mattias: "I should have never underestimated the trio." `# Ebain` → they take the metocy (goes to E).

**E. After the metocy (choices 1 and 2)**
- Mattias asks about giving every goblin metocy. No → end right there. Yes → cut to the goblin village dancing → end.

---

## 2. Dynamic lines (DRAFT, pick one per moment by priority)

**2a. Xylo: "Damn that was OD to get here, ..."** (checks the Pass first, since it's the most recent)
- `way_pass=fight`: "we threw hands with a whole giant."
- `way_pass=lore`: "I put a giant to sleep with lore that don't exist."
- `way_pass=sneak`: "we tiptoed across a giant's whole body."
- `way_pass=midtocy`: "Skorn threw a pill at a giant and it worked."
- `way_pass=bogdrinker`: "the giant was the Chief's cousin. That's the only reason we alive."
- fallback `way_troll=bad`: "and that troll still mad we told him Bad."
- fallback: "my wings hurt and I don't even use them."

**2b. Dulbers' ambush line** (by `way_mart`)
- `refuse`: "Y'all walked out my store. In front of customers."
- `xylo`: "Lore-reading ahh dragon exposed my whole business."
- add-on if `hasMidtocy`: "And I KNOW y'all still got my midtocy."
- add-on if `goblinAllies`: "Where the goblins at? Y'all scared without the goblins?"

**2c. Mattias: "I had heard that y'all ..."** (ambush first, then the biggest thing from the run)
- `way_ambush=apologize`: "swore loyalty to Dulbmeethus on the way up" (Mattias pauses: "...That's OD.")
- `way_ambush=fentocy` also works as the top pick. It's the darkest thing the trio can do.
- `way_ambush=fight` or `mattias`: "made Dulbers cry on a mountain"
- `way_ambush=fentocy`: "gave Dulbers fentocy. That's crazy"
- `way_mart=goblins`: "had the goblins handle Dulbers"
- `way_mart=everyone` or `skorn_first`: "beat Dulbers' ass in his own store, while tripping"
- `skornKing`: "made Skorn king of the goblins"
- `chugWon`: "outdrank Chief Bogdrinker"
- `way_pass=lore`: "read a giant to sleep"
- `thumbsBeaten`: "beat up Big Thumbs"
- `way_troll=bad`: "told a troll his bridge was bad"
- fallback: "been through some shit"

**Extra climax lines (only if they fit):**
- After choice 2, all four tripping. Skorn: "Mattias you was fuckin wit one this whole time?" Mattias: "Bet."
- If they fought Dulbers with Mattias, Lykor at the castle: "You fight like you mog." Mattias: "Thank you folk."

---

## 3. Making it feel like a climax (no dialogue)

- **Arrival:** slow camera dolly up to the castle, song swells, wind and sparse embers in the air.
- **Ambush:** hard music cut, footsteps from behind, camera whips 180° to Dulbers, small screen shake, dust trail.
- **Mattias's entrance (call for help):** purple poof, a low choir hit, slow-mo for half a second, then combat.
- **Castle:** music drops to silence on "Welcome to da crib folk", torches flare one by one, the pill hovers with a blue
  point light and particles, and the camera pushes in slowly while he talks.
- **Taking it:** reuse the Mart trip recolor, a wobble or hue-shift on the screen, a choir sting, and the trio's sprites
  floating up slightly.
- **"Bad.":** hard cut to black, no music, "END OF CHAPTER 1" in plain text. The silence is the joke.
- **Sucker punch:** hit-stop freeze frame, zoom on the impact, letterbox bars slide in, boss music.
- **Goblin party:** "The Mogging Elf" song, confetti, the goblin band, fire pit lit, camera orbits the village, then
  credits.

---

## 4. Images to generate (green screen, side views face right)

1. **Normal Dulbers running** (side view), for the ambush sprint.
2. **Dulbers kneeling or crying** (apology and loss outcomes).
3. **Mattias battle pose** (casting, side view) and **Mattias side view** for walking.
4. **The metocy pill** close-up: glowing blue oval, inventory icon and in-world glow sprite.
5. **Trio tripping** versions (eyes wide, floating), or one tripping portrait each.
6. **Goblins dancing**: 2 or 3 poses.
7. **Castle exterior at night** reference art, if the 3D build needs a target.
8. **END OF CHAPTER 1** title card.

---

## 5. Extra silly choices for Mattias (DRAFT pitches)

- **Lykor mogs Mattias:** close-up push-in, Mattias mogs back harder, and Lykor faints. Ends.
- **Skorn tries to light it like the map:** pill burns, everyone stares, Mattias: "...Bet." Ends.
- **Xylo: "Deloye Lore says this pill is fake."** Mattias: "...Damn." Ends abruptly.
- **"Y'all hiring?"** (the goblin callback): Mattias: "No." Back to the choices.
- **Ask for it in a Chipotle Bowl:** Mattias pulls one out of nowhere. Counts as choice 1.
