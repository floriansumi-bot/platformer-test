extends Node
## Global run state: health, score, lives, deaths, and the player's inventory /
## equipment (helmets). Emits signals the HUD + equipment screen bind to.
## Health is a float so an equipped helmet can soak a fraction of a heart.

signal health_changed(new_health: float)
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal deaths_changed(new_deaths: int)
signal equipment_changed

const MAX_HEALTH: float = 3.0
const LEVEL_COMPLETE_BONUS: int = 100

# Helmet tiers and the fraction of incoming damage they let through.
const HELMET_ORDER: Array[String] = ["bronze", "steel", "gold"]
const HELMET_DAMAGE := {"": 1.0, "bronze": 2.0 / 3.0, "steel": 0.5, "gold": 1.0 / 3.0}

var health: float = MAX_HEALTH
var score: int = 0
var lives: int = 3
var deaths: int = 0

# Inventory / equipment — persists across levels, reset on a new game.
var owned_helmets: Array[String] = []
var equipped_helmet: String = ""


func _ready() -> void:
	# EventBus is loaded before GameManager (autoload order), so it's safe here.
	EventBus.enemy_killed.connect(func(): add_score(1))
	EventBus.boss_defeated.connect(func(): add_score(LEVEL_COMPLETE_BONUS); heal(1.0))


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


## Damage in hearts, reduced by the equipped helmet (e.g. bronze → 2/3 a heart).
func apply_damage(amount: float) -> void:
	health = maxf(0.0, health - amount * helmet_damage_mult())
	health_changed.emit(health)


func helmet_damage_mult() -> float:
	return HELMET_DAMAGE.get(equipped_helmet, 1.0)


func reset_health() -> void:
	health = MAX_HEALTH
	health_changed.emit(health)


## Restore health (capped at max). Used by heart pickups and boss kills.
func heal(amount: float) -> void:
	health = minf(MAX_HEALTH, health + amount)
	health_changed.emit(health)


## On player death: bump the death counter and reset the run's score + health.
## Inventory/equipment are kept (only a new game clears them).
func register_death() -> void:
	deaths += 1
	deaths_changed.emit(deaths)
	score = 0
	score_changed.emit(score)
	reset_health()


# --- Inventory / equipment ---------------------------------------------------

## Award the next helmet tier the player doesn't own yet. Returns it, or "".
func award_helmet() -> String:
	for h in HELMET_ORDER:
		if not owned_helmets.has(h):
			owned_helmets.append(h)
			equipment_changed.emit()
			return h
	return ""


## Equip a helmet by name ("" = none). Only equips ones actually owned.
func equip_helmet(helmet: String) -> void:
	if helmet == "" or owned_helmets.has(helmet):
		equipped_helmet = helmet
		equipment_changed.emit()


## Start a fresh game: clear run state AND inventory/equipment.
func new_game() -> void:
	owned_helmets.clear()
	equipped_helmet = ""
	score = 0
	deaths = 0
	health = MAX_HEALTH
	equipment_changed.emit()
	score_changed.emit(score)
	deaths_changed.emit(deaths)
	health_changed.emit(health)
