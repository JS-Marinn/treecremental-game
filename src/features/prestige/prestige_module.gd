class_name PrestigeModule
extends GameModule
## Manages 3-Act Breakthrough Gates, Heartwood Sap gain evaluation, lifetime Sap
## resonance multipliers, and full Breakthrough reset orchestration across all modules.

var main_screen: MainScreen
var sawmill_module: SawmillModule
var kiln_module: KilnModule
var logging_camp: LoggingCampModule


func _init() -> void:
	module_id = &"prestige"


func _ready() -> void:
	is_active = true


func bind_dependencies(
	screen: MainScreen,
	sawmill: SawmillModule = null,
	kiln: KilnModule = null,
	camp: LoggingCampModule = null
) -> void:
	main_screen = screen
	sawmill_module = sawmill
	kiln_module = kiln
	logging_camp = camp
	_sync_lifetime_sap_modifier()


func compute_pending_sap(run_coins: float = -1.0) -> float:
	if Balance.config == null or Balance.config.sap_gain == null:
		return 0.0
	var coins: float = run_coins
	if coins < 0.0 and main_screen != null and main_screen.wallet != null:
		coins = main_screen.wallet.run_coins_earned
	var base_sap: float = Balance.config.sap_gain.evaluate(maxf(0.0, coins))
	var sap_mult: float = StatAggregator.query(&"sap_gain_multiplier", &"all", 1.0)
	return floorf(base_sap * sap_mult)


func can_breakthrough() -> bool:
	if main_screen == null or main_screen.wallet == null or Balance.config == null:
		return false
	var gate_coins: float = Balance.config.get_gate_coins(main_screen.current_act_index)
	var min_sap: float = Balance.config.prestige_min_sap
	return main_screen.wallet.run_coins_earned >= gate_coins or compute_pending_sap() >= min_sap


func execute_breakthrough() -> float:
	if main_screen == null or main_screen.wallet == null:
		return 0.0
	var wallet: WalletModule = main_screen.wallet
	var pending: float = compute_pending_sap(wallet.run_coins_earned)
	if pending <= 0.0:
		return 0.0

	wallet.add_currency(&"sap", pending, &"heartwood_ascension")
	main_screen.current_act_index = mini(2, main_screen.current_act_index + 1)

	StatAggregator.reset_for_breakthrough()
	_sync_lifetime_sap_modifier()

	if sawmill_module != null:
		sawmill_module.reset_for_breakthrough()
	elif main_screen.roster_dispatcher != null:
		main_screen.roster_dispatcher.reset_for_breakthrough()

	if kiln_module != null:
		kiln_module.reset_for_breakthrough()

	var start_coins: float = StatAggregator.query(&"starting_coins", &"all", 0.0)
	wallet.reset_for_breakthrough(start_coins)
	main_screen.reset_in_run_upgrades_for_breakthrough()

	if logging_camp != null:
		logging_camp.sync_workers_from_stat_aggregator(main_screen._get_total_sawmill_assigned())
		logging_camp.fill_clearing_to_capacity()

	if is_instance_valid(EventBus):
		EventBus.prestige_performed.emit(pending, wallet.get_balance(&"sap"))
		EventBus.breakthrough_reached.emit(main_screen.current_act_index)
	return pending


func _sync_lifetime_sap_modifier() -> void:
	if main_screen == null or main_screen.wallet == null or Balance.config == null or Balance.config.sap_multiplier == null:
		return
	var life_sap: float = main_screen.wallet.lifetime_sap
	var mult: float = Balance.config.sap_multiplier.evaluate(life_sap)

	var curve := FormulaCurve.new()
	curve.kind = FormulaCurve.Kind.LINEAR
	curve.base = maxf(1.0, mult)
	curve.scale = 0.0

	var mod := StatModifierData.new()
	mod.modifier_id = &"lifetime_sap_resonance"
	mod.target_domain = &"global_coin_multiplier"
	mod.stat_key = &"all"
	mod.operation = StatModifierData.Operation.MUL_COMPOUND
	mod.curve = curve

	StatAggregator.register_modifier(&"lifetime_sap_resonance", mod, 1, false, false)
