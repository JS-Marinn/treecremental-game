extends Node
## Global signal bus (autoload "EventBus").
## Systems emit and subscribe here without holding direct references to each other.
## UI nodes subscribe to state signals and dispatch player intent via command_requested.

@warning_ignore_start("unused_signal")
signal resource_gained(resource_id: StringName, amount: float, source_id: StringName)
signal resource_spent(resource_id: StringName, amount: float, sink_id: StringName)
signal resource_total_changed(resource_id: StringName, new_total: float)

signal species_unlocked(species_id: StringName)
signal worker_hired(species_id: StringName, new_count: int)
signal upgrade_purchased(upgrade_id: StringName, new_level: int)
signal breakthrough_reached(act_index: int)
signal prestige_performed(sap_gained: float, sap_total: float)

signal achievement_unlocked(achievement_id: StringName)
signal setting_changed(section: StringName, key: StringName, value: Variant)
signal notation_changed()

signal event_raised(event_name: StringName, payload: Dictionary)
signal command_requested(command_name: StringName, payload: Dictionary)
@warning_ignore_restore("unused_signal")


func raise(event_name: StringName, payload: Dictionary = {}) -> void:
	event_raised.emit(event_name, payload)


func request(command_name: StringName, payload: Dictionary = {}) -> void:
	command_requested.emit(command_name, payload)
