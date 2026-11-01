class_name RosterDispatcher
extends RefCounted
## Enforces worker loop placement rules from WorkerArchetypeData.allowed_loop_ids:
## - Only simple_lumberjack has allowed_loop_ids = ["logging_camp", "sawmill"] and can be shared.
## - heavy_sawyer and swift_cleaver have allowed_loop_ids = ["logging_camp"] and are Main Loop exclusive.
## Tracks per-species Sawmill station assignments and computes remaining clearing workers.

var _sawmill_by_species: Dictionary = {} # StringName (species_id) -> int


func can_worker_enter_loop(worker_id: StringName, loop_id: StringName) -> bool:
	var arch: WorkerArchetypeData = Balance.worker(worker_id)
	if arch == null:
		return false
	return arch.can_assign_to_loop(loop_id)


func get_total_hired(worker_id: StringName) -> int:
	var queried: int = int(StatAggregator.query(&"worker_roster_count", worker_id, 0.0))
	if worker_id == &"simple_lumberjack":
		var bonus_start: int = int(StatAggregator.query(&"starting_simple_lumberjacks", &"simple_lumberjack", 0.0))
		return maxi(1, queried + bonus_start)
	return maxi(0, queried)


func get_sawmill_max_capacity() -> int:
	var base_slots: int = Balance.config.sawmill_initial_worker_slots if Balance.config != null else 2
	var bonus_slots: int = int(StatAggregator.query(&"sawmill_max_workers", &"all", 0.0))
	return base_slots + bonus_slots


func get_station_max_slots(species_id: StringName) -> int:
	return 1 + int(StatAggregator.query(&"sawmill_station_slots", species_id, 0.0))


func get_station_assigned(species_id: StringName) -> int:
	return int(_sawmill_by_species.get(species_id, 0))


func get_total_sawmill_assigned() -> int:
	var total: int = 0
	for sid in _sawmill_by_species.keys():
		total += int(_sawmill_by_species[sid])
	return total


func get_clearing_worker_count(worker_id: StringName) -> int:
	var total: int = get_total_hired(worker_id)
	if worker_id == &"simple_lumberjack":
		return maxi(0, total - get_total_sawmill_assigned())
	return total


func can_assign_more_to_station(species_id: StringName, worker_id: StringName = &"simple_lumberjack") -> bool:
	if not can_worker_enter_loop(worker_id, &"sawmill"):
		return false
	var total_hired: int = get_total_hired(worker_id)
	var used_total: int = get_total_sawmill_assigned()
	var max_mill_cap: int = get_sawmill_max_capacity()
	var cur_station: int = get_station_assigned(species_id)
	var station_cap: int = get_station_max_slots(species_id)
	return (used_total < total_hired) and (used_total < max_mill_cap) and (cur_station < station_cap)


func try_adjust_station_assignment(
	species_id: StringName,
	delta: int,
	worker_id: StringName = &"simple_lumberjack"
) -> bool:
	if not can_worker_enter_loop(worker_id, &"sawmill"):
		return false
	var current: int = get_station_assigned(species_id)
	if delta > 0:
		if not can_assign_more_to_station(species_id, worker_id):
			return false
		_sawmill_by_species[species_id] = current + 1
		if is_instance_valid(EventBus):
			EventBus.worker_assigned.emit(worker_id, &"sawmill", species_id, current + 1)
		return true
	elif delta < 0:
		if current <= 0:
			return false
		_sawmill_by_species[species_id] = current - 1
		if is_instance_valid(EventBus):
			EventBus.worker_assigned.emit(worker_id, &"sawmill", species_id, current - 1)
		return true
	return false


func get_all_station_assignments() -> Dictionary:
	return _sawmill_by_species.duplicate()


## Restores per-species Sawmill station assignments from a save file, clamping each
## entry to the current station slot caps without re-emitting assignment events.
func restore_station_assignments(data: Dictionary) -> void:
	_sawmill_by_species.clear()
	for key in data.keys():
		var sid := StringName(String(key))
		if Balance.species(sid) == null:
			continue
		_sawmill_by_species[sid] = clampi(int(float(data[key])), 0, get_station_max_slots(sid))


func reset_for_breakthrough() -> void:
	_sawmill_by_species.clear()
