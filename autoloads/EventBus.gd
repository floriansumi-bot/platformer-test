extends Node
## Global signal hub. Signals only — never store gameplay state here.

signal boss_defeated
signal enemy_killed

## A timed powerup became active / ended (for the HUD's countdown indicator).
signal powerup_started(kind: String, duration: float)
signal powerup_ended(kind: String)
