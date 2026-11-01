class_name SynergyController
extends Node
## Evaluates and manages the 9 canonical Tree Species Ecological Synergies on tree fell:
## 1. pine -> pitch_sap_splatter (+25% worker_chop_power for 6s)
## 2. birch -> silver_bark_kindling (+25% kiln_cycle_speed & +15% worker_attack_rate for 6s)
## 3. oak -> acorn_mast_shower (instant +25% bonus coins + 1 birdseed)
## 4. sakura -> cherry_petal_rain (+35% worker_move_speed & +35% worker_attack_rate for 8s)
## 5. canadian_maple -> sugarbush_sap_flow (+30% global_coin_multiplier for 8s)
## 6. fir -> boreal_frost_shatter (+2 bark_penetration for 6s)
## 7. baobab -> monsoon_reservoir_surge (+50% species_spawn_weight & +30% sawmill_work_speed for 10s)
## 8. socotra_dragon_tree -> cinnabar_dragons_blood (+15% worker_crit_chance & +50% worker_crit_damage for 8s)
## 9. giant_sequoia -> seismic_timberfall (100% shockwave dealing 12% max_hp to all other living trees)

signal synergy_activated(species_id: StringName, synergy_id: StringName, duration_s: float)
signal synergy_expired(synergy_id: StringName)

var _active_timers: Dictionary = {} # StringName (synergy_id) -> Dictionary { "remaining": float, "sources": Array[StringName] }
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 9001


func try_trigger_on_fell(
	species_data: SpeciesData,
	synergy_weight: float,
	wallet: WalletModule,
	living_trees: Array,
	force_proc: bool = false
) -> bool:
	if species_data == null or species_data.synergy_id == &"":
		return false
	var proc_mult: float = StatAggregator.query(&"synergy_proc_chance", &"all", 1.0)
	var final_chance: float = clampf(species_data.synergy_proc_chance * synergy_weight * proc_mult, 0.0, 1.0)
	if not force_proc and _rng.randf() > final_chance:
		return false

	var syn_id: StringName = species_data.synergy_id
	var dur_mult: float = StatAggregator.query(&"synergy_duration", &"all", 1.0)
	var dur: float = species_data.synergy_duration_s * dur_mult
	var mag: float = species_data.synergy_magnitude

	match syn_id:
		&"pitch_sap_splatter":
			_register_timed_buff(syn_id, dur, [
				_make_mod(&"syn_pine_power", &"worker_chop_power", &"all", StatModifierData.Operation.MUL_ADD, mag)
			])
		&"silver_bark_kindling":
			_register_timed_buff(syn_id, dur, [
				_make_mod(&"syn_birch_kiln", &"kiln_cycle_speed", &"all", StatModifierData.Operation.MUL_ADD, mag),
				_make_mod(&"syn_birch_atk", &"worker_attack_rate", &"all", StatModifierData.Operation.MUL_ADD, 0.15)
			])
		&"acorn_mast_shower":
			if wallet != null:
				wallet.add_currency(&"coins", species_data.base_coin_value * mag, &"acorn_mast_shower")
				wallet.add_currency(&"birdseed", 1.0, &"acorn_mast_shower")
		&"cherry_petal_rain":
			_register_timed_buff(syn_id, dur, [
				_make_mod(&"syn_sakura_move", &"worker_move_speed", &"all", StatModifierData.Operation.MUL_ADD, mag),
				_make_mod(&"syn_sakura_atk", &"worker_attack_rate", &"all", StatModifierData.Operation.MUL_ADD, mag)
			])
		&"sugarbush_sap_flow":
			_register_timed_buff(syn_id, dur, [
				_make_mod(&"syn_maple_coin", &"global_coin_multiplier", &"all", StatModifierData.Operation.MUL_ADD, mag)
			])
		&"boreal_frost_shatter":
			_register_timed_buff(syn_id, dur, [
				_make_mod(&"syn_fir_pen", &"bark_penetration", &"all", StatModifierData.Operation.ADD, mag)
			])
		&"monsoon_reservoir_surge":
			_register_timed_buff(syn_id, dur, [
				_make_mod(&"syn_baobab_spawn", &"species_spawn_weight", &"all", StatModifierData.Operation.MUL_ADD, mag),
				_make_mod(&"syn_baobab_mill", &"sawmill_work_speed", &"all", StatModifierData.Operation.MUL_ADD, 0.30)
			])
		&"cinnabar_dragons_blood":
			_register_timed_buff(syn_id, dur, [
				_make_mod(&"syn_socotra_crit_c", &"worker_crit_chance", &"all", StatModifierData.Operation.ADD, 0.15),
				_make_mod(&"syn_socotra_crit_d", &"worker_crit_damage", &"all", StatModifierData.Operation.ADD, mag)
			])
		&"seismic_timberfall":
			for item in living_trees:
				var other: TreeEntity = item as TreeEntity
				if other != null and is_instance_valid(other) and not other.is_felled:
					var quake_dmg: float = other.max_hp * mag
					other.apply_chop_damage(quake_dmg, 999, true, &"seismic_timberfall", 0.0)

	if is_instance_valid(EventBus):
		EventBus.synergy_triggered.emit(species_data.id, syn_id, dur)
	synergy_activated.emit(species_data.id, syn_id, dur)
	return true


func is_synergy_active(synergy_id: StringName) -> bool:
	return _active_timers.has(synergy_id)


func tick_synergies(delta: float) -> void:
	var expired: Array[StringName] = []
	for syn_id in _active_timers.keys():
		var entry: Dictionary = _active_timers[syn_id]
		var rem: float = float(entry.get("remaining", 0.0)) - delta
		if rem <= 0.0:
			expired.append(syn_id)
		else:
			entry["remaining"] = rem
	for syn_id in expired:
		var entry: Dictionary = _active_timers[syn_id]
		var sources: Array = entry.get("sources", [])
		for src in sources:
			StatAggregator.remove_modifier(src)
		_active_timers.erase(syn_id)
		synergy_expired.emit(syn_id)


func _register_timed_buff(synergy_id: StringName, duration_s: float, mods: Array[StatModifierData]) -> void:
	var sources: Array[StringName] = []
	for mod in mods:
		var src_id: StringName = StringName("synergy:%s:%s" % [synergy_id, mod.modifier_id])
		StatAggregator.register_modifier(src_id, mod, 1, true, true)
		sources.append(src_id)
	_active_timers[synergy_id] = {
		"remaining": maxf(0.1, duration_s),
		"sources": sources,
	}


func _make_mod(
	mod_id: StringName,
	domain: StringName,
	key: StringName,
	op: StatModifierData.Operation,
	constant_val: float
) -> StatModifierData:
	var curve := FormulaCurve.new()
	curve.kind = FormulaCurve.Kind.CONSTANT
	curve.base = constant_val
	var mod := StatModifierData.new()
	mod.modifier_id = mod_id
	mod.target_domain = domain
	mod.stat_key = key
	mod.operation = op
	mod.curve = curve
	return mod
