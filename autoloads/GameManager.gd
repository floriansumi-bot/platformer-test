extends Node
## Global run state: health, score, lives, deaths. Emits signals the HUD binds to.
## Score = coins collected (+1) + enemy kills (+1) + level completion (+100).

signal health_changed(new_health: int)
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal deaths_changed(new_deaths: int)

const MAX_HEALTH: int = 3
const LEVEL_COMPLETE_BONUS: int = 100

var health: int = MAX_HEALTH
var score: int = 0
var lives: int = 3
var deaths: int = 0


func _ready() -> void:
	# EventBus is loaded before GameManager (autoload order), so it's safe here.
	EventBus.enemy_killed.connect(func(): add_score(1))
	EventBus.boss_defeated.connect(func(): add_score(LEVEL_COMPLETE_BONUS); heal(1))


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func apply_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health)


func reset_health() -> void:
	health = MAX_HEALTH
	health_changed.emit(health)


## Restore health (capped at max). Used by heart pickups and boss kills.
func heal(amount: int) -> void:
	health = mini(MAX_HEALTH, health + amount)
	health_changed.emit(health)


## On player death: bump the death counter and reset the run's score + health.
func register_death() -> void:
	deaths += 1
	deaths_changed.emit(deaths)
	score = 0
	score_changed.emit(score)
	reset_health()
