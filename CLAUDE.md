# Instructions for any Claude working on this repo

Two people work on Trio Adventures, each with their own Claude: **Ebain** (Ayden, the creator) and his friend.
The two Claudes can't talk to each other directly. **`COLLAB.md` is how you coordinate.** Follow this every session:

1. **Before touching anything:** `git fetch origin && git checkout foundation && git pull --rebase origin foundation`,
   then read `COLLAB.md` (the board, claimed files, and the latest log entries) and `HANDOFF.md` (how the project works).
2. **Claim before you build.** Add your task to the board in `COLLAB.md` with the files you'll change, commit just
   that edit, and push it right away so the other Claude sees it. Don't start work on files someone else has claimed.
3. **Work on your own branch** (`ebain/<task>` or `friend/<task>`), not straight on `foundation`. Small, frequent commits.
4. **Before merging:** `git pull --rebase origin foundation` onto your branch, fix any conflicts, run the area's test
   tour (see HANDOFF.md 6b) to make sure nothing broke, then merge into `foundation`, push `foundation`, and push
   `foundation:main` (that's what makes it live).
5. **When you finish or stop:** move your task to Done (or leave a note on where it stands), unclaim the files, and add
   a short entry to the Log in `COLLAB.md`: what changed, anything the other person needs to know. Update `HANDOFF.md`
   if you changed how something works.

Shared hot spots — `godot/scripts/level.gd`, `godot/scripts/game.gd`, `godot/scripts/combat/*`, `godot/scripts/dialogue.gd`,
`godot/project.godot`: claim them for as short a time as possible, and say in the Log what you changed in them.

Creative rules (from Ebain): his dialogue wording is used verbatim (tag `# Ebain`), drafts are tagged `# DRAFT`,
and the tone is goofy Baldur's Gate 3. Ebain has the final say on story and characters.

Commit messages end with your own session's attribution lines, if your setup gives you some.
