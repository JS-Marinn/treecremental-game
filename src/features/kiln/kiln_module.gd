class_name KilnModule
extends GameModule
## Loop 3: Brick Charcoal Kilns & Steam Boiler Thermal Overclock.
## Runs self-contained carbonization cycles producing Charcoal and Ash, and drives
## the Steam Boiler Thermal Overclock gauge (thermal_pressure in [0.0, 1.0]) which
## registers a dynamic global_work_speed multiplier on StatAggregator.

signal cycle_completed(charcoal_gained: float, ash_gained: float)
signal thermal_pressure_changed(new_pressure: float, speed_bonus: float)

const BASE_CYCLE_DURATION_S: float = 5.0

var wallet: WalletModule
var cycle_progress: float = 0.0 # [0.0, 1.0]
var thermal_pressure: float = 0.0 # [0.0, 1.0]
var total_cycles_completed: int = 0


func _init() -> void:
	module_id = &"charcoal_kilns"


func _ready() -> void:
	is_active = true
	_update_overclock_modifier()


func bind_wallet(external_wallet: WalletModule) -> void:
	wallet = external_wallet


func _process(delta: float) -> void:
	if is_active:
		tick(delta)


func tick(delta: float) -> void:
	if delta <= 0.0:
		return

	# 1. Advance carbonization cycle
	var eff_duration: float = get_effective_cycle_duration_s()
	cycle_progress += delta / eff_duration
	while cycle_progress >= 1.0:
		cycle_progress -= 1.0
		_complete_carbonization_cycle()

	# 2. Update Steam Boiler thermal pressure decay & floor
	var retention: float = maxf(0.0, StatAggregator.query(&"kiln_boiler_retention", &"all", 0.0))
	var floor_pressure: float = clampf(StatAggregator.query(&"kiln_boiler_floor", &"all", 0.0), 0.0, 1.0)
	var decay_rate: float = 0.05 / (1.0 + retention)
	var prev_pressure: float = thermal_pressure
	thermal_pressure = maxf(floor_pressure, thermal_pressure - decay_rate * delta)
	if not is_equal_approx(prev_pressure, thermal_pressure):
		_update_overclock_modifier()


func stoke_boiler(boost: float = 0.35) -> void:
	var floor_pressure: float = clampf(StatAggregator.query(&"kiln_boiler_floor", &"all", 0.0), 0.0, 1.0)
	thermal_pressure = clampf(maxf(thermal_pressure, floor_pressure) + boost, floor_pressure, 1.0)
	_update_overclock_modifier()


func get_effective_cycle_duration_s() -> float:
	var cycle_speed: float = StatAggregator.query(&"kiln_cycle_speed", &"all", 1.0)
	var global_speed: float = StatAggregator.query(&"global_work_speed", &"all", 1.0)
	return maxf(0.25, BASE_CYCLE_DURATION_S / maxf(0.1, cycle_speed * global_speed))


func get_overclock_speed_bonus() -> float:
	return 0.50 * thermal_pressure


func reset_for_breakthrough() -> void:
	cycle_progress = 0.0
	total_cycles_completed = 0
	var floor_pressure: float = clampf(StatAggregator.query(&"kiln_boiler_floor", &"all", 0.0), 0.0, 1.0)
	thermal_pressure = floor_pressure
	_update_overclock_modifier()


func _complete_carbonization_cycle() -> void:
	total_cycles_completed += 1
	var charcoal_mult: float = StatAggregator.query(&"kiln_charcoal_yield", &"all", 1.0)
	var ash_flat: float = StatAggregator.query(&"kiln_ash_yield", &"all", 0.0)
	var ash_purity: float = StatAggregator.query(&"kiln_ash_purity", &"all", 1.0)

	var charcoal_amount: float = 1.0 * charcoal_mult
	var ash_amount: float = (0.25 + ash_flat) * ash_purity

	if wallet != null:
		wallet.add_currency(&"charcoal", charcoal_amount, &"charcoal_kilns")
		wallet.add_currency(&"ash", ash_amount, &"charcoal_kilns")

	# Auto-stoke pulse on each cycle completion (amplified by kiln_auto_stoker / retention)
	var retention: float = maxf(0.0, StatAggregator.query(&"kiln_boiler_retention", &"all", 0.0))
	stoke_boiler(0.18 + 0.12 * retention)
	cycle_completed.emit(charcoal_amount, ash_amount)


func _update_overclock_modifier() -> void:
	var bonus: float = get_overclock_speed_bonus()
	var curve := FormulaCurve.new()
	curve.kind = FormulaCurve.Kind.LINEAR
	curve.base = bonus
	curve.scale = 0.0

	var mod := StatModifierData.new()
	mod.modifier_id = &"boiler_thermal_overclock"
	mod.target_domain = &"global_work_speed"
	mod.stat_key = &"all"
	mod.operation = StatModifierData.Operation.MUL_ADD
	mod.curve = curve

	StatAggregator.register_modifier(&"kiln_boiler_overclock", mod, 1, false, true)
	thermal_pressure_changed.emit(thermal_pressure, bonus)
