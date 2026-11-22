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

## Skorn lines still on the robot voice (checked 2026-11-22, Asar)
These have no generated file yet, so they fall back to TTS. Generate + approve them in the studio and re-import:
- camp: "Man, it's about cold as a motherfucker." · "Good thing I got the fire going though." · "Bunch of squiggly ass lines." ·
  "I'm not tired. I'm finna stay up and guard the fire." · "From… other fires." · "Metocin Mattias? What are you doing here?"
  (also used in the Pass)
- mart: "Bro, it's a store. You feel a store?"
- village: "Send your biggest guy." · "BOOOO. GET A JOB." · "BOOOO. Ain't nobody dumb enough to pay twenty spoons for a
  receipt." · "Say less. We'll get your spoon, lil bro." · "Bro it's just a mirror ball." · "Found a Chipotle Bowl in
  there. It was sealed. Don't worry about it." · "Smart." · "Don't worry about me. I'm a king now. I got spoons."
