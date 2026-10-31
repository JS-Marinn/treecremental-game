class_name GameModule
extends Node
## Base contract for decoupled gameplay systems.
## Modules communicate exclusively through EventBus signals and commands.
## This game is designed as a continuous active session with no offline progression.

@export var module_id: StringName = &""
@export var dependencies: Array[StringName] = []

var is_active: bool = false


func setup(_context: Node) -> void:
	is_active = true


func tick(_delta: float) -> void:
	pass


func serialize() -> Dictionary:
	return {}


func deserialize(_data: Dictionary) -> void:
	pass


func raise_event(event_name: StringName, payload: Dictionary = {}) -> void:
	EventBus.raise(event_name, payload)


func request_command(command_name: StringName, payload: Dictionary = {}) -> void:
	EventBus.request(command_name, payload)
