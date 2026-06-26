# Platformer

A 2D action-platformer built in **Godot 4.6** (GDScript) — a hand-built game with multiple levels, a roster of enemies, and several distinct boss fights, structured the way a real game project is rather than a single-scene prototype.

## Features

- 🗺️ **Multiple hand-built levels** (`src/levels/`)
- 👾 **Varied enemies** — bee, fly, frog, mouse, slime, each with its own behaviour
- 🐉 **Six boss fights with distinct AI** — a charger (goblin), a flyer (fire), a mage (ranged projectiles), a slime, a troll, and more, each subclassing a shared `boss_base`
- ⚔️ **Component-based combat** — reusable `hitbox` / `hurtbox` components drive all damage, so enemies, bosses and the player share one consistent system
- 🏆 **Leaderboard** and scene-to-scene transitions

## Architecture

The project is organised around **autoload singletons** for clean cross-cutting systems:

| Autoload | Role |
|---|---|
| `GameManager` | global game state |
| `EventBus` | decoupled signal hub — systems talk through events, not direct references |
| `AudioManager` | centralised SFX / music |
| `SceneTransitioner` | level and menu transitions |
| `Leaderboard` | score persistence |

Gameplay code lives under `src/` (`components/`, `enemies/`, `levels/`, `ui/`); shared systems under `autoloads/`.

## Build / run

Open the project in **Godot 4.6+** and press play. Export presets are configured for **Windows, Linux, and Web (HTML5)** (`export_presets.cfg`).

---

A personal project for learning game architecture in Godot. Part of my portfolio — **https://floriansumi-bot.github.io/portfolio/**
