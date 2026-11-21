# Trio Adventures

*by Ebain* — a goofy browser RPG starring Skorn, Lykor and Xylo on a quest for the metocy.

All design decisions live in **[DESIGN.md](DESIGN.md)**.

- **Play the game:** https://aydenit247.github.io/Trio-Adventures/
- **Play the 2.5D test (Godot):** https://aydenit247.github.io/Trio-Adventures/play3d/ — Scene 1 as a walkable camp.
  Source in [`godot/`](godot/). Rebuild with Godot 4.7: `godot --headless --path godot --export-release "Web" ../play3d/index.html`

## Play it locally

The game uses JavaScript modules, so it has to be served (double-clicking `index.html` won't work).
From the repo folder, run one of:

```bash
npx serve .
# or
python -m http.server 8000
```

Then open the address it prints (e.g. http://localhost:8000). In VS Code, the **Live Server**
extension also works.

## Publish it online (GitHub Pages)

1. On GitHub, open the repo → **Settings** → **Pages**.
2. Under **Build and deployment**, set **Source** to *Deploy from a branch*, branch **main**,
   folder **/ (root)**, and save.
3. After a minute the game is live at **https://aydenit247.github.io/Trio-Adventures/**.

Every push to `main` updates the live site.

## Project layout

```
index.html                 entry page
lib/phaser.min.js          game engine (Phaser 3.90, MIT)
src/main.js                game config + scene list
src/scenes/                Boot (loading), Intro (Scene 1), Title
src/ui/DialogueBox.js      portraits, typewriter text, choices
src/data/characters.js     cast, moves, portrait file list
src/data/scenes/           dialogue scripts — voicelines go here
assets/portraits/          character images (see assets/README.md)
```

## Adding voicelines

Open `src/data/scenes/scene1_the_map.js` and replace `line: null` with your line.
Empty slots show up in-game in orange with the scene context.
