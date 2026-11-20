# Trio Adventures — 2.5D Test (Godot)

A small test of what Trio Adventures could look like as a "real" game: a 3D world you walk around in,
with the trio as 2D cutouts (like Octopath Traveler / Paper Mario / Don't Starve).

## How to play it

1. Download **Godot 4.7** (free) from https://godotengine.org/download. Use the normal version, not ".NET".
2. Unzip this folder somewhere.
3. Open Godot → **Import** → pick `project.godot` in this folder → **Import & Edit**.
   (The first time, it takes a few seconds to import the art.)
4. Press **F5** (or the ▶ Play button, top right).

## Controls

| | |
|---|---|
| WASD | walk (Shift = run) |
| E / Space | talk / look at things |
| Tab | switch who you control (Skorn → Lykor → Xylo) |
| ← / → or right-mouse drag | turn the camera |
| Mouse wheel | zoom |
| V | robot voices on/off |

Things to find: the campfire, the burnt map scrap, Lykor's bag, the tent, Lykor and Xylo, a goblin
who wants a job, and whatever is waiting at the end of the dark path.

## What's in here

- `scripts/main.gd` — builds the whole level in code (forest, tents, fire, moon, fog, camera, interactions)
- `scripts/unit.gd` — a character as a 2D cutout in 3D (walk bounce, following, facing)
- `scripts/dialogue.gd` — dialogue box with portraits, choices and TTS voices
- `scripts/camp_script.gd` — the dialogue lines (Ebain's lines tagged `# Ebain`, Claude's drafts `# DRAFT`)
- `scripts/ambience.gd` — synthesized campfire crackle + crickets
- `assets/` — cutouts and portraits copied from the web game

Everything (trees, tents, fire) is simple placeholder 3D built from basic shapes. Real 3D props or
a hand-painted look can replace them later without touching the characters or dialogue.
