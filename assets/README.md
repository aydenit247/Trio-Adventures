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


## Full-body cutouts — `assets/characters/`

Transparent PNGs keyed from green screen.
- Story: `skorn`, `lykor`, `xylo`, `*_tweaking`, `goblin`, `goblin_kneel`, `goblin_chief`, `dulbers`, `dulbers_demon`, `mattias`, `giant_angry`, `giant_sit`
- Combat (ready, not wired in yet): `skorn_slap`, `skorn_crashout`, `skorn_throw`, `lykor_hairflip`, `lykor_mog`, `lykor_scream`,
  `xylo_blast`, `xylo_lore`, `xylo_chudout`, `skorn_hurt`, `lykor_hurt`, `xylo_hurt`, `goblin_fight`

## Items — `assets/items/`

`metocy`, `midtocy`, `dice`, `beer` (heal), `chipotle_bowl` (heal)
