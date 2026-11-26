# Voice batch 2026-11-26 (Ebain)

Run on the PC with Ultimate TTS Studio (see VOICE_LINES.md, "Cloned Skorn lines"):

    python3 tools/tts_batch.py refs tools/voice_batches/2026-11-26/lines.json --out refs
    python tts_batch.py gen tools/voice_batches/2026-11-26/lines.json --refs refs --out out
    python3 tools/tts_batch.py pack out -o clones.zip      # applies the FX table (troll: Chief's voice, -4 semitones)
    python3 tools/import_voices.py clones.zip

- `lines.json`: 12 lines. The first 7 that still talk on the robot voice and are Ebain's or Asar's (not DRAFT): the **Bridge Troll**
  ("Y'all had said i could get some bussy?", cloned from **Chief Bogdrinker's** takes, then lowered 4 semitones: `FX["troll"]`
  in `tts_batch.py`), Lykor's new "I always knew you were on that type timing", Xylo's "Shut up Lykor" (new) and four
  Xylo lines. Redo one: add `--only "line text"`. Want the troll deeper: change `st` in `FX["troll"]`.
- `skorn_ebain_lines.json`: every Skorn line tagged `# Ebain` (26). They **all already have a voice** (his mic takes or
  the 11/25 clones), `already_has_voice` says so. Use it if you want to regenerate Skorn from scratch (`gen ... --only`).
- `skorn_draft_lines.json`: the 47 Skorn lines that are still `# DRAFT` (Claude's wording) and on the robot voice. Only use it
  if you want those voiced too; reword the ones you don't like first (drafts are not final).
- **Deloye** (5 lines, `# Ebain`) are in `lines.json` too. His voice is Ebain's reference recording, kept at
  `tools/voice_refs/deloye.wav` (from "eloy voice.mp3": long pauses cut, mono, loudness-matched); the `refs` step copies
  it to `refs/deloye.wav` by itself. Respellings for him: Deloye = Duh-loy, shi = shee, Im = I'm, Dulbmeethus =
  Dulb-mee-thus (`PRONUNCIATIONS` in `tts_batch.py`). No pitch change (not in the FX table).
