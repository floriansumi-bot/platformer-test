# Base FSM state. Every concrete state (idle/run/jump/fall) does `extends State`.
# The StateMachine injects `player` and connects `transitioned` automatically.
class_name State
extends Node

## Emit with a StringName to request a transition, e.g. transitioned.emit(&"fall").
## The StateMachine matches it to a sibling state node by (lower-cased) name.
signal transitioned(new_state_name: StringName)

## Injected by the StateMachine on _ready(); typed so autocomplete and the
## compiler know about every Player helper. Never walk get_parent() chains.
var player: Player


## Called once when this state becomes active.
func enter() -> void:
	pass


## Called once when this state is left.
func exit() -> void:
	pass


## Forwarded from StateMachine._unhandled_input. Use for one-shot, event-driven input.
func handle_input(_event: InputEvent) -> void:
	pass


## Forwarded from StateMachine._process. Use for non-physics per-frame work (e.g. animation).
func update(_delta: float) -> void:
	pass


## Forwarded from StateMachine._physics_process. Do movement here, in this order:
## gravity -> horizontal -> input/jump -> move_and_slide() -> emit transitions.
func physics_update(_delta: float) -> void:
	pass
