class_name SawmillModule
extends GameModule
## Loop 2: Self-Contained Water-Powered Sawmill.
## Requires zero input materials. Assigned Simple Lumberjacks process each tree species'
## station to continuously raise that species' individual base coin value multiplier
## on StatAggregator (target_domain = &"species_coin_value") and generate processed_logs
## spent exclusively inside the Sawmill to upgrade:
##   1. Species base coin value & station slots (mill_<species>)
##   2. Quantity of Simple Lumberjacks sent to work in the Sawmill (mill_crew_quarters)
##   3. Sawmill working speed (mill_undershot_wheel, mill_gang_saw, mill_hydraulic_carriage, etc.)

var wallet: WalletModule
var roster_dispatcher: RosterDispatcher

var _species_cycles: Dictionary = {}        # StringName (species_id) -> float
var _species_process_bonus: Dictionary = {} # StringName (species_id) -> float


func _init() -> void:
	module_id = &"sawmill"


func _ready() -> void:
	is_active = true


func bind_dependencies(external_wallet: WalletModule, external_dispatcher: RosterDispatcher) -> void:
	wallet = external_wallet
	roster_dispatcher = external_dispatcher


func _process(delta: float) -> void:
	if is_active:
		tick(delta)


func tick(delta: float) -> void:
	if delta <= 0.0 or roster_dispatcher == null:
		return

	var work_speed: float = get_effective_work_speed()
	var value_rate: float = StatAggregator.query(&"sawmill_value_rate", &"all", 1.0)
	var logs_yield_mult: float = StatAggregator.query(&"sawmill_logs_yield", &"all", 1.0)
	var idle_baseline: float = StatAggregator.query(&"sawmill_idle_baseline", &"all", 0.0)

	var total_logs_generated: float = 0.0

	for sid in Balance.species_ids():
		var assigned: int = roster_dispatcher.get_station_assigned(sid)
		var active_workers: float = float(assigned) + idle_baseline
		if active_workers <= 0.0:
			continue

		var cycle_advance: float = active_workers * work_speed * delta
		var new_cycles: float = float(_species_cycles.get(sid, 0.0)) + cycle_advance
		_species_cycles[sid] = new_cycles

		var bonus: float = 0.20 * log(1.0 + new_cycles) * value_rate
		_species_process_bonus[sid] = bonus
		_register_species_value_modifier(sid, bonus)

		total_logs_generated += cycle_advance * logs_yield_mult

	if total_logs_generated > 0.0 and wallet != null:
		wallet.add_currency(&"processed_logs", total_logs_generated, &"sawmill")


func get_effective_work_speed() -> float:
	var mill_speed: float = StatAggregator.query(&"sawmill_work_speed", &"all", 1.0)
	var global_speed: float = StatAggregator.query(&"global_work_speed", &"all", 1.0)
	return maxf(0.05, mill_speed * global_speed)


func get_species_cycles(species_id: StringName) -> float:
	return float(_species_cycles.get(species_id, 0.0))


func get_species_processing_bonus(species_id: StringName) -> float:
	return float(_species_process_bonus.get(species_id, 0.0))


func reset_for_breakthrough() -> void:
	for sid in _species_cycles.keys():
		StatAggregator.remove_modifier(StringName("sawmill_process:%s" % String(sid)))
	_species_cycles.clear()
	_species_process_bonus.clear()
	if roster_dispatcher != null:
		roster_dispatcher.reset_for_breakthrough()


func _register_species_value_modifier(species_id: StringName, bonus_value: float) -> void:
	var curve := FormulaCurve.new()
	curve.kind = FormulaCurve.Kind.LINEAR
	curve.base = bonus_value
	curve.scale = 0.0

	var mod := StatModifierData.new()
	mod.modifier_id = &"sawmill_active_process"
	mod.target_domain = &"species_coin_value"
	mod.stat_key = species_id
	mod.operation = StatModifierData.Operation.MUL_ADD
	mod.curve = curve

	StatAggregator.register_modifier(
		StringName("sawmill_process:%s" % String(species_id)),
		mod,
		1,
		false,
		true
	)
