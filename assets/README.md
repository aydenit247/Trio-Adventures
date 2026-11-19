# Assets

## Portraits — `assets/portraits/`

Square PNGs (1024×1024 is plenty), chest-up, facing camera, plain solid background,
same realistic style and lighting across all characters.

File names the game looks for:

| Character | Files (base + moods) |
|---|---|
| Skorn | `skorn` + angry, shocked, smug, confused, tweaking |
| Lykor | `lykor` + angry, shocked, mog, flattered, tweaking |
| Xylo | `xylo` + shocked, vision, unimpressed, smug, tweaking |
| Dulbers Frint | `dulbers` + grin, demon |
| Diddy Chud Giant | `giant` (asleep) + angry |
| Goblin | `goblin` + worship, joy |
| Others | `mattias`, `dulbmeethus` |

Mood files are named `<character>_<mood>.png` (e.g. `lykor_mog.png`). In a scene script, use `mood: 'mog'`.

Anything missing shows a placeholder, so add them one at a time. An expression that's missing
falls back to the character's base portrait.
