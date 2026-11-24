# Assets needed

Art and audio the game is waiting on. Tick or delete a line once it's in.

## Signs (Asar, 2026-11-22)
The village names are now wooden signs in the world (`Level.wood_sign`). Each one shows plain burned-in text until a
picture exists. Drop a **transparent PNG** at `godot/assets/signs/<file>` and it replaces the board automatically
(the sign keeps the picture's shape; no code change). Wooden board, text painted/carved on it, goofy goblin-made look,
about **3:1 wide** (the throne plaque and outhouse sign about 2:1), at least 1024 px wide.

| File | Text on it | Where |
|---|---|---|
| `sign_chief.png` | CHIEF'S HUT (CLOSED) | over the Chief's Hut door |
| `sign_bar.png` | UNEMPLOYMENT OFFICE & BAR | over the bar door |
| `sign_shaman.png` | SHAMAN'S TENT | on a post by the tent |
| `sign_outhouse.png` | OUTHOUSE (SMELLS) | on the outhouse, above the moon door |
| `sign_goblin_house.png` | DO NOT DISTURB (NAPPING) | on the locked goblin house door |
| `job_board.png` | JOB BOARD | across the top of the job board |
| `sign_throne.png` | THRONE (spoons, bones, 1 wheel) | small plaque on the throne's base |
| `sign_shop.png` | HAGGLE'S STALL (NO HAGGLING) | over the market stall (village) |
| `sign_trail_village.png` | GOBLIN VILLAGE (NO TROLLS) | trail, north end |
| `sign_trail_camp.png` | BACK TO CAMP | trail, south end |
| `sign_troll_hut.png` | DO NOT DISTURB | troll's hut door ("It's good" path) |
| `sign_wizard_lair.png` | WIZARD'S LAIR (NO SOLICITORS) | Summit Path, by the plaza |
| `sign_metocy_mart.png` | METOCY MART → (probably) | signpost at the east road, arrow pointing right |

## Shop item pictures (Asar, 2026-11-22)
New gear sold at Haggle's Stall shows a "?" crate until it has a picture. Same style as the other item icons:
**transparent PNG, roughly square, about 512 px**, in `godot/assets/items/`.

| File | Item |
|---|---|
| `pot_lid.png` | Pot Lid Shield (a pot lid used as a shield) |
| `jordan9s.png` | Jordan 9's (sneakers) |
| `goblin_tooth.png` | Lucky Goblin Tooth (on a string) |
| `rock.png` | A Rock (Pre-Owned) |

## Rat colony art (RUINS_PLAN.md, 2026-11-24)
Gemini, realistic, green screen like the goblins; `tools/key_chars.py` cuts them into `godot/assets/characters/`.
**Side views face right.** Make the front first, then attach it when asking for side/back ("same rat") so they match.
Portraits: square, opaque, dark candle-lit backdrop like `portraits/goblin.png`. Prompts: in Ebain's chat (11/24),
short version below. Rats are upright, knee-to-waist high next to the trio, wearing scavenged junk.

| File | What |
|---|---|
| `rat_front.png`, `rat_side.png`, `rat_back.png` | regular colony rat (bottle-cap armor, thimble helmet, toothpick spear) |
| `rat_fat_front.png`, `rat_tiny_front.png` | variants for fights/crowds |
| `rat_king_front.png`, `rat_king_side.png`, `rat_king_back.png` + `portraits/rat_king.png` | old fat Rat King: bottle-cap crown, sock cape, corncob scepter |
| `rat_trader_front.png` + `portraits/rat_trader.png` | the shady rat trader with a huge junk backpack |
| `portraits/rat.png` | a regular rat's portrait (for its lines) |

## Summit finale art (Ebain's summit plan, 2026-11-24)
The finale works with the current art; these would make it look right. Gemini, realistic, green screen, **side views
face right** (`tools/key_chars.py` cuts them into `godot/assets/characters/`).

| File | What | Used for (stand-in today) |
|---|---|---|
| `dulbers_run_side.png` | regular-size Dulbers running, side view | the ambush sprint (`dulbers.png`) |
| `dulbers_cry.png` | Dulbers kneeling / crying | "Good boy." exit and crying off after a fight (`dulbers.png` tilted) |
| `mattias_cast.png`, `mattias_side.png` | Mattias casting (battle pose) and walking side view | fights (`mattias.png`) |
| `assets/items/metocy.png` (new) | the metocy close-up: glowing blue oval, transparent | the hovering pill + inventory (current `metocy.png`) |
| `skorn/lykor/xylo_tweaking.png` (new takes) | eyes wide, floating | tripping on the metocy (the Mart's tweaking art) |
| `goblin_dance_1..3.png` | goblins dancing, 2–3 poses | the goblin party ending (standing goblins bouncing) |
| reference only | castle exterior at night | if the tower gets rebuilt |
| `assets/backdrops/end_of_chapter_1.png` | END OF CHAPTER 1 title card | end cards are plain text today |

Also wanted: a **boss track** for the Mattias fight (there's no battle/boss music yet).
