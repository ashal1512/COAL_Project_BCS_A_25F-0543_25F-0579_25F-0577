# Super Mario Engine — 16-bit x86 Assembly

A single-level Super Mario-style platform game written in 16-bit x86 assembly for DOS. The project is assembled into a DOS `.COM` executable with NASM and uses BIOS video services together with direct VGA Mode 13h framebuffer access.

**Course:** CS401 — Computer Organization and Assembly Language (COAL) Lab Semester Project  
**Institution:** FAST-NUCES, Chiniot-Faisalabad Campus

---

## Table of contents

- [Project overview](#project-overview)
- [Features](#features)
- [Controls](#controls)
- [Game rules and scoring](#game-rules-and-scoring)
- [Technical design](#technical-design)
- [Repository structure](#repository-structure)
- [Requirements](#requirements)
- [Build instructions](#build-instructions)
- [Run the game](#run-the-game)
- [Troubleshooting](#troubleshooting)
- [Current scope and limitations](#current-scope-and-limitations)
- [Team members](#team-members)

## Project overview

The project implements a side-scrolling platform game in 16-bit real-mode assembly. It starts in a title menu, runs a game loop driven by the hardware timer, draws the world to an off-screen buffer, and copies that buffer to VGA memory.

The executable is a DOS COM program. The source uses `ORG 0x100`, the standard load offset for a DOS COM program. The graphics code selects BIOS video mode `0x13`, which provides a 320 × 200, 256-colour display.

The game currently contains one predefined World 1-1 map. Its tile map is 64 columns by 12 rows, with each tile representing a 16 × 16 pixel area.

## Features

### Gameplay

- Horizontal movement with acceleration, friction, and separate walking and running speed limits.
- Jumping with gravity, variable jump height, and collision checks against the tile map.
- Small and Super forms. Collecting the question-block mushroom changes Mario to the larger form and increases the collision height.
- Goomba and Koopa enemies, including stomp behaviour, Koopa shells, and moving-shell interactions.
- Breakable bricks for Super Mario, question blocks, coins, and a mushroom power-up.
- Side-scrolling camera movement that follows the player through the level.
- Lives, a countdown timer, temporary invulnerability after taking damage, and title, pause, death, level-complete, and game-over states.

### Graphics and interface

- 320 × 200 VGA Mode 13h output.
- An off-screen 64,000-byte framebuffer followed by a copy to VGA memory.
- A tile renderer and 16 × 16 indexed-colour sprite data stored in the assembly source.
- Sprite drawing supports horizontal flipping and double-height rendering for the Super form.
- BIOS 8 × 8 font rendering for text, including the score and HUD.
- HUD display for score, coins, world, remaining time, lives, and health.

### Scoring

- Coins add 200 points each.
- Collecting 100 coins awards an extra life and resets the coin counter.
- Enemy stomps award increasing points in a combo sequence; after the combo reaches its final tier, further stomps can award an extra life.
- The flagpole awards points based on the height at which the player reaches it.
- Remaining time is converted into a completion bonus.
- The score is stored as a 32-bit value and capped at 999,999 for the six-digit HUD display.

## Controls

| Key | Action |
|---|---|
| Left Arrow | Move left |
| Right Arrow | Move right |
| Space | Jump |
| Left Shift | Run |
| P | Pause or resume |
| Up / Down | Move the title-menu selection |
| Enter | Select a title-menu option; continue from the completion or game-over screen |
| Esc | Exit from the title screen, or return to the title screen while playing/paused |

### Development shortcuts

Two extra keys are present in the playing state for testing:

- `T`: set the remaining game time to 5.
- `C`: set the coin counter to 99, so the next coin can test the extra-life behaviour.

These are testing shortcuts, not normal gameplay objectives.

## Game rules and scoring

Mario loses a life after the death sequence completes. Falling below the level also triggers the death sequence. When the player has the Super form, a side collision removes the power-up first and grants a short invulnerability period; a later hit can cause a life loss.

Goombas are defeated by jumping on them. Koopa enemies enter a shell state when stomped; the shell can then be kicked and can hit other active enemies. The mushroom is released from its question block, moves along the level, and upgrades Mario when collected.

The level timer is updated using the chained hardware timer interrupt. The source counts 18 timer ticks for each displayed second, so the in-game countdown is an approximation of real seconds.

## Technical design

### Program entry and memory model

`src/mario.asm` is the main assembly file. It defines the constants, game variables, tile map, sprite bitmaps, and entry point. It includes the other three assembly modules in this order:

1. `src/gfx.asm`
2. `src/phys.asm`
3. `src/game.asm`

The program is assembled as a flat binary with NASM's `-f bin` output format. No linker is used. The resulting `MARIO.COM` file is loaded by DOS at offset `0x100`.

### Graphics pipeline

The program selects BIOS video mode `0x13`. Rendering functions write to an off-screen buffer in a separate segment. At the end of each frame, the `flip` routine copies 32,000 words (64,000 bytes) to VGA memory at `A000:0000`.

The tile map is held in `orig_map`; `level_map` is the mutable copy used during play. This allows blocks and collected coins to be changed without modifying the original level layout.

### Input and timing

The physics module installs custom handlers for interrupt 9 (keyboard) and interrupt 8 (timer). The keyboard handler records make/break states in `key_state`. The timer handler increments the frame tick counter and chains to the previous timer handler. When the game exits, the original interrupt vectors are restored.

### Physics and collision

Horizontal and vertical movement use 8.8 fixed-point values. The high byte represents the integer component and the low byte stores the fractional component. Movement is updated each frame, with collision checks against solid tile IDs 1 through 10.

The camera follows Mario after he passes the screen's horizontal midpoint and stops at the end of the map.

### Game state

The game state byte selects the active screen/logic routine:

| State | Purpose |
|---|---|
| Title | Start or exit the game |
| Playing | Update movement, enemies, items, timer, camera, and gameplay rendering |
| Paused | Display the pause screen |
| Dying | Run the death animation and process the lost life |
| Life lost | Show the remaining lives before resuming |
| Win sequence | Run the flagpole sequence and calculate the time bonus |
| Level complete | Show the level summary |
| Game over | Show the final score |

## Repository structure

```text
.
├── README.md
├── build.bat
└── src
    ├── mario.asm
    ├── gfx.asm
    ├── phys.asm
    └── game.asm
```

| File | Responsibility |
|---|---|
| `src/mario.asm` | COM entry point, constants, game variables, map, sprite data, and module includes |
| `src/gfx.asm` | Framebuffer operations, rectangles, sprites, text, tile-map helpers, and map rendering |
| `src/phys.asm` | Keyboard/timer interrupt handlers, frame timing, camera, fixed-point movement, and collision routines |
| `src/game.asm` | Score and coin handling, HUD, blocks, mushroom, enemies, life handling, and game-state routines |
| `build.bat` | Windows build script that invokes NASM |

`MARIO.COM` is generated by the build process and is not required to be stored in the repository.

## Requirements

- **NASM** (Netwide Assembler), available on your system's `PATH`.
- **DOS or a DOS emulator** to run the resulting COM program. DOSBox or DOSBox-X can be used on modern Windows, Linux, or macOS systems.

The game uses BIOS interrupts, real-mode interrupt vectors, and VGA memory. It is not a native 32-bit or 64-bit Windows application and is not expected to run directly as a modern Windows executable.

## Build instructions

Run the build from the repository root.

### Windows

1. Install NASM and make sure `nasm.exe` is available on `PATH`.
2. Open a terminal in the project folder.
3. Run:

```bat
build.bat
```

The script creates `MARIO.COM` in the repository root. It prints an error and returns a non-zero exit code if NASM is missing or assembly fails.

### Linux

Install NASM using your distribution's package manager, then run:

```bash
nasm -f bin -o MARIO.COM src/mario.asm
```

If you run NASM from outside the repository root, change to the project folder first because the main source includes files by their `src/...` paths.

## Run the game

In DOSBox, mount the project folder as a DOS drive and start the COM program:

```text
mount c /path/to/COAL_Project_BCS_A_25F-0543_25F-0579_25F-0577
c:
MARIO.COM
```

Replace the example host path with the actual location of your cloned repository. On Windows, the mount path will normally look like `C:\Users\YourName\path\to\project`.

To exit, use the Exit option on the title screen or press Esc from the title screen. The game restores the original keyboard and timer interrupt vectors before returning to DOS.

## Troubleshooting

**`nasm` is not recognized**  
Install NASM and add its installation directory to the system `PATH`. Open a new terminal after changing the environment variable.

**NASM cannot find an included assembly file**  
Run the build from the repository root. The source includes the modules using paths such as `src/gfx.asm`.

**The COM file builds but does not start in Windows**  
A DOS COM executable requires a DOS environment. Run it inside DOSBox/DOSBox-X or another compatible DOS environment.

**The screen remains blank or behaves incorrectly**  
Use a DOS emulator with VGA Mode 13h support. The project writes directly to VGA memory and uses BIOS services available in a DOS-compatible environment.

## Current scope and limitations

- The repository contains one predefined level; there is no level editor or level-loading system.
- The map, sprites, palette indices, and game constants are assembled into the executable.
- Graphics are pixel-art sprites drawn from data in `src/mario.asm`; no external asset files are needed.
- The timer is based on 18 hardware timer ticks per displayed second, which is an approximation.
- The `T` and `C` gameplay shortcuts are retained for development/testing.

## Team members

- **Ashal Haider (`25F-0543`)** — Main program entry, constants, level map, sprite data, and graphics/tile engine (`src/mario.asm`, `src/gfx.asm`, `build.bat`).
- **Hamza Mansoor (`25F-0579`)** — Keyboard interrupt handling, timer chaining, camera scrolling, 8.8 fixed-point physics, and collisions (`src/phys.asm`).
- **Hassan Nadeem (`25F-0577`)** — Enemy and shell logic, block/mushroom mechanics, scoring, HUD, and game-state routines (`src/game.asm`).

---

This is an academic semester project for learning and demonstrating low-level x86 assembly concepts.
