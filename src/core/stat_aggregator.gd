extends Node
## Autoload "StatAggregator": central decoupled stat evaluation bus.
## Gameplay loops, upgrades, prestige nodes, and temporary synergies register StatModifierData
## entries here. Consumers query aggregated values by (domain, stat_key, base_value) without
## holding direct references to any other gameplay module.

var _entries: Dictionary = {} # StringName (source_id) -> Dictionary
var _cache: Dictionary = {}   # String -> float


func register_modifier(
	source_id: StringName,
	modifier: StatModifierData,
	level: int = 1,
	is_temporary: bool = false,
	resets_on_breakthrough: bool = true
) -> void:
	if modifier == null or source_id == &"":
		return
	if level <= 0:
		remove_modifier(source_id)
		return
	_entries[source_id] = {
		"modifier": modifier,
		"level": level,
		"is_temporary": is_temporary,
		"resets_on_breakthrough": resets_on_breakthrough,
	}
	_invalidate(modifier.target_domain, modifier.stat_key)


func register_upgrade(upgrade: UpgradeDefinitionData, level: int) -> void:
	if upgrade == null or upgrade.id == &"":
		return
	if level <= 0:
		remove_upgrade(upgrade.id)
		return
	for i in range(upgrade.modifiers.size()):
		var mod: StatModifierData = upgrade.modifiers[i]
		if mod == null:
			continue
		var mod_key: StringName = mod.modifier_id if mod.modifier_id != &"" else StringName(str(i))
		var source_id: StringName = StringName("%s:%s" % [upgrade.id, mod_key])
		register_modifier(source_id, mod, level, false, upgrade.resets_on_breakthrough)


func remove_modifier(source_id: StringName) -> void:
	if not _entries.has(source_id):
		return
	var entry: Dictionary = _entries[source_id]
	var mod: StatModifierData = entry.get("modifier")
	_entries.erase(source_id)
	if mod != null:
		_invalidate(mod.target_domain, mod.stat_key)
	else:
		_cache.clear()


func remove_upgrade(upgrade_id: StringName) -> void:
	var prefix: String = "%s:" % String(upgrade_id)
	var to_remove: Array[StringName] = []
	for key in _entries.keys():
		if String(key).begins_with(prefix) or key == upgrade_id:
			to_remove.append(key)
	for key in to_remove:
		remove_modifier(key)


func clear_temporary_modifiers() -> void:
	var to_remove: Array[StringName] = []
	for key in _entries.keys():
		var entry: Dictionary = _entries[key]
		if entry.get("is_temporary", false):
			to_remove.append(key)
	for key in to_remove:
		remove_modifier(key)


func reset_for_breakthrough() -> void:
	var to_remove: Array[StringName] = []
	for key in _entries.keys():
		var entry: Dictionary = _entries[key]
		if entry.get("resets_on_breakthrough", true) or entry.get("is_temporary", false):
			to_remove.append(key)
	for key in to_remove:
		remove_modifier(key)


func clear_all() -> void:
	_entries.clear()
	_cache.clear()
	if is_instance_valid(EventBus):
		EventBus.stat_invalidated.emit(&"all", &"all")


func has_source(source_id: StringName) -> bool:
	return _entries.has(source_id)


func active_source_count() -> int:
	return _entries.size()


func query(domain: StringName, stat_key: StringName = &"all", base_value: float = 0.0) -> float:
	var cache_key: String = "%s|%s|%s" % [domain, stat_key, str(base_value)]
	if _cache.has(cache_key):
		return _cache[cache_key]

	var sum_add: float = 0.0
	var sum_mul_add: float = 0.0
	var prod_mul: float = 1.0
	var has_override: bool = false
	var override_value: float = 0.0

	for source_id in _entries:
		var entry: Dictionary = _entries[source_id]
		var mod: StatModifierData = entry.get("modifier")
		var level: int = entry.get("level", 0)
		if mod == null or level <= 0:
			continue
		if mod.target_domain != domain:
			continue
		if mod.stat_key != stat_key and mod.stat_key != &"all":
			continue

		var val: float = mod.evaluate(level)
		match mod.operation:
			StatModifierData.Operation.ADD:
				sum_add += val
			StatModifierData.Operation.MUL_ADD:
				sum_mul_add += val
			StatModifierData.Operation.MUL_COMPOUND:
				prod_mul *= val
			StatModifierData.Operation.OVERRIDE:
				has_override = true
				override_value = val

	var result: float = override_value if has_override else (base_value + sum_add) * maxf(0.0, 1.0 + sum_mul_add) * prod_mul
	_cache[cache_key] = result
	return result


func _invalidate(domain: StringName, stat_key: StringName) -> void:
	_cache.clear()
	if is_instance_valid(EventBus):
		EventBus.stat_invalidated.emit(domain, stat_key)
