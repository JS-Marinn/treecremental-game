class_name ModuleRegistry
extends Node
## Central manager for all plug-and-play GameModule instances.
## Discovers, topologically sorts, and updates active gameplay modules.

var _modules: Dictionary = {}  # StringName -> GameModule
var _ordered_modules: Array[GameModule] = []


func register_module(module: GameModule) -> void:
	assert(module != null and module.module_id != &"", "ModuleRegistry: invalid module registration")
	if _modules.has(module.module_id):
		push_warning("ModuleRegistry: replacing existing module '%s'" % module.module_id)
	_modules[module.module_id] = module
	if not module.is_inside_tree():
		add_child(module)
	_sort_modules()
	module.setup(self)


func unregister_module(module_id: StringName) -> void:
	if not _modules.has(module_id):
		return
	var mod: GameModule = _modules[module_id]
	_modules.erase(module_id)
	_sort_modules()
	if mod.is_inside_tree():
		mod.queue_free()


func get_module(module_id: StringName) -> GameModule:
	return _modules.get(module_id)


func has_module(module_id: StringName) -> bool:
	return _modules.has(module_id)


func get_all_modules() -> Array[GameModule]:
	return _ordered_modules.duplicate()


func _process(delta: float) -> void:
	for mod in _ordered_modules:
		if mod.is_active:
			mod.tick(delta)


func process_offline_progress(seconds: float) -> void:
	for mod in _ordered_modules:
		if mod.is_active:
			mod.offline_step(seconds)


func serialize_all() -> Dictionary:
	var out: Dictionary = {}
	for mod in _ordered_modules:
		out[String(mod.module_id)] = mod.serialize()
	return out


func deserialize_all(data: Dictionary) -> void:
	for mod in _ordered_modules:
		var key := String(mod.module_id)
		if data.has(key) and data[key] is Dictionary:
			mod.deserialize(data[key])


func _sort_modules() -> void:
	var visited: Dictionary = {}
	var temp: Dictionary = {}
	var order: Array[GameModule] = []

	for mod_id in _modules:
		if not visited.get(mod_id, false):
			_visit_module(mod_id, visited, temp, order)

	_ordered_modules = order


func _visit_module(mod_id: StringName, visited: Dictionary, temp: Dictionary, order: Array[GameModule]) -> void:
	if temp.get(mod_id, false):
		push_error("ModuleRegistry: circular dependency detected involving '%s'" % mod_id)
		return
	if visited.get(mod_id, false):
		return

	temp[mod_id] = true
	var mod: GameModule = _modules.get(mod_id)
	if mod:
		for dep in mod.dependencies:
			if _modules.has(dep):
				_visit_module(dep, visited, temp, order)

	temp[mod_id] = false
	visited[mod_id] = true
	if mod:
		order.append(mod)
