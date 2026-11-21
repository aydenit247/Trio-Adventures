# Crash: Big Thumbs bar fight (Asar, 2026-11-21 15:26)

**What Asar saw:** the game closed by itself during the Big Thumbs bouncer fight, right as Lykor's Hair Flip hit him at very
low HP. Asar says it's "the same exact spot" as an earlier crash.

## What the game's crash data said
From `%APPDATA%\Godot\app_userdata\Trio Adventures\crash\` (the session marker was still there, so it didn't quit normally):
- Fight `bouncer` started at 0:47. The last save of state was at 4:31, still in the fight. No dialogue or menu was open.
- **No script errors and no freeze**: the 12 s freeze watchdog never fired. The process just died.
- Settings: voices on, graphics High. Party level 1, no gear equipped.
- (The reporter didn't log individual fight moves yet. It does now: "Fight — …" breadcrumbs.)

## What the Windows crash dumps say
`%LOCALAPPDATA%\CrashDumps\TrioAdventures.exe.*.dmp`, 4 from today (08:55, 13:18, 15:01, 15:26), parsed by hand (no symbols):

| Dump | Exception | Crashing thread |
|---|---|---|
| 22108 (08:55) | 0xC0000374 heap corruption | worker thread #13 |
| 23752 (13:18) | 0xC0000005 access violation (read) in TrioAdventures.exe+0x2784040 | worker thread #20 |
| 17484 (15:01) | 0xC0000374 heap corruption | worker thread #20 |
| 5128 (15:26, this one) | 0xC0000374 heap corruption | worker thread #7 |

- All four are on **background worker threads**, never the main thread, and the stacks are mostly engine code with **GPU shader
  compiler modules** on them: NVIDIA `nvgpucomp64.dll`/`nvoglv64.dll` and Intel `igc64.dll` (the PC has an RTX 4070 + Intel iGPU).
- Loaded but **not** on the crashing stacks: Windows TTS (`Windows.Media.Speech`, `MSTTSEngine_OneCore`, MediaPlayer).
- Also loaded: **Overwolf's Vulkan overlay** (`ow-graphics-vulkan.dll`), injected into the game.

**Best guess:** the Vulkan driver crashes while Godot compiles a shader/pipeline on a worker thread. A new visual effect
showing up for the first time triggers that (Hair Flip sparkle, the knockdown/second-wind flash), which explains "same spot
every time". Not a game-script bug. Overwolf's overlay and the dual-GPU setup are the usual suspects for this kind of crash.

## Trying next
1. **DirectX 12 instead of Vulkan:** `Play with DirectX 12.bat` in Asar's game folder (`TrioAdventures.exe --rendering-driver d3d12`).
   If the bouncer fight stops crashing, switch the project to D3D12 on Windows (`rendering/rendering_device/driver.windows="d3d12"`).
2. If it still crashes: turn off Overwolf's in-game overlay, update the NVIDIA driver, and make sure Windows runs the game
   on the NVIDIA GPU (Settings → Display → Graphics → TrioAdventures.exe → High performance).

## Status
Open, waiting on Asar's DirectX 12 test.
