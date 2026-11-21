# Crash Reports

Reports from the game when it **crashes, freezes, or gets force-closed**. Each one is a Markdown file that explains what
probably happened, what the player was doing (area, dialogue line, fight, menu), the last ~80 things that happened,
every engine/script error from that session, and the PC's specs.

## Where the game saves them
The game writes reports itself (`godot/scripts/crash_reporter.gd`). Nothing is uploaded anywhere.
- **Windows download:** a `Crash Reports` folder right next to `TrioAdventures.exe`.
- Running from the editor (or if the game folder can't be written to): `%APPDATA%\Godot\app_userdata\Trio Adventures\Crash Reports`
  (Linux: `~/.local/share/godot/app_userdata/Trio Adventures/Crash Reports`).

When does it write one?
- **Freeze:** nothing has been drawn for 12 seconds. If the game comes back, the report gets an "it came back after N s" note
  (a long stall, not a hard freeze). If it never comes back and you close it with Task Manager, the next launch adds
  "it never came back" plus the end of Godot's log.
- **Crash / force-close:** the game didn't shut down normally. It's detected on the next launch, and the game shows a
  message saying where the report went.

## Getting them into this folder
Give the `.md` file to your Claude (or ask it to grab it from the game's `Crash Reports` folder if it can reach your
computer). It goes here as `Crash Reports/<who> <date> <Freeze|Crash>.md`, gets committed, and whoever fixes it adds a line
under it saying what the cause was.

## Fixed / explained
_(newest first: report file → cause → fix)_
