# Drop voice packs here

To put voices from the Emberstage voice studio into the game:

1. In the studio, click **Export approved**. You get a zip (e.g. `trio-voices-approved-2026-11-21.zip`).
2. On GitHub, open this folder (`voice-imports`), click **Add file → Upload files**, drag the zip in, and click
   **Commit changes**. Either branch is fine (`main` or `foundation`).
3. Wait a few minutes. GitHub does the rest by itself:
   - converts every voice to OGG and puts it in `godot/assets/voices/<character>/`
   - links each file to its line (`godot/scripts/voice_index.gd`); a line you voiced again replaces its old file
   - deletes the zip from this folder
   - rebuilds the Windows game, so the new voices are in the download at
     https://github.com/aydenit247/Trio-Adventures/releases/tag/latest-windows

Progress and results are on the **Actions** tab ("Voice import"). The result page lists how many lines went in and any
lines that weren't found in the game's script (usually because the line was reworded after it was voiced: regenerate
it in the studio and upload again).

If it fails, the zip stays here and the Actions tab shows why.
