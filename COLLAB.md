# COLLAB — the shared board for Ebain's Claude and his friend's Claude

Read `CLAUDE.md` for the rules. Short version: pull first, claim here before building, push the claim right away,
work on your own branch, log what you did when you stop.

Who's who: **ebain** = Ayden's Claude · **friend** = his friend's Claude. (Swap in the friend's name once we know it.)

## Board

### Claimed / in progress
<!-- One line per task:  - [who] task — files: a.gd, b.gd — branch: who/task — started YYYY-MM-DD -->
- (nothing right now)

### Up next (unclaimed — grab one by moving it up and adding your name)
- Explorable Goblin Village: walk-in buildings with interiors (Chief's Hut, Unemployment Office & Bar with the joke
  goblin, Job Board, Shaman's Tent, Spoonsmith, Outhouse, Goblin Pit arena) — waiting on Ebain's picks + dialogue
- Side quests for the village (Lost Spoon, Bar Tab, Lykor's hair contest, Xylo's lore class, Skorn's job interviews)
- More roaming enemies (needs new creature art)
- Swap in real art from `godot/ASSETS_NEEDED.md` as it arrives (huts, throne, sleeping giant, etc.)
- Friend's voice-line MP3 for Mattias + goblins → replace TTS for those characters
- Music tracks (see HANDOFF.md section 7)

### Done (recent)
- 2026-11-21 [ebain] Scene 4 The Pass ported to Godot (End of Chapter 1)
- 2026-11-21 [ebain] Turn-based combat (Combat 2.0) in Godot: in-world fights, XP + gear, roaming enemies,
  Chief ally, Talk/Run, funny defeat penalty, Esc/I menus

## Claimed files
<!-- Files someone is editing right now. Remove your lines when you merge. -->
- (none)

## Log (newest first)
<!-- - YYYY-MM-DD [who] what changed · anything the other person should know -->
- 2026-11-21 [ebain] Set up CLAUDE.md + COLLAB.md so two Claudes can work on the repo without stepping on each
  other. Combat lives in `godot/scripts/combat/`; fights are started with `await fight(key, {...})` from any area.
