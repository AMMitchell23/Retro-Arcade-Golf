# Retro Arcade Golf

A fast 2D party golf game with a neon, ASCII-inspired look. SE 353 Software Engineering, Trine University.
Built with **Godot 4.7** (GDScript).

## Open it

1. Unzip `Godot_v4.7.2-stable_win64.exe.zip` and run the Godot exe.
2. In the Project Manager click **Import**, pick this folder's `project.godot`, then **Import & Edit**.
3. Press **F5** to play.

## Controls (shown on screen too, NFR-04)

| Action | Keyboard | Mouse |
| --- | --- | --- |
| Aim (angle) | A / D or Left / Right | move the mouse |
| Power | W / S or Up / Down | scroll wheel |
| Shoot | Space or Enter | left click |
| Back to menu | Esc | |

## What's in this slice (Sprint 2 goal)

| Backlog | What | Where |
| --- | --- | --- |
| PB-01 | Godot project and repo layout | `project.godot`, folders below |
| PB-02 | Main Menu and Play Menu (Local Singleplayer / Local Multiplayer 2 to 4 players) | `scenes/main_menu.tscn`, `scripts/main_menu.gd` |
| PB-03 | Angle and power controls, aim line, power meter | `scripts/level.gd`, `scripts/hud.gd` |
| PB-04 | 2D ball physics and hole detection | `scenes/ball.tscn`, `Cup` node in the level |
| PB-05 | Level 1 with stroke counter | `scenes/levels/level_1.tscn` |
| PB-06 | Neon/ASCII style (start) | `assets/neon_theme.tres`, drawing code in `level.gd` / `ball.gd` |

Local multiplayer is hot-seat and turn-based (FR-16): players share the keyboard and take turns, the others' balls are dimmed.
A results screen (FR-26) ranks players by strokes at the end of the hole.

## Project layout

```
project.godot          project settings (main scene, Game autoload, theme)
assets/neon_theme.tres buttons, panels, monospace font
scenes/main_menu.tscn  Main Menu + Play Menu
scenes/ball.tscn       RigidBody2D golf ball
scenes/hud.tscn        in-game HUD and results panel
scenes/levels/         one scene per hole
scripts/game.gd        global state: players, colors, level list (autoload "Game")
scripts/level.gd       builds the course and runs the turns
scripts/ball.gd        ball drawing, launch and stop
scripts/hud.gd         HUD text, messages, results
```

## Making a new level

1. Duplicate `scenes/levels/level_1.tscn` as `level_2.tscn`.
2. Select the root node and edit **Ground Points** (the top edge of the ground, left to right),
   **Tee Position**, **Cup Position** (put a 40 px wide dip in the ground there) and **Par**.
3. Add the path to `LEVELS` in `scripts/game.gd`.

## Next up (from the SRS)

- Roulette wheel modifier after the shot is planned (FR-18, FR-19): hook is marked `TODO` in `level.gd` `_shoot()`.
- Shot clock and skipping a turn when it runs out (FR-22, FR-23).
- Scorecard between holes and more levels (FR-25, FR-13).
- Player names and colors picked in a lobby (FR-05, FR-06).
