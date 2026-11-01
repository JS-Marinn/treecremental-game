class_name AchievementModule
extends GameModule
## Evaluates the ~80 canonical achievements from EventBus signals and game state.
## Every unlock registers a derived global_coin_multiplier bonus equal to
## unlocked_count * StatAggregator.query(&"achievement_coin_bonus") so each achievement
## feeds the sap_ancient_harmony prestige node exactly as its .tres data dictates.
## Unlocked achievements and evaluation progress persist via SaveModule.

var _unlocked: Dictionary = {}               # StringName -> true
var _lifetime_currency: Dictionary = {}      # StringName -> float
var _trees_felled_total: int = 0
var _trees_felled_by_species: Dictionary = {} # StringName -> int
var _old_growth_felled: int = 0
var _upgrade_levels: Dictionary = {}         # StringName -> int
var _upgrade_levels_purchased_total: int = 0
var _sawmill_assigned_total: int = 0
var _kiln_cycles_total: int = 0
var _max_boiler_pressure: float = 0.0
var _synergies_total: int = 0
var _max_breakthrough_act: int = 0
var _max_sap_balance: float = 0.0


func _init() -> void:
	module_id = &"achievements"


func _ready() -> void:
	is_active = true
	if is_instance_valid(EventBus):
		if not EventBus.resource_gained.is_connected(_on_resource_gained):
			EventBus.resource_gained.connect(_on_resource_gained)
		if not EventBus.resource_total_changed.is_connected(_on_resource_total_changed):
			EventBus.resource_total_changed.connect(_on_resource_total_changed)
		if not EventBus.tree_felled.is_connected(_on_tree_felled):
			EventBus.tree_felled.connect(_on_tree_felled)
		if not EventBus.upgrade_purchased.is_connected(_on_upgrade_purchased):
			EventBus.upgrade_purchased.connect(_on_upgrade_purchased)
		if not EventBus.synergy_triggered.is_connected(_on_synergy_triggered):
			EventBus.synergy_triggered.connect(_on_synergy_triggered)
		if not EventBus.breakthrough_reached.is_connected(_on_breakthrough_reached):
			EventBus.breakthrough_reached.connect(_on_breakthrough_reached)
		if not EventBus.worker_assigned.is_connected(_on_worker_assigned):
			EventBus.worker_assigned.connect(_on_worker_assigned)
	_evaluate_all()
	_refresh_mastery_modifier()


func is_unlocked(achievement_id: StringName) -> bool:
	return _unlocked.has(achievement_id)


func get_unlocked_count() -> int:
	return _unlocked.size()


func unlock_achievement(achievement_id: StringName) -> bool:
	if _unlocked.has(achievement_id):
		return false
	_unlocked[achievement_id] = true
	if is_instance_valid(EventBus):
		EventBus.achievement_unlocked.emit(achievement_id)
	_refresh_mastery_modifier()
	_evaluate_all()
	return true


## Copies existing upgrade levels from the MainScreen without counting them as
## fresh purchases. Called once at boot and after loading a save.
func sync_upgrade_levels_from_screen(screen: MainScreen) -> void:
	if screen == null:
		return
	for uid in Balance.upgrade_ids():
		var level: int = screen.get_upgrade_level(uid)
		if level > 0:
			_upgrade_levels[uid] = level
	_evaluate_all()


func notify_kiln_cycle_completed(_charcoal_gained: float = 0.0, _ash_gained: float = 0.0) -> void:
	_kiln_cycles_total += 1
	_evaluate_all()


func notify_thermal_pressure_changed(new_pressure: float, _speed_bonus: float = 0.0) -> void:
	_max_boiler_pressure = maxf(_max_boiler_pressure, new_pressure)
	_evaluate_all()


func serialize() -> Dictionary:
	var unlocked_list: Array[String] = []
	for ach_id in _unlocked.keys():
		unlocked_list.append(String(ach_id))
	return {
		"unlocked": unlocked_list,
		"lifetime_currency": _string_keyed_floats(_lifetime_currency),
		"trees_felled_total": _trees_felled_total,
		"trees_felled_by_species": _string_keyed_ints(_trees_felled_by_species),
		"old_growth_felled": _old_growth_felled,
		"upgrade_levels": _string_keyed_ints(_upgrade_levels),
		"upgrade_levels_purchased_total": _upgrade_levels_purchased_total,
		"sawmill_assigned_total": _sawmill_assigned_total,
		"kiln_cycles_total": _kiln_cycles_total,
		"max_boiler_pressure": _max_boiler_pressure,
		"synergies_total": _synergies_total,
		"max_breakthrough_act": _max_breakthrough_act,
		"max_sap_balance": _max_sap_balance,
	}


func deserialize(data: Dictionary) -> void:
	_unlocked.clear()
	var unlocked_list: Array = data.get("unlocked", [])
	for entry in unlocked_list:
		_unlocked[StringName(String(entry))] = true
	_lifetime_currency = _restore_floats(data.get("lifetime_currency", {}))
	_trees_felled_total = maxi(0, int(data.get("trees_felled_total", 0)))
	_trees_felled_by_species = _restore_ints(data.get("trees_felled_by_species", {}))
	_old_growth_felled = maxi(0, int(data.get("old_growth_felled", 0)))
	_upgrade_levels = _restore_ints(data.get("upgrade_levels", {}))
	_upgrade_levels_purchased_total = maxi(0, int(data.get("upgrade_levels_purchased_total", 0)))
	_sawmill_assigned_total = maxi(0, int(data.get("sawmill_assigned_total", 0)))
	_kiln_cycles_total = maxi(0, int(data.get("kiln_cycles_total", 0)))
	_max_boiler_pressure = maxf(0.0, float(data.get("max_boiler_pressure", 0.0)))
	_synergies_total = maxi(0, int(data.get("synergies_total", 0)))
	_max_breakthrough_act = maxi(0, int(data.get("max_breakthrough_act", 0)))
	_max_sap_balance = maxf(0.0, float(data.get("max_sap_balance", 0.0)))
	_evaluate_all()
	_refresh_mastery_modifier()


func _on_resource_gained(currency_id: StringName, amount: float, _source_id: StringName) -> void:
	_lifetime_currency[currency_id] = float(_lifetime_currency.get(currency_id, 0.0)) + amount
	_evaluate_all()


func _on_resource_total_changed(currency_id: StringName, new_total: float) -> void:
	if currency_id == &"sap":
		_max_sap_balance = maxf(_max_sap_balance, new_total)
		_evaluate_all()


func _on_tree_felled(species_id: StringName, maturity_rank: int, _jackpot_coins: float) -> void:
	_trees_felled_total += 1
	_trees_felled_by_species[species_id] = int(_trees_felled_by_species.get(species_id, 0)) + 1
	if maturity_rank >= 4:
		_old_growth_felled += 1
	_evaluate_all()


func _on_upgrade_purchased(upgrade_id: StringName, new_level: int) -> void:
	var previous: int = int(_upgrade_levels.get(upgrade_id, 0))
	_upgrade_levels[upgrade_id] = maxi(previous, new_level)
	if new_level > previous:
		_upgrade_levels_purchased_total += new_level - previous
	_evaluate_all()
	if upgrade_id == &"sap_ancient_harmony":
		_refresh_mastery_modifier()


func _on_synergy_triggered(_species_id: StringName, _synergy_id: StringName, _duration_s: float) -> void:
	_synergies_total += 1
	_evaluate_all()


func _on_breakthrough_reached(act_index: int) -> void:
	_max_breakthrough_act = maxi(_max_breakthrough_act, act_index)
	_evaluate_all()


func _on_worker_assigned(_worker_id: StringName, _loop_id: StringName, _target_id: StringName, _assigned_count: int) -> void:
	_sawmill_assigned_total += 1
	_evaluate_all()


func _evaluate_all() -> void:
	for ach_id in Balance.achievement_ids():
		if _unlocked.has(ach_id):
			continue
		var def: AchievementDefinitionData = Balance.achievement(ach_id)
		if def != null and _is_condition_met(def):
			unlock_achievement(ach_id)


func _is_condition_met(def: AchievementDefinitionData) -> bool:
	match def.trigger:
		AchievementDefinitionData.Trigger.LIFETIME_CURRENCY:
			return float(_lifetime_currency.get(def.currency_id, 0.0)) >= def.threshold
		AchievementDefinitionData.Trigger.TREES_FELLED_TOTAL:
			return float(_trees_felled_total) >= def.threshold
		AchievementDefinitionData.Trigger.TREES_FELLED_SPECIES:
			return float(_trees_felled_by_species.get(def.species_id, 0)) >= def.threshold
		AchievementDefinitionData.Trigger.OLD_GROWTH_FELLED:
			return float(_old_growth_felled) >= def.threshold
		AchievementDefinitionData.Trigger.UPGRADES_PURCHASED_TOTAL:
			return float(_upgrade_levels_purchased_total) >= def.threshold
		AchievementDefinitionData.Trigger.UPGRADE_LEVEL:
			return float(_upgrade_levels.get(def.upgrade_id, 0)) >= def.threshold
		AchievementDefinitionData.Trigger.CATEGORY_UPGRADES:
			return _category_total(def.category_id) >= def.threshold
		AchievementDefinitionData.Trigger.WORKER_ROSTER_LEVEL:
			return float(_upgrade_levels.get(StringName("hire_%s" % String(def.worker_id)), 0)) >= def.threshold
		AchievementDefinitionData.Trigger.ALL_WORKER_TYPES:
			for worker_id in Balance.worker_ids():
				if float(_upgrade_levels.get(StringName("hire_%s" % String(worker_id)), 0)) < def.threshold:
					return false
			return true
		AchievementDefinitionData.Trigger.SAWMILL_ASSIGNED:
			return float(_sawmill_assigned_total) >= def.threshold
		AchievementDefinitionData.Trigger.KILN_CYCLES:
			return float(_kiln_cycles_total) >= def.threshold
		AchievementDefinitionData.Trigger.BOILER_PRESSURE:
			return _max_boiler_pressure >= def.threshold
		AchievementDefinitionData.Trigger.SPECIES_UNLOCKED:
			return _unlocked_species_count() >= def.threshold
		AchievementDefinitionData.Trigger.SYNERGIES_TRIGGERED:
			return float(_synergies_total) >= def.threshold
		AchievementDefinitionData.Trigger.BREAKTHROUGH_INDEX:
			return float(_max_breakthrough_act) >= def.threshold
		AchievementDefinitionData.Trigger.SAP_BANKED:
			return _max_sap_balance >= def.threshold
		AchievementDefinitionData.Trigger.ALL_ACHIEVEMENTS:
			return _unlocked.size() >= Balance.achievement_ids().size() - 1
	return false


func _unlocked_species_count() -> float:
	var count: float = 0.0
	for sid in Balance.species_ids():
		if int(_upgrade_levels.get(StringName("prop_%s" % String(sid)), 0)) >= 1:
			count += 1.0
	return count


func _category_total(category_id: StringName) -> float:
	var total: float = 0.0
	for upg in Balance.upgrades_for_category(category_id):
		total += float(_upgrade_levels.get(upg.id, 0))
	return total


func _refresh_mastery_modifier() -> void:
	if _unlocked.is_empty():
		StatAggregator.remove_modifier(&"achievement_mastery")
		return
	# sap_ancient_harmony contributes its per-level percentage via the
	# achievement_coin_bonus domain (evaluated against a 1.0 base multiplier).
	var bonus_per_achievement: float = StatAggregator.query(&"achievement_coin_bonus", &"all", 1.0) - 1.0
	var curve := FormulaCurve.new()
	curve.kind = FormulaCurve.Kind.CONSTANT
	curve.base = maxf(0.0, bonus_per_achievement * float(_unlocked.size()))

	var mod := StatModifierData.new()
	mod.modifier_id = &"achievement_mastery"
	mod.target_domain = &"global_coin_multiplier"
	mod.stat_key = &"all"
	mod.operation = StatModifierData.Operation.MUL_ADD
	mod.curve = curve

	StatAggregator.register_modifier(&"achievement_mastery", mod, 1, false, false)


func _string_keyed_floats(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in source.keys():
		out[String(key)] = float(source[key])
	return out


func _string_keyed_ints(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in source.keys():
		out[String(key)] = int(source[key])
	return out


func _restore_floats(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in source.keys():
		out[StringName(String(key))] = float(source[key])
	return out


func _restore_ints(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in source.keys():
		out[StringName(String(key))] = int(source[key])
	return out
