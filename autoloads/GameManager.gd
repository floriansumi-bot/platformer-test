extends Node
## Global run state: health, coins, deaths, lives. Emits signals the HUD binds to.
## No gameplay logic — entities call these and react to the signals.

signal health_changed(new_health: int)
signal coins_changed(new_coins: int)
signal lives_changed(new_lives: int)
signal deaths_changed(new_deaths: int)

const MAX_HEALTH: int = 3

var health: int = MAX_HEALTH
var coins: int = 0
var lives: int = 3
var deaths: int = 0   # persists across respawns (autoloads survive reload_current_scene)


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)


func apply_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health)


func reset_health() -> void:
	health = MAX_HEALTH
	health_changed.emit(health)


## Called on player death: bump the death counter and reset the run's coins + health.
func register_death() -> void:
	deaths += 1
	deaths_changed.emit(deaths)
	coins = 0
	coins_changed.emit(coins)
	reset_health()
