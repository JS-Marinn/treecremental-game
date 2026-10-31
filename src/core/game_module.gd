class_name GameModule
extends Node
## Base class for every decoupled game system (Logging, Sawmill, Charcoal, Bonsai, Tertiary Loops, etc.).
##
## Plug-and-play contract:
## - Modules NEVER hold direct references to sibling modules.
## - All inter-module interaction happens strictly through EventBus signals and commands.
## - Adding or removing a module requires zero modifications to existing modules.

@export var module_id: StringName = &""
@export var dependencies: Array[StringName] = []

var is_active: bool = false


## Called when the module is registered and attached to the scene tree.
func setup(_context: Node) -> void:
	is_active = true


## Main process loop for runtime simulation.
func tick(_delta: float) -> void:
	pass


## Analytic simulation step for offline progress calculation.
## Used when the player returns after closing the game.
func offline_step(_elapsed_seconds: float) -> void:
	pass


## Serializes state for saving. Must return a JSON-compatible Dictionary.
func serialize() -> Dictionary:
	return {}


## Deserializes saved state.
func deserialize(_data: Dictionary) -> void:
	pass


## Helper to emit on the event bus without hardcoding.
func raise_event(event_name: StringName, payload: Dictionary = {}) -> void:
	EventBus.raise(event_name, payload)


## Helper to request a game command.
func request_command(command_name: StringName, payload: Dictionary = {}) -> void:
	EventBus.request(command_name, payload)
