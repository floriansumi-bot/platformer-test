# Platformer

A 2D action-platformer built in Godot 4.6 (GDScript). Multiple levels, a set of enemies, and several boss fights.

## Features

- Several hand-built levels (`src/levels/`)
- Enemies including a bee, fly, frog, mouse and slime
- Six boss fights with different behaviour (a charger, a flyer, a mage, a slime, a troll), each built on a shared `boss_base`
- Reusable hitbox / hurtbox components handle all damage, so the player, enemies and bosses share one system
- A leaderboard and scene transitions

## Architecture

Cross-cutting systems are autoload singletons:

- `GameManager`: global game state
- `EventBus`: a signal hub, so systems talk through events instead of direct references
- `AudioManager`: SFX and music
- `SceneTransitioner`: level and menu transitions
- `Leaderboard`: score persistence

Gameplay lives under `src/` (`components/`, `enemies/`, `levels/`, `ui/`); shared systems under `autoloads/`.

## Build

Open the project in Godot 4.6 or later and press play. Export presets are set up for Windows, Linux and Web (`export_presets.cfg`).

---

A personal project for learning game architecture in Godot. Part of my portfolio: https://floriansumi-bot.github.io/portfolio/
