# Ruins → Cave → Rat Colony, and Charis's house (plan, Ebain 2026-11-24)

Status: **planned, not built.** A chat that builds this: claim it on the COLLAB board first, follow CLAUDE.md.
Everything marked DRAFT is a placeholder: Ebain writes the real lines and has the final say on story/characters.

## Ebain's answers (don't re-ask)
- **Where:** an optional **side path** off the road between the Goblin Village and the Metocy Mart. Never blocks the story.
- **Rats:** a **big 5-way choice** like the throne / Mart / giant scenes. Each option is a story outcome (Scrapbook + Outcomes).
- **Cave:** a **puzzle** to find the way out. Ebain: "interesting, not super hard, more than just push boulders" (design below).
- **Dialogue:** placeholders first (# DRAFT), Ebain replaces them later.
- **Gold:** the rats run a **rat trader** shop in the cave.
- **Charis's house:** one of the 4 houses at the Metocy Mart becomes enterable (Ebain: "whatever is best"). Charis lives
  there. Dialogue later (Ebain writes it): until then Charis has one DRAFT greeting.
- **Assets:** Poly Haven for everything it has (`tools/fetch_polyhaven.py`). Ebain supplies character art (below).

## Flow
1. **Ruins (side path):** a fork off the Village → Mart road (world map: a small "Old Ruins" stop between Village and
   Mart, reached by a signpost). Crumbled walls, pillars, overgrown floor, 3–4 loot chests/spots (gold + items + XP).
2. **The trap:** the biggest, shiniest chest is in the middle. Opening it: the floor gives way, the trio falls into the
   cave (fade, thud, Skorn's DRAFT line). The other chests can be looted before or after.
3. **The cave:** dark, torch-lit (torches on walls + a light around the leader). A few loot spots, 1–2 roaming rat
   groups (fights for XP), then the puzzle chamber.
4. **The puzzle** opens the way to the colony.
5. **The Rat Colony:** a big cavern full of rats, the Rat Elder/King on a pile of junk. The **5-way choice**. After it:
   the rat trader opens (unless you fought them all), and a tunnel leads up and out back to the ruins.

## The puzzle: "The Three Seals" (uses the whole trio + Q to switch)
A sealed rat door with **3 pressure plates**, each carved with a symbol (spoon, bowl, book). Three boulders in the room
carry the same symbols, but it's not just "push the matching one":
- **Skorn** is the only one strong enough to push the **big** boulder (others: DRAFT "it won't budge" line).
- **Lykor** is the only one small/slick enough to squeeze through a **crack in the wall** to reach the second
  room, where one boulder is stuck behind a rubble pile; he pulls a lever that drops the rubble.
- **Xylo** is the only one who can **read the carvings** on the wall (Deloye-style runes). The carving says which
  plate each boulder goes on, and the plates' symbols are **worn off** until he reads it, so you need him. (Others reading it:
  DRAFT joke lines.)
- Boulders slide on a grid until they hit something (sliding-tile style), so you have to line them up, but each
  boulder has only a 2–3 move solution. A **reset** rope/lever puts them back (a rat pops out: DRAFT "skill issue").
- When all 3 sit on their plates: rumble, the door grinds open, the rats on the other side scatter.
Tuning: solvable in 2–4 minutes; a hint from whoever's leading after 90 s of no progress (DRAFT lines).

## The 5-way rat choice (all options + lines are DRAFT ideas; Ebain picks/rewrites)
Outcome ids `rats_*` → add to `progress_data.gd` ITEMS (story = true) + `ScrapbookUI.SECTIONS` ("The Rat Colony",
"rats_") + `ScrapbookUI.HINTS`. Rebalance the points so the total stays 100.
1. `rats_fight`: fight the colony (a rat swarm + the Elder: XP + gold, but no trader).
2. `rats_king`: Skorn gets crowned Rat King (callback to Lykor's throne; the trader gives a "royal discount").
3. `rats_trade`: do business (the trader opens with extra stock).
4. `rats_lore`: Xylo out-lores the Rat Elder (a Deloye Lore bit; the colony shows a secret shortcut out).
5. `rats_mog`: Lykor mogs them into submission (the rats worship him; one follows the party as a pet?).

## Rat trader (ShopUI with its own STOCK, rat-themed)
Cheap-but-weird consumables + one or two cave-only gear pieces. Reuse `ShopUI` (pass a stock list + title). Prices in
line with the new gear tiers (see the leveling rework in HANDOFF/COLLAB).

## Charis's house
Pick the Mart house that fits best (probably the one right of the Mart, `mart.gd` `_house(Vector3(9.5, 0, -17.0)…)`).
Door → interior built off to the side (like the Mart shop at `INT`), furnished from Poly Haven (bed, table, shelves,
rug, lantern, fireplace). Charis stands inside: talk = one DRAFT greeting until Ebain writes dialogue. Add Charis to
`dialogue.gd` CHARS (name color + TTS voice) and a portrait.

## Poly Haven to fetch (check names with tools/fetch_polyhaven.py; skip what's missing)
- Ruins: broken stone walls/pillars, `stone_wall_*`, `castle_brick_broken_06` + `mossy_brick` (already in the repo),
  overgrown ground, `treasure_chest` (already used on the trail), dead trees/bushes, rocks.
- Cave: `rock_wall_10` (in repo), cliff/cave rock textures, boulders (`boulder_01` is used in the Pass), stalagmite-ish
  rocks, wooden supports/planks, torches/lanterns, a rope, barrels/crates for the rat junk pile, bones if available.
- Charis's house: bed, table, chairs, shelves, rug fabric (`dirty_carpet`/`quatrefoil_jacquard_fabric`), lantern,
  stove/fireplace, plants.

## Art Ebain supplies (Gemini, green screen like the others → tools/key_chars.py)
- **Rat** (regular colony rat): front, side, back. Optional variants (a fat one, a tiny one).
- **Rat Elder / Rat King**: front (+ side/back if possible) and a portrait.
- **Charis**: front, side, back and a portrait (+ moods later).
Until they arrive: placeholder cards (tinted goblin art with a "?" label) so it's playable.

## Testing
Add a `--shots` tour for the ruins + cave (fall, solve the puzzle with scripted pushes, each rat choice via
`RUINS_CHOICE=0..4`) and a Charis house step to the Mart tour. Headless first.
