# The Secret Deloye Lore Library (plan, Ebain 2026-11-24)

Status: **built 2026-11-24 (ebain); made a big walkable library the same day** (Ebain: "much bigger place you have
to walk around in", Deloye's rotunda = the end). **11/25: Ebain's own script replaced the drafts** (Mattias guide,
3 joint pieces, Deloye's A/B/C, Faded, Xylo's fizzle, radio): see HANDOFF section 1. This plan is history now. How it works now: HANDOFF section 1 ("Secret Deloye Lore library"). Still open:
Ebain's song, his real lines (everything in `deloye_script.gd` is DRAFT), Deloye's voice, the shaman hint.
Everything marked DRAFT is a placeholder: Ebain writes the real lines and has the final say on story and characters.

## Ebain's answers (don't re-ask)
- **A super secret easter egg:** hard to find, never on the main route, no objective marker.
- **How you find it:** collect **5 Lost Deloye Lore Pages**, **one per area**: Camp, Trail, Village, Mart, Pass.
- **The entrance:** the **village outhouse**. With all 5 pages, you can **Flush** it: the outhouse spins and drops
  everyone down into the library.
- **Inside:** a **giant library** with **a book floating in the center**. **Pure easter egg:** no fight, no test.
- **Who's there:** **Deloye himself**, who wrote Deloye Lore (the huge book about a universe with almost no lore).
  **His look (Ebain's pictures, 11/24):** messy black hair, grey zip hoodie, wired white earbuds, dark jeans, DC shoes.
  **He floats and twirls in the center** of the library (Ebain). **Vibe:** chill, earbuds in, barely looks up,
  surprised anyone actually read it.
- **Rewards (all four):** a hidden achievement, a secret Scrapbook page, Ebain's Deloye Lore song in the Library
  Soundtrack (once heard), and a gift from Deloye to Xylo.
- **The gift (Ebain 11/24):** the **Deloye Lore Neuralink**: shows what the enemy is about to do next, 15% dodge chance,
  "and maybe something else" (Claude's DRAFT third perk: start fights with 20 meter, "the lore pre-downloads").
- **The entrance, as built:** the outhouse is Asar's file, so (Ebain's pick) a **separate flush chain** appears on the
  outhouse's east side with all 5 pages (village.gd). Same spinning flush.
- **Song:** Ebain makes it later. It plays in the library (AreaMusic).

## 1. The Lost Pages (the hunt)
- 5 small glowing parchment pickups, one per area. **No minimap dot, no objective, no prompt until you're close** (1.5 m).
  Tucked in odd but walkable spots. Suggestions (the builder checks they're reachable):
  Camp: behind the tent, half under a log · Trail: under the troll bridge's far end · Village: behind the outhouse
  (a sneaky nod) or on the throne's back · Mart: in a shelf corner inside the shop · Pass: in a rock crack by the giant.
- Picking one up: a soft whisper/page sound, toast "Lost Page (n/5)", and Xylo reacts with a DRAFT line. Each page has
  a short Deloye Lore snippet you can read in the inventory (DRAFT, about nothing, e.g. "Chapter 4: The rock remained.").
- **Hints, not hand-holding:** Xylo murmurs a DRAFT line when he's the leader within ~8 m of a page ("…I smell
  parchment."). The shaman's fortune can hint that "the lore hides where the goblins go" (DRAFT).
- Pages are saved in `Game.progress` (they carry across playthroughs, like outcomes), so a replay doesn't restart the hunt.
  The inventory shows "Lost Pages n/5" once you have at least one.

## 2. The outhouse flush (the entrance)
- The village outhouse (`village_buildings.gd`, **Asar's file: claimed by Asar right now, coordinate first**).
  With 5/5 pages, interacting shows a new option **"Flush"** (before 5/5 it isn't there at all).
- Flush: a gurgle, the outhouse spins faster and faster (tween its rotation, shake the camera), a big FLUSH sound,
  white fade, then everyone lands in the library in a heap. DRAFT lines from the trio on the way down.

## 3. The library
- New scene `deloye_library.tscn` (+ `deloye_library.gd`, `deloye_script.gd`). A huge round hall: shelves that
  climb up into darkness, spiral stairs and ladders, candles and chandeliers, dust drifting in light beams, a few
  floating books slowly circling.
- **The book in the center:** giant, floating, slowly turning, pages flipping on their own, glowing. Walking up to it
  plays the song at full volume (until then: silence + a soft hum) and shows a DRAFT line.
- **Deloye** stands somewhere in the stacks. Talking: DRAFT lines (he's confused anyone actually read it all), then
  he gives Xylo the gift. Placeholder card until Ebain describes him (then: art, portrait, a CHARS entry with a TTS voice).
- **The gift (DRAFT, Ebain picks):** "Deloye Lore Vol. 0 (Blank)": a trinket, +15% meter gain and immune to
  Lore-Pilled. Or a pure joke item.
- **Leaving:** a door marked EXIT (or flushing back up) returns you to the village next to the outhouse.

## 4. Rewards and wiring
- **Achievement** (`achievements.gd`, secret = shows ??? until earned): "Lore Accurate" (DRAFT name), "Found the
  Deloye Lore library."
- **Scrapbook:** a secret section that only appears once found ("??? " page before that, hint "Flush." DRAFT). Not part of
  the 100 outcome points.
- **Song:** add to `LibraryUI.SONGS` (`deloye_lore`, by Ebain, plays in "a place you shouldn't be") + `Lyrics.TEXT`,
  and an AreaMusic node in the library. Locked in the Library until you hear it there.

## Poly Haven to fetch (tools/fetch_polyhaven.py; skip what's missing)
Bookshelves (tall/old), books and book stacks, lecterns, reading desks and chairs, globe, candles/candelabras,
chandeliers, rugs (`dirty_carpet`, `quatrefoil_jacquard_fabric` already in the repo), wood floor/plank textures,
stone/marble floor, wooden stairs/ladders, an HDRI that's dark and warm (or a plain dark sky).

## Ebain supplies
- **Deloye:** a description first, then art (front/side/back + portrait, green screen like the others).
- **The Deloye Lore song** (`godot/assets/music/deloye_lore.ogg`) + lyrics.
- Optional: a picture of the Lost Page (else a drawn parchment), and real text for the 5 page snippets.

## Testing
A `--shots` tour: give 5 pages (`DEV` / env flag), flush at the outhouse, land in the library, talk to Deloye, get
the gift, check the achievement + Scrapbook unlock, exit. Headless first.
