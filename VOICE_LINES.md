# Voice lines

**Every character's voice is now AI-generated** with Ebain's Emberstage voice studio:
https://github.com/aydenit247/Voice-actor-generation (Gemini text-to-speech). The studio loads every line from the
game scripts, Ebain (and Asar) set each character's voice and each line's delivery, generate takes, and approve them.

- **Lines without a generated voice** still use the robot TTS as a fallback. That's on purpose, so new lines always talk.
- **Easiest way (anyone, from a browser):** upload the studio's export zip into the `voice-imports/` folder on GitHub
  (Add file → Upload files). GitHub Actions ("Voice import") imports it, pushes, and rebuilds Windows by itself.
  See `voice-imports/README.md`.
- **By hand (a Claude with a shell):** the studio's **Export approved** gives a zip (WAV files with effects already applied, plus
  `manifest.json`). Run `python3 tools/import_voices.py path/to/the.zip`: it converts everything to OGG Vorbis in
  `godot/assets/voices/<character>/`, updates `godot/scripts/voice_index.gd` (line text → file; a re-imported line
  replaces its old file) and lists any lines that were reworded since. Then `godot --headless --path godot --import`,
  commit, push: the Windows build updates itself. Needs ffmpeg.
- **Inner thoughts** play their voice file too (the studio bakes the echo in).
- **Reworded a line?** Its old voice file stops matching, and the line goes back to the robot voice until it's regenerated.
  The studio picks up script changes from GitHub (see its README).
- Asar's 37 goblin/Chief recordings were removed on 2026-11-21 (Ebain's call).

## Narrator (Asar's own recordings, 2026-11-22)
The narrator is voiced by Asar's recordings: 26 mp3s in `godot/assets/voices/narrator/`, mapped by hand in
`voice_lines.gd` `LINES` (exact line text → file). Asar's call: **narrator lines without a recording were removed from
the game**, so every narrator line now has his voice. Two lines were changed to say what he recorded
("Folk, head into that village over there." and "And OD as a mufucka."). Adding or rewording a narrator line means it
needs a new recording from Asar, or it plays on the robot voice.

## Goblins (Asar's recordings, 2026-11-22)
86 mp3s in `godot/assets/voices/goblins_asar/` (village goblins, Chief Bogdrinker, Big Thumbs, Wuzzle, Gulpo, Grubnik,
Sludge, Haggle, the clerk, combat taunts), mapped in `voice_lines.gd` `LINES`. They win over the studio goblin voices
in `voices/goblin/`. Reworded to match: "BYE!! YOU BETTER COME BACK ONE DAY!!", Gulpo's "Me liver…", Big Thumbs' "Shi did
not work.", the Chief's "Then we will take him there OURSELVES", and his perfect-hit taunt is now "On some smelly shiiii!".

## Dulbers Frint (Asar's recordings, 2026-11-22)
18 mp3s in `godot/assets/voices/dulbers/`, mapped in `voice_lines.gd` `LINES` (Mart dialogue + his 3 combat taunts). Four
lines were changed to match the takes ("Store's open, folk!", "Similar vibes doe.", "Hand-made. On some type shit.",
"For y'all ahh? First one's free."). Still robot: "…\"Loser\"? Says so right on your forehead, my boy." (no take yet).

## Lykor and Xylo (Asar's own recordings, 2026-11-22)
Same deal as the narrator: 71 Lykor + 40 Xylo mp3s in `godot/assets/voices/lykor/` and `xylo/`, mapped in
`voice_lines.gd` `LINES` (dialogue and their combat barks). **Their lines without a recording were removed.** Lines Asar
and Ebain reworded in the recordings were changed in the scripts to match (see the COLLAB log, 2026-11-22). Adding or
rewording a Lykor or Xylo line means it needs a new recording, or it plays on the robot voice.

## Cloned Skorn lines (Ebain's PC, 2026-11-25)
6 Skorn lines are voice-cloned with **Ultimate TTS Studio** (ChatterboxTTS, Exaggeration 0.7, CFG 0.3) using
`tools/tts_batch.py` (`find` → `refs` → `gen` → `pack` → `tools/import_voices.py`). Each take uses reference audio built
from Skorn's existing takes closest in wording and mood, then `pack` lowers the pitch to Skorn's ~90 Hz (Rubber Band,
capped at -5 semitones, plus a quiet octave-down layer). Only Ebain-tagged lines are cloned (DRAFT lines are skipped), and
only Skorn's clones are in the game: the Mattias, Dulbers and goblin test clones are not approved, so they aren't imported.
Reworded to fit his voice: "Man, it's about cold as a mufug." · "Wizard jit? What are you doing here?" (camp + Pass; this
replaces only that spoken line, **Metocin Mattias's name is unchanged everywhere else**) · "Bruh, it's a store, mud. You
feel a store?" · "Woahhh.. on God, I think we made it boys" · "Are all of these books Deloye lore scripture?" · "Damn bro,
you ain't gonna make it, sad in de bih". Also cloned 11/25: "I'm not tired. I'm finna stay up and guard the fire." and "From… other fires." (camp; "From… other fires" was pitched -5 st by hand because pitch detection failed on it). **Lykor** has 6 clones (ChatterboxTTS, no pitch fx), including his reworded camp line "Dumbass Skorn burning our only map to the metocy, fuck you Skorn, you on some bullshit, I put that on the set." (it replaces Asar's "Why does that look like… nah" take). Redo one line: `python3 tools/tts_batch.py gen ... --only "line text"`.

## Skorn lines still on the robot voice (checked 2026-11-22, Asar)
These have no generated file yet, so they fall back to TTS. Generate + approve them in the studio and re-import:
- camp: "Man, it's about cold as a motherfucker." · "Good thing I got the fire going though." · "Bunch of squiggly ass lines." ·
  "I'm not tired. I'm finna stay up and guard the fire." · "From… other fires." · "Metocin Mattias? What are you doing here?"
  (also used in the Pass)
- mart: "Bro, it's a store. You feel a store?"
- village: "Send your biggest guy." · "BOOOO. GET A JOB." · "BOOOO. Ain't nobody dumb enough to pay twenty spoons for a
  receipt." · "Say less. We'll get your spoon, lil bro." · "Bro it's just a mirror ball." · "Found a Chipotle Bowl in
  there. It was sealed. Don't worry about it." · "Smart." · "Don't worry about me. I'm a king now. I got spoons."

## Summit finale lines still on the robot voice (added 2026-11-24, Ebain's summit plan)
New lines in `summit_script.gd`. Ebain approved putting Lykor/Xylo lines in (his spec), so they play on the robot until
Asar records them. Lines marked *dynamic* change per run: the studio sees the fallback text only.
- **Lykor:** "Deadahh." · "Bet. Here we go, folk" · "You fight like you mog." (only if Mattias fought Dulbers with you)
- **Xylo:** "Damn that was OD to get here, …" (*dynamic*: 7 endings, see `DYN_XYLO_ARRIVE`)
- **Skorn:** "Woah.. I think we made it boys" · "Aight, aight. My fault, Dulbers. We fw Dulbmeethus. On everything." ·
  "Ayo, peace offering. Here go some midtocy. On the house." · "MATTIAS! We need you, folk!" · "Mattias you was fuckin
  wit one this whole time?"
- **Dulbers:** ambush line (*dynamic*: "Y'all walked out my store. In front of customers." / "Lore-reading ahh dragon
  exposed my whole business.") · "And I KNOW y'all still got my midtocy." · "Where the goblins at? Y'all scared without
  the goblins?" · "Good boy." · "…Free midtocy? Y'all finally learning." · "*sniffling* Y'all gon' hear from Dulbmeethus
  about this…"
- **Mattias:** "Welcome to da crib folk, …" (*dynamic* middle, see `DYN_MATTIAS_WELCOME`) · "Thank you folk." · "Here yall
  go folk, have at it." · "Bet." · "Oh okay." · "Get lost midget fucker!" · "I should have never underestimated the trio." ·
  "Y'all must be geeking off that midtocy to think you could defeat me." · "Now peep this, folk. What if we gave every
  goblin some metocy?" (plus "Peep the song first folk, shit is gas", still unrecorded)
- Already recorded and reused: Mattias "*echoing* Impressive, my beloved trio. Come closer…" (moved from the Pass) and the
  narrator's "Dulbers Frint was never seen again."
- **Not used anymore:** Skorn's "Man, I'm finna slap this old head too." (it answered Mattias's echo at the end of the
  Pass; the echo moved to the summit). The recording is still in `assets/voices/skorn/`.
