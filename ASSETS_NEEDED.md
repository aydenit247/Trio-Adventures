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
