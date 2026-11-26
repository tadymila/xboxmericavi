<p align="center"><img src="branding/logo-chill.svg" width="220" alt="xboxmericavi"></p>

# xboxmericavi

**A performance-focused fork of [victory-fork](https://github.com/fxceless/victory-fork) (hyphennn), itself a fork of [VIctory](https://github.com/Marvisak/VIctory) by Marvisak.**
Runs the Xbox Series build of Grand Theft Auto VI natively on Windows from files you supply yourself.

> **No game files, code or assets are in this repository.** You need your own copy of the game.
> Not affiliated with or endorsed by Rockstar Games or Take-Two Interactive.

## Status (2026-11-25)

Not playable yet, but the prologue is reachable, controllable and lit: Lucia, cellmates, the cell and the yard outside render.
Up to date with victory-fork `main` (a803c87: skin and hair colour fix, texture catch-up budget).

Tested on: **Intel i7-9700F** (8C/8T, no Zen 2 instructions, emulated), **RTX 5070 Ti 16 GB**, 64 GB RAM, Windows 11, game 1.0.2.1 (Series X profile).

| | upstream defaults | upstream fast switches | xboxmericavi MAX | **xboxmericavi TURBO** |
|---|---|---|---|---|
| Prologue (cell / corridor), ms per frame | 1200–1700 | 380–690 | 150–325 ¹ | **200–230** |
| Frame rate in the world | ~1 fps | ~1.5–3 fps | 3–6.5 fps ¹ | **4–5 fps** |

¹ MAX: 150–225 ms in earlier runs, 290–325 ms on a first run (shaders still compiling). TURBO: warm shader cache, 4,000–6,500 draws/frame.
Every build change makes the next launch translate all ~3,000 shaders again: **measure on the second launch.**

<img width="2467" height="1390" alt="Screenshot_1" src="https://github.com/user-attachments/assets/85913f19-714a-45b1-bacf-2df74e6d6e7a" />

*Prologue, TURBO: 212.9 ms/frame (~5 fps), 4378 draws/frame, i7-9700F + RTX 5070 Ti.*

<img width="1143" height="662" alt="Live stats window" src="https://github.com/user-attachments/assets/a7a8be17-a72e-4a06-89f0-7160e6a1f43e" />

*The live stats window: where each frame's time goes.*

## Quick start

1. Install Rust and the C++ build tools (PowerShell, one at a time):
   `winget install Rustlang.Rustup` and `winget install Microsoft.VisualStudio.2022.BuildTools` (pick the **Desktop development with C++** workload).
2. Download or clone this repository (no game files in it).
3. Double-click **`xboxmericavi-launcher.cmd`**:
   - **Browse...** to your own `game_scarlett_master.exe`
   - pick a preset (**TURBO** recommended)
   - **BUILD & START**. The first build takes a few minutes; the first launch translates the shaders.
4. Keyboard works as a pad: WASD move, IJKL camera, Enter = A.

The launcher remembers your path and preset (`%LOCALAPPDATA%\victory\xboxmericavi-launcher.json`). The `.cmd` presets still work on their own (set `GAME_EXE` or edit the line at their top).

## Presets

| Preset | File | What it sets | When |
|---|---|---|---|
| **TURBO** | `xboxmericavi-turbo.cmd` | MAX + `VICTORY_CARD_REHASH_RUNS=1`, `VICTORY_LATE_WAIT_LISTS=256`, high CPU priority, live stats window | default, fastest |
| MAX | `xboxmericavi.cmd` | `VICTORY_RELAY=1`, `VICTORY_LATE_WAIT=3`, `VICTORY_WIDE_BACK=1`, card buffers 1024 MB, texture budget 64 MB / 80 ms, joined copies | if TURBO misbehaves |
| STABLE | `xboxmericavi-stable.cmd` | no relay / late wait | flicker or crashes |

## What this fork adds

- **Texture staging budget per frame** (64 MB / 80 ms in the presets; `VICTORY_TEXTURE_FRAME_MB`/`_MS` still accepted as aliases of upstream's `VICTORY_TEXTURE_STAGE_MB`/`_MS`). On an 8-thread CPU the texture pass took 800–1200 ms of every world frame; now ~17 ms.
- **Pipeline workers use every logical core** (2..16 instead of 2..8): first-run pipeline queues drain about twice as fast.
- **TURBO preset**: card hash passes joined into runs, 256 lists in flight, high CPU priority.
- **Live stats window** (`tools/stats.ps1`): fps, frame-time graph, per-frame breakdown, CSV export. Loading screens and menus (under 1,000 draws) are left out of the averages.
- **GUI launcher** (`tools/launcher.ps1`).
- **Relay timing split** in the log (`xboxmericavi relay split per frame: fetch ... CPU merge ... rest ...`).
- **Mesh PSV string fix** from victory-fork #12.
- **AMD-only CPU instructions patched in place on Intel** (from avatarmanz/VIctory-7900XTX, on by default): the frame wait's `monitorx`/`mwaitx` become `nop`/`pause` and the title's `clzero` loops jump to the same loop with plain stores, so they stop raising exceptions (hundreds of thousands a second on an Intel CPU). `VICTORY_PATCH_WAITS=0` / `VICTORY_PATCH_CLZERO=0` emulate them as before.
- **TURBO uses upstream's newest speed switches** (victory-fork d510ee4): `ASYNC_SUBMIT`, `QUEUE2`, `JOIN_PARTS`, `BACK_OWN_VIEW`, `INDIRECT_WINDOW` + `INDIRECT_GATHER`, `COPY_PLAIN`.
- Experiment, **off by default**: `VICTORY_DESC_AS_DATA=1` (a descriptor read as data gets its table offset; 6 more pixel shaders translate).

## Findings (what limits the speed)

Measured with the relay timing split on i7-9700F + RTX 5070 Ti:

- The card is only 60–70 % busy. A frame is a chain: the card runs the work (~110 ms waiting for it to finish and fetch results back), the CPU merges ~1,200 pieces of 64 KiB back into game memory (~45–60 ms, kernel calls), then the game may go on.
- Faster CPUs only shorten the merge, faster GPUs only part of the wait: people with much faster CPUs also see ~5 fps. The next real step is architectural (copy back only what the game reads, when it reads it).

Tested and **not recommended**:

| Switch | Result |
|---|---|
| `VICTORY_WIDE_MERGE=1` | cell walls disappear (~2,500 draws/frame) |
| `VICTORY_KEEP_SNAPSHOTS=1` | turns the relay off: 285–365 ms instead of 200–230 |
| `VICTORY_RELAY=2` | 280–317 ms: waits for title memory reads rise from 79 to 137 ms |
| texture budget 128 MB / 120 ms | cell loads without pausing, but the picture looked worse |

## Known issues

- Cell walls / ceiling are missing in some launches and fine in others (nondeterministic, see victory-fork #62). Relaunch if the cell is see-through.
- Shadowed areas are dark: the game's ray-traced lighting does not run yet (`docs/fork-ray-tracing.md`).
- ~320 draws per frame are dropped (shaders that do not translate yet and an unknown console pipeline-creation method, device slot 0x218).
- White blotches on clothing and blue blocks that vanish after a few seconds (textures still streaming in).
- The intro video flickers a little on 144 Hz monitors; `--console series-s` does not get past the start screen; `VICTORY_WAVE_WIDE=1` can hang NVIDIA GPUs.

## Credits

- [VIctory](https://github.com/Marvisak/VIctory) by Marvisak and contributors – the base of everything (GPL-3.0-or-later).
- [victory-fork](https://github.com/fxceless/victory-fork) by hyphennn and contributors – rendering and speed fixes this fork builds on.
- This fork's changes were made with [Claude](https://claude.ai). License: GPL-3.0-or-later, see `LICENSE`.

For how VIctory works (architecture, commands, debugging, asset policy), see the upstream documentation: [victory-fork README](https://github.com/fxceless/victory-fork#readme), [VIctory README](https://github.com/Marvisak/VIctory#readme) and `docs/` in this repository.
