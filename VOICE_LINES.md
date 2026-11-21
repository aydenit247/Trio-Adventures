# Voice lines

**Every character's voice is now AI-generated** with Ebain's Emberstage voice studio:
https://github.com/aydenit247/Voice-actor-generation (Gemini text-to-speech). The studio loads every line from the
game scripts, Ebain (and Asar) set each character's voice and each line's delivery, generate takes, and approve them.

- **Lines without a generated voice** still use the robot TTS as a fallback. That's on purpose, so new lines always talk.
- **Plugging voices in:** the studio exports a zip (WAV files + `manifest.json` + `voice_lines_snippet.gd`). Convert the
  WAVs to MP3 (`ffmpeg -i in.wav -b:a 96k out.mp3`), put them in `godot/assets/voices/<character>/`, and add the snippet
  lines to `LINES` in `godot/scripts/voice_lines.gd`. Matching is by line text.
- **Reworded a line?** Its old voice file stops matching, and the line goes back to the robot voice until it's regenerated.
  The studio picks up script changes from GitHub (see its README).
- Asar's 37 goblin/Chief recordings were removed on 2026-11-21 (Ebain's call).
