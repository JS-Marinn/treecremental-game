extends Node
## Global decoupled event bus (autoload "EventBus").
## Systems never hold references to each other: they emit here and listen here.
## UI is display-only: it listens to these signals and requests changes via command_requested.
##
## Plug-and-play rule: a NEW mechanic that needs a NEW event does not edit this file;
## it uses the generic [signal event_raised] channel (name + payload dictionary).

# --- Core economy -----------------------------------------------------------
@warning_ignore_start("unused_signal")
signal resource_gained(resource_id: StringName, amount: float, source_id: StringName)
signal resource_spent(resource_id: StringName, amount: float, sink_id: StringName)
signal resource_total_changed(resource_id: StringName, new_total: float)

# --- Progression ------------------------------------------------------------
signal species_unlocked(species_id: StringName)
signal worker_hired(species_id: StringName, new_count: int)
signal upgrade_purchased(upgrade_id: StringName, new_level: int)
signal prestige_performed(sap_gained: float, sap_total: float)

# --- Meta -------------------------------------------------------------------
signal achievement_unlocked(achievement_id: StringName)
signal setting_changed(section: StringName, key: StringName, value: Variant)
signal notation_changed()

# --- Generic channels (extensibility) --------------------------------------
## Any module may announce anything: e.g. event_raised(&"bonsai.pruned", {"species": &"pine"}).
signal event_raised(event_name: StringName, payload: Dictionary)
## UI/input -> game logic requests (UI never mutates state directly).
signal command_requested(command_name: StringName, payload: Dictionary)
@warning_ignore_restore("unused_signal")


func raise(event_name: StringName, payload: Dictionary = {}) -> void:
	event_raised.emit(event_name, payload)


func request(command_name: StringName, payload: Dictionary = {}) -> void:
	command_requested.emit(command_name, payload)
