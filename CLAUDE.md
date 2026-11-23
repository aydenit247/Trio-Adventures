# Instructions for any AI working on this repo

Two people work on Trio Adventures, each with their own Claude: **Ebain** (Ayden, the creator) and his friend.
Ebain also uses a **Grok** assistant (tag `grok`) for documentation hygiene and light tasks. These rules apply to it
too. The AIs can't talk to each other directly. **`COLLAB.md` is how you coordinate.**

**Hard rules — every session, before writing any code, no exceptions:**
- **Pull, then read `COLLAB.md` and `TIPS.md`.** Never work from an old copy. If you've been working a while, pull and re-read before
  claiming anything new.
- **No claim, no code.** If your task and its files aren't on the board under your name, and that claim isn't pushed,
  don't touch them.
- **Push the claim straight away.** If the push is rejected, the other Claude pushed first: pull, re-read the board,
  and if they claimed the same thing, pick something else and tell your person.
- **Never edit a file someone else has claimed.** If you truly need a change there, write a request in the Log and
  tell your person, so the two of you can sort it out.

Full steps:

1. **Before touching anything:** `git fetch origin && git checkout foundation && git pull --rebase origin foundation`,
   then read `COLLAB.md` (the board, claimed files, and the latest log entries), `TIPS.md` (gotchas, tricks, and answers
   our people already gave; add a line when you learn something) and `HANDOFF.md` (how the project works).
2. **Claim before you build.** Add your task to the board in `COLLAB.md` with the files you'll change, commit just
   that edit straight to `foundation`, and push it right away so the other Claude sees it. (Board edits in
   `COLLAB.md` always go straight to `foundation`; code goes on your branch.)
3. **Work on your own branch** (`ebain/<task>`, `asar/<task>` or `grok/<task>`), not straight on `foundation`. Small, frequent commits.
4. **Before merging:** `git pull --rebase origin foundation` onto your branch, fix any conflicts, run the area's test
   tour (see "Testing" in HANDOFF.md) to make sure nothing broke, then merge into `foundation`, push `foundation`, and push
   `foundation:main` (that's what makes it live).
5. **When you finish or stop:** move your task to Done (or leave a note on where it stands), unclaim the files, and add
   a short entry to the Log in `COLLAB.md`: what changed, anything the other person needs to know. Update `HANDOFF.md`
   if you changed how something works.

**Grok's lane:** docs and light tasks. That means tidying the `.md` files (typos, broken links, stale section numbers,
outdated facts, trimming old Log entries into a short summary), keeping `HANDOFF.md`'s code map in sync with the code,
`ASSETS_NEEDED.md`/`VOICE_LINES.md` upkeep, and small non-code chores. Grok claims like everyone else, uses tag `[grok]`
on the board and in TIPS.md, and leaves code changes, especially in the shared hot spots, to the Claudes unless Ebain
asks. When tidying, keep each entry's meaning. Don't delete someone's open request or unanswered question; never
edit `CLAUDE.md` (it's the rulebook).

**Stale claims:** a claim with no commits and no Log entry for 3 days can be taken over, but only after writing in
the Log that you're taking it, and telling your person.

**Changing these rules:** `CLAUDE.md` is the rulebook, not the board. Don't edit it during normal work. Change it only
when Ebain and his friend agree to a new rule, and say so in the Log.

Shared hot spots — `godot/scripts/level.gd`, `godot/scripts/game.gd`, `godot/scripts/combat/*`, `godot/scripts/dialogue.gd`,
`godot/project.godot`: claim them for as short a time as possible, and say in the Log what you changed in them.

Creative rules (from Ebain): his dialogue wording is used verbatim (tag `# Ebain`), drafts are tagged `# DRAFT`,
and the tone is goofy Baldur's Gate 3. Ebain has the final say on story and characters.

Commit messages end with your own session's attribution lines, if your setup gives you some.
