<p align="center"><img src="branding/logo-chill.svg" width="220" alt="xboxmericavi"></p>

# xboxmericavi

**A launcher fork built on Codec's CGBJ code** ([Pavl3000/cgbj-fork](https://github.com/Pavl3000/cgbj-fork), the surviving copy of codec-d/cool_fox at `f4b48ad`), which is itself [avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX) with NVIDIA work on top. All of it goes back to [VIctory](https://github.com/Marvisak/VIctory) by Marvisak.
Runs the Xbox Series build of Grand Theft Auto VI natively on Windows from files you supply yourself.

> **No game files, code or assets are in this repository.** You need your own copy of the game.
> Not affiliated with or endorsed by Rockstar Games or Take-Two Interactive.

## Status (2026-11-27)

xboxmericavi now runs on the CGBJ code base instead of victory-fork. CGBJ's build is reported at about 25 fps on PortWatch (on a much faster PC than ours); this fork has yet to be measured on our test PC.

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

The launcher remembers your path (`%LOCALAPPDATA%\victory\xboxmericavi-launcher.json`). `tools\play.cmd` still works on its own (set `GAME_EXE` or edit the line at their top).

## One preset

`tools\play.cmd` (what the launcher's **PLAY** runs; **PLAY NOW** runs `tools\playnow.cmd`, the same without a build): the settings of Codec's `Play-VIctory.cmd pareto-residency` (kept in this repository), the game on the **Series S** profile (fewer pixels, the fastest), high CPU priority, a log, the console and the live stats window.

## What this fork adds

- **GUI launcher** (`tools/launcher.ps1`): game path check, one-click build and start, the last run's average fps, live stats.
- **Console** (`tools/console.ps1`), opened with the game: one line a second (fps, where the frame's time goes, draws, pipelines still being made), shader progress, warnings in yellow, errors in red.
- **Frame rate box in the corner** (`fpsbox.rs` and `stats.rs` from victory-fork): fps, CPU, GPU, VRAM, RAM; `VICTORY_FPS_COUNTER=0` hides it, `=fps` shows the rate alone.
- **Live stats window** (`tools/stats.ps1`): fps, frame-time graph, per-frame breakdown, CSV export. Loading screens and menus (under 1,000 draws) are left out of the averages.
- **Own icon in `victory.exe` and its window** (`branding/icon.ico`, put in by `apps/victory/build.rs` as a resource, no extra tool or crate).

Everything else is CGBJ's, AvatarManz's and upstream's work; see `docs/cgbj-fork-README.md` and the rest of `docs/`.

## Known issues

- The first launch after a build is slow and blurry until the driver has made its pipelines (a few minutes); measure on the second launch.
- Tested upstream on an RX 7900 XTX and an RTX 5090; the 8-thread i7-9700F is the limit on our PC.

## Credits

- **Codec (codec-d, CGBJ)**: the code base of this fork, NVIDIA Wave32 lowering, Series S two-plane fix, residency budgets. Surviving copy: [Pavl3000/cgbj-fork](https://github.com/Pavl3000/cgbj-fork) by Pavel.
- [AvatarManz / VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX): the AMD speed work CGBJ builds on, bringing together [DexNom](https://github.com/DexNom/VIctory) and [Belobug](https://github.com/Belobug/VIctory-Belobug-AMD).
- [victory-fork](https://github.com/fxceless/victory-fork) by hyphennn and contributors.
- [VIctory](https://github.com/Marvisak/VIctory) by Marvisak and contributors: the base of everything (GPL-3.0-or-later).
- This fork's changes were made with [Claude](https://claude.ai). License: GPL-3.0-or-later, see `LICENSE`.
