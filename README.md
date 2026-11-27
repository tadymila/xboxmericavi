<p align="center"><img src="branding/logo-chill.svg" width="220" alt="xboxmericavi"></p>

# xboxmericavi

**A launcher fork built on [avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX)** (its `main` of 26 November 2026, which already takes in the parts of Codec's CGBJ code, [Pavl3000/cgbj-fork](https://github.com/Pavl3000/cgbj-fork), that are safe on every card). All of it goes back to [VIctory](https://github.com/Marvisak/VIctory) by Marvisak.
Runs the Xbox Series build of Grand Theft Auto VI natively on Windows from files you supply yourself.

> **No game files, code or assets are in this repository.** You need your own copy of the game.
> Not affiliated with or endorsed by Rockstar Games or Take-Two Interactive.

## Status (2026-11-27)

xboxmericavi runs on AvatarManz's newest code with its renderer patches 1, 2, 5, 6 and 7 switched on and the game on the Series X profile drawn to a 1080p output. AvatarManz measures about 40-45 ms a frame (22-25 fps) on his PC (RX 7900 XTX, i9-12900K). On ours, the earlier CGBJ-based build ran at 110-125 ms (8-9 fps), about twice the speed of the victory-fork-based one; this build has yet to be measured here.

Tested on: **Intel i7-9700F** (8C/8T, no Zen 2 instructions, emulated), **RTX 5070 Ti 16 GB**, 64 GB RAM, Windows 11, game 1.0.2.1.

The earlier, victory-fork-based xboxmericavi (4–6 fps on this PC) is in this repository's history up to commit `909bbb4`.

<img width="2529" height="1414" alt="image" src="https://github.com/user-attachments/assets/99656005-9257-4621-8d1c-0b30ab36d7e9" />

*Lucia's cell with the yard outside, earlier victory-fork-based TURBO: 252 ms/frame (4 fps), 4898 draws/frame, i7-9700F + RTX 5070 Ti.*

<img width="2467" height="1390" alt="Screenshot_1" src="https://github.com/user-attachments/assets/85913f19-714a-45b1-bacf-2df74e6d6e7a" />

*Prologue, earlier victory-fork-based TURBO: 212.9 ms/frame (~5 fps), 4378 draws/frame.*

<img width="1143" height="662" alt="Live stats window" src="https://github.com/user-attachments/assets/a7a8be17-a72e-4a06-89f0-7160e6a1f43e" />

*The live stats window: where each frame's time goes.*

## Quick start

1. Install Rust and the C++ build tools (PowerShell, one at a time):
   `winget install Rustlang.Rustup` and `winget install Microsoft.VisualStudio.2022.BuildTools` (pick the **Desktop development with C++** workload).
2. Download or clone this repository (no game files in it).
3. Double-click **`xboxmericavi-launcher.cmd`**:
   - **Browse...** to your own `game_scarlett_master.exe`
   - **PLAY**. The first build takes a few minutes; the first launch translates the shaders and lets the driver make its pipelines (slow and blurry for a few minutes).
4. Keyboard works as a pad: WASD move, IJKL camera, Enter = A.

The launcher remembers your path (`%LOCALAPPDATA%\victory\xboxmericavi-launcher.json`). `xboxmericavi.cmd` still works on its own (set `GAME_EXE` or edit the line at their top).

## One preset

`xboxmericavi.cmd` (what the launcher's **PLAY** runs): the settings of AvatarManz's `scripts\play.ps1`, his renderer patches 1, 2, 5, 6 and 7 (`VICTORY_PORT_CONSTANTS`, `_DESCRIPTORS`, `_CBV`, `_GUARD`, `_JOURNAL`; off by default upstream while he tests them), the **Series X** profile drawn to **1920x1080** (`VICTORY_OUTPUT`), high CPU priority, a log, the console and the live stats window. If it crashes, remove the `VICTORY_PORT_*` lines first.

## What this fork adds

- **GUI launcher** (`tools/launcher.ps1`): game path check, one-click build and start, the last run's average fps, live stats.
- **Console** (`tools/console.ps1`), opened with the game: one line a second (fps, where the frame's time goes, draws, pipelines still being made), shader progress, warnings in yellow, errors in red.
- **Frame rate box in the corner** (`fpsbox.rs` and `stats.rs` from victory-fork): fps, CPU, GPU, VRAM, RAM; `VICTORY_FPS_COUNTER=0` hides it, `=fps` shows the rate alone.
- **Live stats window** (`tools/stats.ps1`): fps, frame-time graph, per-frame breakdown, CSV export. Loading screens and menus (under 1,000 draws) are left out of the averages.
- **Own icon in `victory.exe` and its window** (`branding/icon.ico`, put in by `apps/victory/build.rs` as a resource, no extra tool or crate).

Everything else is AvatarManz's, CGBJ's and upstream's work; see `docs/` (`docs/cgbj-fork-README.md` is the CGBJ copy's README).

## Known issues

- The first launch after a build is slow and blurry until the driver has made its pipelines (a few minutes); measure on the second launch.
- Tested upstream on an RX 7900 XTX and an RTX 5090; the 8-thread i7-9700F is the limit on our PC.

## Credits

- [AvatarManz / VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX): the code base of this fork, its speed work and renderer patches, bringing together [DexNom](https://github.com/DexNom/VIctory), [Belobug](https://github.com/Belobug/VIctory-Belobug-AMD) and Codec's CGBJ work.
- **Codec (codec-d, CGBJ)**: NVIDIA and Series S work, residency budgets. Surviving copy: [Pavl3000/cgbj-fork](https://github.com/Pavl3000/cgbj-fork) by Pavel.
- [victory-fork](https://github.com/fxceless/victory-fork) by hyphennn and contributors (also the frame rate box in the corner).
- [VIctory](https://github.com/Marvisak/VIctory) by Marvisak and contributors: the base of everything (GPL-3.0-or-later).
- This fork's changes were made with [Claude](https://claude.ai). License: GPL-3.0-or-later, see `LICENSE`.
