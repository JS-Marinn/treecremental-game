extends Node
## Autoload "Balance": the ONLY gateway from game logic to balance data.
## Loads the active BalanceConfig profile and discovers every SpeciesData under data/species/,
## WorkerArchetypeData under data/workers/, and UpgradeDefinitionData under data/upgrades/.
## Game systems call Balance.species(id), Balance.worker(id), Balance.upgrade(id) and never contain numbers.

const SETTING_PROFILE: String = "treecremental/balance/profile"
const SETTING_SPECIES_DIR: String = "treecremental/balance/species_dir"
const SETTING_WORKERS_DIR: String = "treecremental/balance/workers_dir"
const SETTING_UPGRADES_DIR: String = "treecremental/balance/upgrades_dir"

var config: BalanceConfig
var _species: Dictionary = {}          # StringName -> SpeciesData
var _species_order: Array[StringName] = []
var _workers: Dictionary = {}          # StringName -> WorkerArchetypeData
var _worker_order: Array[StringName] = []
var _upgrades: Dictionary = {}         # StringName -> UpgradeDefinitionData
var _upgrade_order: Array[StringName] = []


func _ready() -> void:
	LocaleResolver.ensure_loaded()
	reload()


## Hot-reload entry point: designers can call this from a debug key after editing .tres files.
func reload() -> void:
	var profile_path: String = ProjectSettings.get_setting(SETTING_PROFILE, "res://data/balance/balance_default.tres")
	config = load(profile_path) as BalanceConfig
	assert(config != null, "Balance: cannot load profile %s" % profile_path)
	_load_species(ProjectSettings.get_setting(SETTING_SPECIES_DIR, "res://data/species"))
	_load_workers(ProjectSettings.get_setting(SETTING_WORKERS_DIR, "res://data/workers"))
	_load_upgrades(ProjectSettings.get_setting(SETTING_UPGRADES_DIR, "res://data/upgrades"))


func species(id: StringName) -> SpeciesData:
	return _species.get(id)


func species_ids() -> Array[StringName]:
	return _species_order


func worker(id: StringName) -> WorkerArchetypeData:
	return _workers.get(id)


func worker_ids() -> Array[StringName]:
	return _worker_order


func upgrade(id: StringName) -> UpgradeDefinitionData:
	return _upgrades.get(id)


func upgrade_ids() -> Array[StringName]:
	return _upgrade_order


func upgrades_for_loop(loop_id: StringName) -> Array[UpgradeDefinitionData]:
	var result: Array[UpgradeDefinitionData] = []
	for uid in _upgrade_order:
		var upg: UpgradeDefinitionData = _upgrades[uid]
		if upg.loop_id == loop_id:
			result.append(upg)
	return result


func upgrades_for_category(category: StringName) -> Array[UpgradeDefinitionData]:
	var result: Array[UpgradeDefinitionData] = []
	for uid in _upgrade_order:
		var upg: UpgradeDefinitionData = _upgrades[uid]
		if upg.category == category:
			result.append(upg)
	return result


func _load_species(dir_path: String) -> void:
	_species.clear()
	_species_order.clear()
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Balance: species dir missing: %s" % dir_path)
	for file_name in dir.get_files():
		var clean: String = file_name.trim_suffix(".remap")
		if not clean.ends_with(".tres"):
			continue
		var res: SpeciesData = load(dir_path.path_join(clean)) as SpeciesData
		if res == null or res.id == &"":
			push_warning("Balance: skipped invalid species file %s" % clean)
			continue
		_species[res.id] = res
	_species_order.assign(_species.keys())
	_species_order.sort_custom(func(a: StringName, b: StringName) -> bool:
		return (_species[a] as SpeciesData).tier < (_species[b] as SpeciesData).tier)


func _load_workers(dir_path: String) -> void:
	_workers.clear()
	_worker_order.clear()
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Balance: workers dir missing: %s" % dir_path)
	for file_name in dir.get_files():
		var clean: String = file_name.trim_suffix(".remap")
		if not clean.ends_with(".tres"):
			continue
		var res: WorkerArchetypeData = load(dir_path.path_join(clean)) as WorkerArchetypeData
		if res == null or res.id == &"":
			push_warning("Balance: skipped invalid worker file %s" % clean)
			continue
		_workers[res.id] = res
	_worker_order.assign(_workers.keys())
	_worker_order.sort_custom(func(a: StringName, b: StringName) -> bool:
		return (_workers[a] as WorkerArchetypeData).tier_index < (_workers[b] as WorkerArchetypeData).tier_index)


func _load_upgrades(dir_path: String) -> void:
	_upgrades.clear()
	_upgrade_order.clear()
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Balance: upgrades dir missing: %s" % dir_path)
	for file_name in dir.get_files():
		var clean: String = file_name.trim_suffix(".remap")
		if not clean.ends_with(".tres"):
			continue
		var res: UpgradeDefinitionData = load(dir_path.path_join(clean)) as UpgradeDefinitionData
		if res == null or res.id == &"":
			push_warning("Balance: skipped invalid upgrade file %s" % clean)
			continue
		_upgrades[res.id] = res
	_upgrade_order.assign(_upgrades.keys())
	_upgrade_order.sort_custom(_compare_upgrades)


func _compare_upgrades(a: StringName, b: StringName) -> bool:
	var ua: UpgradeDefinitionData = _upgrades[a]
	var ub: UpgradeDefinitionData = _upgrades[b]
	var sa: float = _upgrade_sort_score(ua)
	var sb: float = _upgrade_sort_score(ub)
	if not is_equal_approx(sa, sb):
		return sa < sb
	return String(a) < String(b)


func _upgrade_sort_score(u: UpgradeDefinitionData) -> float:
	if u == null:
		return 0.0
	var id_str: String = String(u.id)
	# Species-targeted upgrades sort by species tier (0..8)
	if u.target_entity_id != &"" and _species.has(u.target_entity_id):
		var sp: SpeciesData = _species[u.target_entity_id]
		return float(sp.tier)
	# Worker-targeted upgrades sort Hire (0..2) before Gear (10..12)
	if u.target_entity_id != &"" and _workers.has(u.target_entity_id):
		var wk: WorkerArchetypeData = _workers[u.target_entity_id]
		var group_offset: float = 0.0 if id_str.begins_with("hire_") else 10.0
		return group_offset + float(wk.tier_index)
	# All other upgrades sort by initial cost ( Lv.0 evaluation )
	return 100.0 + (u.cost_curve.evaluate(0.0) if u.cost_curve != null else 0.0)
