# Drives the active state and swaps states when one emits `transitioned`.
# Child of Player; its own children are the State nodes.
class_name StateMachine
extends Node

## Set this in the inspector to the state node the player should start in (usually Idle).
@export var initial_state: State

var current_state: State
var states: Dictionary = {}


func _ready() -> void:
	var player := owner as Player
	for child in get_children():
		if child is State:
			var state := child as State
			states[StringName(child.name.to_lower())] = state
			state.player = player
			state.transitioned.connect(_on_state_transitioned)
	if initial_state:
		current_state = initial_state
		# Defer the first enter() so the owner (Player) finishes _ready and its
		# @onready refs (e.g. sprite) exist before any state touches them.
		current_state.call_deferred(&"enter")


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _on_state_transitioned(new_state_name: StringName) -> void:
	var key := StringName(String(new_state_name).to_lower())
	var new_state: State = states.get(key)
	if new_state == null:
		push_warning("StateMachine: no state named '%s'" % new_state_name)
		return
	if new_state == current_state:
		return
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()
