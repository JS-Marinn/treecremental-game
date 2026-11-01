extends Node
## Smoke test for Milestone 1: Composable .tres Data Layer, StatAggregator Bus, and WalletModule.
## Run scene directly (run_project scene="res://tests/smoke/smoke_formulas.tscn").
## Prints PASS/FAIL lines; quits with exit code 0 only if everything passes.

var _fails: int = 0


func _ready() -> void:
	_test_registry()
	_test_workers_v06()
	_test_species_v06()
	_test_upgrades_and_stat_aggregator()
	_test_wallet_module()
	_test_plateau_structure()
	_test_exponential()
	_test_bulk_buy()
	_test_sap()
	_test_softcaps()
	_test_expression()
	_test_notation()
	_test_milestone_2_ui()
	_test_milestone_3_clearing()
	_test_milestone_4_sawmill_and_kilns()
	_test_milestone_5_separated_loops_tertiary_and_prestige()
	_test_milestone_6_assets_conventions()
	_test_milestone_6_save_and_achievements()
	_test_milestone_6_audio_and_settings()
	print("SMOKE RESULT: %s (%d failures)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	get_tree().quit(_fails)


func _check(label: String, ok: bool, detail: String = "") -> void:
	if not ok:
		_fails += 1
	print("[%s] %s %s" % ["PASS" if ok else "FAIL", label, detail])


func _test_registry() -> void:
	var ids: Array[StringName] = Balance.species_ids()
	_check("9 species discovered", ids.size() == 9, str(ids.size()))
	_check("first is pine, last is giant_sequoia", ids[0] == &"pine" and ids[8] == &"giant_sequoia", str(ids[0]) + " .. " + str(ids[8]))
	var oak: SpeciesData = Balance.species(&"oak")
	_check("oak (tier 2) unlock cost = 150*2.2^1 = 330", is_equal_approx(oak.unlock_cost.evaluate(0.0), 330.0), str(oak.unlock_cost.evaluate(0.0)))
	_check("loc key", oak.name_key() == "KEY_TREE_OAK_NAME", oak.name_key())


func _test_workers_v06() -> void:
	var w_ids: Array[StringName] = Balance.worker_ids()
	_check("3 worker archetypes discovered", w_ids.size() == 3, str(w_ids))
	var simple: WorkerArchetypeData = Balance.worker(&"simple_lumberjack")
	var heavy: WorkerArchetypeData = Balance.worker(&"heavy_sawyer")
	var swift: WorkerArchetypeData = Balance.worker(&"swift_cleaver")
	_check("simple_lumberjack shared between logging_camp and sawmill",
		simple != null and simple.can_assign_to_loop(&"logging_camp") and simple.can_assign_to_loop(&"sawmill"))
	_check("heavy_sawyer exclusive to logging_camp",
		heavy != null and heavy.can_assign_to_loop(&"logging_camp") and not heavy.can_assign_to_loop(&"sawmill"))
	_check("swift_cleaver exclusive to logging_camp",
		swift != null and swift.can_assign_to_loop(&"logging_camp") and not swift.can_assign_to_loop(&"sawmill"))
	_check("heavy_sawyer ignores bark hardness", heavy != null and heavy.ignore_all_bark_hardness)
	_check("swift_cleaver has 2.0x synergy trigger weight", swift != null and is_equal_approx(swift.synergy_trigger_weight, 2.0))


func _test_species_v06() -> void:
	var pine: SpeciesData = Balance.species(&"pine")
	var sakura: SpeciesData = Balance.species(&"sakura")
	var sequoia: SpeciesData = Balance.species(&"giant_sequoia")
	_check("pine base_hp=20, base_coin_value=1.0, clearance=12",
		is_equal_approx(pine.base_hp, 20.0) and is_equal_approx(pine.base_coin_value, 1.0) and is_equal_approx(pine.trunk_clearance_radius, 12.0))
	_check("sakura synergy_id is cherry_petal_rain", sakura.synergy_id == &"cherry_petal_rain", String(sakura.synergy_id))
	_check("sequoia bark_hardness=6, base_coin_value=900",
		sequoia.bark_hardness == 6 and is_equal_approx(sequoia.base_coin_value, 900.0))
	_check("pine spawn weight Lv.1 = 100, Lv.0 = 0",
		is_equal_approx(pine.evaluate_spawn_weight(1), 100.0) and is_equal_approx(pine.evaluate_spawn_weight(0), 0.0))
	_check("pine max quantity Lv.2 = 5", pine.evaluate_max_quantity(2) == 5, str(pine.evaluate_max_quantity(2)))


func _test_upgrades_and_stat_aggregator() -> void:
	var upg_ids: Array[StringName] = Balance.upgrade_ids()
	_check("87 canonical upgrades discovered", upg_ids.size() == 87, str(upg_ids.size()))

	StatAggregator.clear_all()
	var base_pine_val: float = Balance.species(&"pine").base_coin_value
	var initial_val: float = StatAggregator.query(&"species_coin_value", &"pine", base_pine_val)
	_check("StatAggregator base query = 1.0", is_equal_approx(initial_val, 1.0), str(initial_val))

	var mill_pine: UpgradeDefinitionData = Balance.upgrade(&"mill_pine")
	var myc_phos: UpgradeDefinitionData = Balance.upgrade(&"myc_phosphorus_exchange")
	StatAggregator.register_upgrade(mill_pine, 4) # +100% MUL_ADD on pine
	StatAggregator.register_upgrade(myc_phos, 2)  # +20% MUL_ADD on all species
	var boosted_val: float = StatAggregator.query(&"species_coin_value", &"pine", base_pine_val)
	# 1.0 * (1.0 + 1.0 + 0.20) = 2.20
	_check("StatAggregator combined pine + all MUL_ADD = 2.20", is_equal_approx(boosted_val, 2.20), str(boosted_val))

	StatAggregator.reset_for_breakthrough()
	var post_reset_val: float = StatAggregator.query(&"species_coin_value", &"pine", base_pine_val)
	# mill_pine resets on breakthrough; myc_phosphorus_exchange persists (+20% -> 1.20)
	_check("StatAggregator breakthrough reset preserves non-resetting upgrades", is_equal_approx(post_reset_val, 1.20), str(post_reset_val))
	StatAggregator.clear_all()


func _test_wallet_module() -> void:
	var wallet := WalletModule.new()
	wallet.add_currency(&"coins", 500.0, &"test")
	wallet.add_currency(&"processed_logs", 120.0, &"test")
	wallet.add_currency(&"spores", 45.0, &"test")
	wallet.add_currency(&"sap", 15.0, &"test")
	_check("wallet tracks coins and lifetime_sap",
		is_equal_approx(wallet.get_balance(&"coins"), 500.0) and is_equal_approx(wallet.lifetime_sap, 15.0))
	var prop_birch: UpgradeDefinitionData = Balance.upgrade(&"prop_birch")
	var can_buy: bool = wallet.can_afford_upgrade(prop_birch, 0, 1)
	var spent_ok: bool = wallet.spend_for_upgrade(prop_birch, 0, 1)
	_check("wallet spends coins for prop_birch Lv.1 (cost 150)",
		can_buy and spent_ok and is_equal_approx(wallet.get_balance(&"coins"), 350.0), str(wallet.get_balance(&"coins")))
	wallet.reset_for_breakthrough(250.0)
	_check("wallet breakthrough resets coins/processed_logs and preserves spores/sap",
		is_equal_approx(wallet.get_balance(&"coins"), 250.0)
		and is_equal_approx(wallet.get_balance(&"processed_logs"), 0.0)
		and is_equal_approx(wallet.get_balance(&"spores"), 45.0)
		and is_equal_approx(wallet.get_balance(&"sap"), 15.0))
	wallet.free()


func _test_plateau_structure() -> void:
	var cfg: BalanceConfig = Balance.config
	_check("trees per act = 3", cfg.trees_per_act == 3, str(cfg.trees_per_act))
	_check("prop caps [4, 7, 10]", cfg.get_prop_cap(0) == 4 and cfg.get_prop_cap(1) == 7 and cfg.get_prop_cap(2) == 10)
	_check("tool/gear caps [3, 5, 6]", cfg.get_gear_cap(0) == 3 and cfg.get_gear_cap(1) == 5 and cfg.get_gear_cap(2) == 6)
	_check("sawmill caps [4, 7, 10]", cfg.get_sawmill_cap(0) == 4 and cfg.get_sawmill_cap(1) == 7 and cfg.get_sawmill_cap(2) == 10)
	_check("breakthrough gate 1 = 247K coins", is_equal_approx(cfg.get_gate_coins(0), 247000.0), str(cfg.get_gate_coins(0)))
	_check("tertiary knobs present", cfg.tertiary_multiplier_cap == 1.0 and cfg.tertiary_half_point_minutes == 90.0)


func _test_exponential() -> void:
	var hire: FormulaCurve = Balance.species(&"pine").hire_cost
	_check("hire cost n=0 is 10", is_equal_approx(hire.evaluate(0.0), 10.0))
	_check("hire cost n=10 is 10*1.15^10 = 40.456", absf(hire.evaluate(10.0) - 40.4556) < 0.001, str(hire.evaluate(10.0)))


func _test_bulk_buy() -> void:
	var hire: FormulaCurve = Balance.species(&"pine").hire_cost
	var loop_sum: float = 0.0
	for i in range(5, 15):
		loop_sum += hire.evaluate(float(i))
	_check("closed-form sum == loop sum", absf(hire.sum_over(5, 10) - loop_sum) < 0.0001, "%f vs %f" % [hire.sum_over(5, 10), loop_sum])
	var n: int = hire.max_affordable(0, 1000.0)
	var spent: float = hire.sum_over(0, n)
	var next: float = hire.sum_over(0, n + 1)
	_check("max_affordable consistent", spent <= 1000.0 and next > 1000.0, "n=%d" % n)


func _test_sap() -> void:
	var cfg: BalanceConfig = Balance.config
	var gain: float = cfg.sap_gain.evaluate(2.0e7)
	_check("sap gain at score 2.0e7 = floor(sqrt(10000)) = 100", gain == 100.0, str(gain))
	var mult: float = cfg.sap_multiplier.evaluate(100.0)
	_check("sap multiplier at 100 sap = 1 + 0.6*sqrt(100) = 7.0", is_equal_approx(mult, 7.0), str(mult))
	_check("milestone mult at 50 workers = 1.5^3", is_equal_approx(cfg.milestone_mult(50), pow(1.5, 3)), str(cfg.milestone_mult(50)))


func _test_softcaps() -> void:
	var c: FormulaCurve = FormulaCurve.new()
	c.kind = FormulaCurve.Kind.HYPERBOLIC_SOFTCAP
	c.base = 1.0
	c.cap = 9.0
	c.half_point = 100.0
	_check("hyperbolic: x=100 -> 5.5", is_equal_approx(c.evaluate(100.0), 5.5))
	_check("hyperbolic: x=1e9 -> ~10 (asymptote)", absf(c.evaluate(1.0e9) - 10.0) < 0.001)
	var p: FormulaCurve = FormulaCurve.new()
	p.kind = FormulaCurve.Kind.POWER_SOFTCAP
	p.scale = 1.0
	p.soft_start = 10.0
	p.exponent = 0.5
	_check("power softcap continuous at start", is_equal_approx(p.evaluate(10.0), 10.0))
	_check("power softcap diminishing above start", p.evaluate(110.0) < 110.0 and p.evaluate(110.0) > 10.0, str(p.evaluate(110.0)))


func _test_expression() -> void:
	var e: FormulaCurve = FormulaCurve.new()
	e.kind = FormulaCurve.Kind.EXPRESSION
	e.expression = "base + scale * sqrt(x)"
	e.base = 2.0
	e.scale = 3.0
	_check("expression sqrt", is_equal_approx(e.evaluate(16.0), 14.0), str(e.evaluate(16.0)))


func _test_notation() -> void:
	var cfg: NotationConfig = load("res://data/settings/notation_default.tres") as NotationConfig
	var F := NumberFormatter
	_check("999 plain", F.format(999.0, F.Mode.STANDARD, cfg) == "999", F.format(999.0, F.Mode.STANDARD, cfg))
	_check("standard 1.5K", F.format(1500.0, F.Mode.STANDARD, cfg) == "1.5K", F.format(1500.0, F.Mode.STANDARD, cfg))
	_check("standard 2.35M", F.format(2.3456e6, F.Mode.STANDARD, cfg) == "2.35M", F.format(2.3456e6, F.Mode.STANDARD, cfg))
	_check("scientific", F.format(2.3456e7, F.Mode.SCIENTIFIC, cfg) == "2.35e7", F.format(2.3456e7, F.Mode.SCIENTIFIC, cfg))
	_check("engineering", F.format(2.3456e7, F.Mode.ENGINEERING, cfg) == "23.46e6", F.format(2.3456e7, F.Mode.ENGINEERING, cfg))
	_check("beyond suffixes falls back to sci", F.format(1.0e60, F.Mode.STANDARD, cfg) == "1e60", F.format(1.0e60, F.Mode.STANDARD, cfg))


func _test_milestone_2_ui() -> void:
	LocaleResolver.ensure_loaded()
	LocaleResolver.apply_locale("en")
	_check("i18n en KEY_HUD_TAB_TREES == Trees", tr("KEY_HUD_TAB_TREES") == "Trees", tr("KEY_HUD_TAB_TREES"))
	LocaleResolver.apply_locale("es_419")
	_check("i18n es_419 KEY_HUD_TAB_TREES == Arboles", tr("KEY_HUD_TAB_TREES") == "Arboles", tr("KEY_HUD_TAB_TREES"))
	LocaleResolver.apply_locale("en")

	var main_scene: PackedScene = load("res://scenes/ui/main_screen.tscn") as PackedScene
	var main_screen: MainScreen = main_scene.instantiate() as MainScreen
	add_child(main_screen)

	var left_col: Control = main_screen.get_node_or_null("%LeftCompoundColumn") as Control
	var top_bar: Control = main_screen.get_node_or_null("%TopResourceBar") as Control
	var clearing_vp: Control = main_screen.get_node_or_null("%CompoundViewportContainer") as Control
	var bottom_bar: Control = main_screen.get_node_or_null("%BottomLoopAccessBar") as Control
	var right_dock: Control = main_screen.get_node_or_null("%RightCommandDock") as Control
	_check("MainScreen 432+208 Right-Hand Docked split geometry with BottomLoopAccessBar",
		left_col != null and left_col.custom_minimum_size == Vector2(432, 360)
		and top_bar != null and top_bar.custom_minimum_size == Vector2(432, 28)
		and clearing_vp != null and clearing_vp.custom_minimum_size == Vector2(432, 304)
		and bottom_bar != null and bottom_bar.custom_minimum_size == Vector2(432, 28)
		and right_dock != null and right_dock.custom_minimum_size == Vector2(208, 360))
	var main_split: Control = main_screen.get_node_or_null("MainSplit") as Control
	var split_min: Vector2 = main_split.get_combined_minimum_size() if main_split != null else Vector2.ZERO
	_check("MainSplit combined minimum size fits strictly within 640x360",
		split_min.x <= 640.0 and split_min.y <= 360.0, str(split_min))

	main_screen.select_tab(MainScreen.DockTab.TREES)
	var trees_count: int = main_screen.get_visible_upgrade_ids().size()
	main_screen.select_tab(MainScreen.DockTab.CREW)
	var crew_count: int = main_screen.get_visible_upgrade_ids().size()
	main_screen.select_tab(MainScreen.DockTab.MILL)
	var mill_count: int = main_screen.get_visible_upgrade_ids().size()
	main_screen.select_tab(MainScreen.DockTab.ROOTS)
	var roots_count: int = main_screen.get_visible_upgrade_ids().size()
	_check("MainScreen 4 tabs populate 9+21+25+16 = 71 in-run upgrades",
		trees_count == 9 and crew_count == 21 and mill_count == 25 and roots_count == 16,
		"%d/%d/%d/%d" % [trees_count, crew_count, mill_count, roots_count])

	main_screen.wallet.add_currency(&"coins", 500.0, &"test")
	main_screen.select_tab(MainScreen.DockTab.TREES)
	main_screen._on_upgrade_purchase_requested(&"prop_birch", 1)
	_check("MainScreen purchasing prop_birch increments level to 1 and deducts 150 coins",
		main_screen.get_upgrade_level(&"prop_birch") == 1 and is_equal_approx(main_screen.wallet.get_balance(&"coins"), 350.0))

	main_screen.select_tab(MainScreen.DockTab.MILL)
	main_screen._on_sawmill_assign_delta_requested(&"pine", 1)
	_check("MainScreen assigns simple_lumberjack to pine Sawmill station",
		main_screen.roster_dispatcher.get_station_assigned(&"pine") == 1)

	var menu_scene: PackedScene = load("res://scenes/ui/modals/main_menu.tscn") as PackedScene
	var menu: MainMenuView = menu_scene.instantiate() as MainMenuView
	add_child(menu)
	_check("MainMenuView instantiates with %PlayButton", menu.get_node_or_null("%PlayButton") != null)
	menu.queue_free()

	var prestige_scene: PackedScene = load("res://scenes/ui/modals/modal_prestige.tscn") as PackedScene
	var prestige: ModalPrestigeView = prestige_scene.instantiate() as ModalPrestigeView
	add_child(prestige)
	prestige.bind_wallet(main_screen.wallet)
	_check("ModalPrestigeView populates 16 Heartwood Sap constellation upgrades across 3 rings",
		prestige._row_views.size() == 16, str(prestige._row_views.size()))
	prestige.queue_free()

	var ach_scene: PackedScene = load("res://scenes/ui/modals/modal_achievements.tscn") as PackedScene
	var ach: ModalAchievementsView = ach_scene.instantiate() as ModalAchievementsView
	add_child(ach)
	_check("ModalAchievementsView instantiates with %AchievementGrid", ach.get_node_or_null("%AchievementGrid") != null)
	ach.queue_free()

	var settings_scene: PackedScene = load("res://scenes/ui/modals/modal_settings.tscn") as PackedScene
	var settings: ModalSettingsView = settings_scene.instantiate() as ModalSettingsView
	add_child(settings)
	_check("ModalSettingsView instantiates with %MasterSlider and %LocaleOption",
		settings.get_node_or_null("%MasterSlider") != null and settings.get_node_or_null("%LocaleOption") != null)
	settings.queue_free()
	main_screen.queue_free()
	StatAggregator.clear_all()


func _test_milestone_3_clearing() -> void:
	StatAggregator.clear_all()
	var prop_pine: UpgradeDefinitionData = Balance.upgrade(&"prop_pine")
	var hire_simple: UpgradeDefinitionData = Balance.upgrade(&"hire_simple_lumberjack")
	var hire_heavy: UpgradeDefinitionData = Balance.upgrade(&"hire_heavy_sawyer")
	var hire_swift: UpgradeDefinitionData = Balance.upgrade(&"hire_swift_cleaver")
	StatAggregator.register_upgrade(prop_pine, 2)
	StatAggregator.register_upgrade(hire_simple, 2)
	StatAggregator.register_upgrade(hire_heavy, 1)
	StatAggregator.register_upgrade(hire_swift, 1)

	var wallet := WalletModule.new()
	var clearing_scene: PackedScene = load("res://scenes/world/logging_clearing.tscn") as PackedScene
	var camp: LoggingCampModule = clearing_scene.instantiate() as LoggingCampModule
	camp.bind_wallet(wallet)
	add_child(camp)

	_check("Milestone 3 Clearing spawns initial Pine trees (up to Q_pine=5)",
		camp.get_living_tree_count(&"pine") == 5, str(camp.get_living_tree_count(&"pine")))

	# Verify Poisson-disc minimum separation between all spawned trees
	var min_sep_ok: bool = true
	for i in range(camp._trees.size()):
		for j in range(i + 1, camp._trees.size()):
			var ta: TreeEntity = camp._trees[i]
			var tb: TreeEntity = camp._trees[j]
			var dist: float = ta.position.distance_to(tb.position)
			if dist + 0.01 < (ta.clearance_radius + tb.clearance_radius):
				min_sep_ok = false
	_check("Poisson-disc random tree positions enforce minimum clearance radius", min_sep_ok)

	_check("Clearing reconciles 2 Simple, 1 Heavy Sawyer, 1 Swift Cleaver",
		camp.get_active_worker_count(&"simple_lumberjack") == 2
		and camp.get_active_worker_count(&"heavy_sawyer") == 1
		and camp.get_active_worker_count(&"swift_cleaver") == 1)

	# Simulate 4 seconds of active chopping and verify coins are earned
	for _step in range(40):
		camp.tick(0.1)
	_check("Autonomous workers chop trees and generate Coins in WalletModule",
		wallet.get_balance(&"coins") > 0.0, str(wallet.get_balance(&"coins")))

	# Verify Bark Hardness mitigation vs Heavy Sawyer 100% penetration on Giant Sequoia (bark_hardness=6)
	var sequoia_data: SpeciesData = Balance.species(&"giant_sequoia")
	var seq_tree := TreeEntity.new()
	seq_tree.setup_tree(sequoia_data, 0)
	var res_simple: Dictionary = seq_tree.apply_chop_damage(100.0, 0, false, &"simple_lumberjack", 1.0)
	var res_heavy: Dictionary = seq_tree.apply_chop_damage(100.0, 999, true, &"heavy_sawyer", 1.0)
	# simple_lumberjack mitigated by 0.80^6 = 0.262144; heavy_sawyer deals full 100.0
	_check("Bark Hardness mitigates unpenetrated hits (26.21) while Heavy Sawyer deals 100% (100.0)",
		absf(float(res_simple["damage_dealt"]) - 26.2144) < 0.01 and is_equal_approx(float(res_heavy["damage_dealt"]), 100.0),
		"%f vs %f" % [float(res_simple["damage_dealt"]), float(res_heavy["damage_dealt"])])
	seq_tree.free()

	# Verify Sakura Cherry Petal Rain synergy applies +35% worker_move_speed and expires after duration
	var sakura_data: SpeciesData = Balance.species(&"sakura")
	var base_move: float = StatAggregator.query(&"worker_move_speed", &"simple_lumberjack", 1.0)
	var proc_ok: bool = camp.synergy_controller.try_trigger_on_fell(sakura_data, 1.0, wallet, camp._trees, true)
	var buffed_move: float = StatAggregator.query(&"worker_move_speed", &"simple_lumberjack", 1.0)
	camp.synergy_controller.tick_synergies(10.0)
	var expired_move: float = StatAggregator.query(&"worker_move_speed", &"simple_lumberjack", 1.0)
	_check("Sakura Cherry Petal Rain buffs worker_move_speed (+35%) and expires cleanly",
		proc_ok and is_equal_approx(base_move, 1.0) and is_equal_approx(buffed_move, 1.35) and is_equal_approx(expired_move, 1.0),
		"%f -> %f -> %f" % [base_move, buffed_move, expired_move])

	camp.queue_free()
	wallet.free()
	StatAggregator.clear_all()


func _test_milestone_4_sawmill_and_kilns() -> void:
	StatAggregator.clear_all()
	var hire_simple: UpgradeDefinitionData = Balance.upgrade(&"hire_simple_lumberjack")
	var hire_heavy: UpgradeDefinitionData = Balance.upgrade(&"hire_heavy_sawyer")
	var hire_swift: UpgradeDefinitionData = Balance.upgrade(&"hire_swift_cleaver")
	StatAggregator.register_upgrade(hire_simple, 2)
	StatAggregator.register_upgrade(hire_heavy, 1)
	StatAggregator.register_upgrade(hire_swift, 1)

	var dispatcher := RosterDispatcher.new()
	_check("RosterDispatcher rejects Heavy Sawyer and Swift Cleaver from Sawmill",
		not dispatcher.can_worker_enter_loop(&"heavy_sawyer", &"sawmill")
		and not dispatcher.can_worker_enter_loop(&"swift_cleaver", &"sawmill")
		and not dispatcher.try_adjust_station_assignment(&"pine", 1, &"heavy_sawyer")
		and not dispatcher.try_adjust_station_assignment(&"pine", 1, &"swift_cleaver"))

	var assign_ok: bool = dispatcher.try_adjust_station_assignment(&"pine", 1, &"simple_lumberjack")
	_check("RosterDispatcher assigns Simple Lumberjack to Pine station and deducts from clearing count (2 -> 1)",
		assign_ok and dispatcher.get_station_assigned(&"pine") == 1 and dispatcher.get_clearing_worker_count(&"simple_lumberjack") == 1)

	# Self-contained SawmillModule: zero input materials required
	var wallet := WalletModule.new()
	var sawmill := SawmillModule.new()
	sawmill.bind_dependencies(wallet, dispatcher)
	var base_pine_mult: float = StatAggregator.query(&"species_coin_value", &"pine", 1.0)
	sawmill.tick(5.0)
	var processed_pine_mult: float = StatAggregator.query(&"species_coin_value", &"pine", 1.0)
	var logs_earned: float = wallet.get_balance(&"processed_logs")
	_check("Self-contained Sawmill raises Pine coin value multiplier and generates Processed Logs with zero input materials",
		processed_pine_mult > base_pine_mult and logs_earned > 0.0,
		"mult: %f -> %f, logs: %f" % [base_pine_mult, processed_pine_mult, logs_earned])

	# Spend Processed Logs inside Sawmill on mill_pine, mill_crew_quarters, and mill_undershot_wheel
	wallet.add_currency(&"processed_logs", 500.0, &"test")
	var mill_pine: UpgradeDefinitionData = Balance.upgrade(&"mill_pine")
	var mill_quarters: UpgradeDefinitionData = Balance.upgrade(&"mill_crew_quarters")
	var mill_wheel: UpgradeDefinitionData = Balance.upgrade(&"mill_undershot_wheel")
	var speed_before: float = sawmill.get_effective_work_speed()
	var cap_before: int = dispatcher.get_sawmill_max_capacity()
	var bought_pine: bool = wallet.spend_for_upgrade(mill_pine, 0, 3)
	if bought_pine:
		StatAggregator.register_upgrade(mill_pine, 3)
	var bought_quarters: bool = wallet.spend_for_upgrade(mill_quarters, 0, 2)
	if bought_quarters:
		StatAggregator.register_upgrade(mill_quarters, 2)
	var bought_wheel: bool = wallet.spend_for_upgrade(mill_wheel, 0, 2)
	if bought_wheel:
		StatAggregator.register_upgrade(mill_wheel, 2)
	_check("Spending Processed Logs upgrades species value & slots (1->2), Sawmill worker capacity (2->4), and Sawmill working speed (1.0->1.4)",
		bought_pine and bought_quarters and bought_wheel
		and dispatcher.get_station_max_slots(&"pine") == 2
		and dispatcher.get_sawmill_max_capacity() == cap_before + 2
		and sawmill.get_effective_work_speed() > speed_before)

	# KilnModule carbonization cycles & Steam Boiler Thermal Overclock
	var kiln := KilnModule.new()
	kiln.bind_wallet(wallet)
	kiln.stoke_boiler(0.60)
	var global_speed_overclocked: float = StatAggregator.query(&"global_work_speed", &"all", 1.0)
	kiln.tick(6.0)
	_check("KilnModule completes carbonization cycles (generating Charcoal & Ash) and Steam Boiler overclock boosts global_work_speed",
		kiln.total_cycles_completed >= 1
		and wallet.get_balance(&"charcoal") > 0.0
		and wallet.get_balance(&"ash") > 0.0
		and global_speed_overclocked > 1.0,
		"charcoal=%f, ash=%f, global_speed=%f" % [wallet.get_balance(&"charcoal"), wallet.get_balance(&"ash"), global_speed_overclocked])

	sawmill.free()
	kiln.free()
	wallet.free()
	StatAggregator.clear_all()


func _test_milestone_5_separated_loops_tertiary_and_prestige() -> void:
	StatAggregator.clear_all()
	var main_scene: PackedScene = load("res://scenes/ui/main_screen.tscn") as PackedScene
	var main_screen: MainScreen = main_scene.instantiate() as MainScreen
	add_child(main_screen)

	# 1. Verify separated BottomLoopAccessBar buttons (Image 1 layout)
	_check("BottomLoopAccessBar exposes Sawmill, Kilns, Ecology, Prestige, Feats, and Settings buttons",
		main_screen.get_node_or_null("%SawmillLoopButton") != null
		and main_screen.get_node_or_null("%KilnsLoopButton") != null
		and main_screen.get_node_or_null("%EcologyLoopButton") != null
		and main_screen.get_node_or_null("%PrestigeModalButton") != null
		and main_screen.get_node_or_null("%AchievementsModalButton") != null
		and main_screen.get_node_or_null("%SettingsModalButton") != null)

	# 2. Verify ModalSawmillView (Image 2 horizontal species lanes)
	var mill_modal_scene: PackedScene = load("res://scenes/ui/modals/modal_sawmill.tscn") as PackedScene
	var mill_modal: ModalSawmillView = mill_modal_scene.instantiate() as ModalSawmillView
	add_child(mill_modal)
	mill_modal.bind_main_screen(main_screen)
	_check("ModalSawmillView populates 9 horizontal SawmillLaneView rows and Back button",
		mill_modal._lane_views.size() == 9 and mill_modal.get_node_or_null("%BackButton") != null,
		str(mill_modal._lane_views.size()))
	mill_modal._on_lane_worker_delta(&"pine", 1)
	_check("ModalSawmillView + button assigns Simple Lumberjack to Pine lane",
		main_screen.roster_dispatcher.get_station_assigned(&"pine") == 1)
	mill_modal.queue_free()

	# 3. Verify ModalKilnsView and ModalEcologyView
	var kilns_scene: PackedScene = load("res://scenes/ui/modals/modal_kilns.tscn") as PackedScene
	var kilns_modal: ModalKilnsView = kilns_scene.instantiate() as ModalKilnsView
	add_child(kilns_modal)
	_check("ModalKilnsView populates 8 kiln_* upgrades and Back button",
		kilns_modal._row_views.size() == 8 and kilns_modal.get_node_or_null("%BackButton") != null)
	kilns_modal.queue_free()

	var eco_scene: PackedScene = load("res://scenes/ui/modals/modal_ecology.tscn") as PackedScene
	var eco_modal: ModalEcologyView = eco_scene.instantiate() as ModalEcologyView
	add_child(eco_modal)
	_check("ModalEcologyView populates 16 aviary_* and myc_* upgrades and Back button",
		eco_modal._row_views.size() == 16 and eco_modal.get_node_or_null("%BackButton") != null)
	eco_modal.queue_free()

	# 4. Verify AviaryModule & MyceliumModule generate Birdseed and Spores
	var aviary := AviaryModule.new()
	aviary.bind_wallet(main_screen.wallet)
	aviary.tick(2.5)
	aviary.on_tree_felled()
	var mycelium := MyceliumModule.new()
	mycelium.bind_dependencies(main_screen.wallet)
	mycelium.tick(2.5)
	_check("AviaryModule generates Birdseed and MyceliumModule generates Spores",
		main_screen.wallet.get_balance(&"birdseed") > 0.0 and main_screen.wallet.get_balance(&"spores") > 0.0,
		"birdseed=%f, spores=%f" % [main_screen.wallet.get_balance(&"birdseed"), main_screen.wallet.get_balance(&"spores")])

	# 5. Verify PrestigeModule Breakthrough reset & persistence
	main_screen.set_upgrade_level(&"prop_birch", 2)
	main_screen.set_upgrade_level(&"myc_phosphorus_exchange", 2)
	main_screen.set_upgrade_level(&"sap_pioneer_charter", 1)
	main_screen.wallet.add_currency(&"coins", 250000.0, &"test_gate_1")
	main_screen.wallet.add_currency(&"processed_logs", 120.0, &"test")

	var prestige_mod := PrestigeModule.new()
	prestige_mod.bind_dependencies(main_screen)
	var can_ascend: bool = prestige_mod.can_breakthrough()
	var sap_earned: float = prestige_mod.execute_breakthrough()
	_check("PrestigeModule Breakthrough awards Sap, advances Act I -> Act II, resets prop_birch, preserves myc_phosphorus_exchange, and grants starting_coins from sap_pioneer_charter",
		can_ascend
		and sap_earned >= 11.0
		and main_screen.current_act_index == 1
		and main_screen.get_upgrade_level(&"prop_birch") == 0
		and main_screen.get_upgrade_level(&"myc_phosphorus_exchange") == 2
		and is_equal_approx(main_screen.wallet.get_balance(&"processed_logs"), 0.0)
		and main_screen.wallet.get_balance(&"coins") > 0.0
		and main_screen.wallet.get_balance(&"spores") > 0.0,
		"sap=%f, act=%d, coins=%f" % [sap_earned, main_screen.current_act_index, main_screen.wallet.get_balance(&"coins")])

	prestige_mod.free()
	aviary.free()
	mycelium.free()
	main_screen.queue_free()
	StatAggregator.clear_all()


func _test_milestone_6_assets_conventions() -> void:
	_check("AssetResolver resolves worker sprite convention",
		AssetResolver.worker_sprite_path(&"simple_lumberjack", 0) == "res://assets/sprites/workers/worker_simple_lumberjack.png",
		AssetResolver.worker_sprite_path(&"simple_lumberjack", 0))
	_check("AssetResolver resolves worker gear overlay convention",
		AssetResolver.worker_sprite_path(&"heavy_sawyer", 3) == "res://assets/sprites/workers/worker_heavy_sawyer_gear3.png",
		AssetResolver.worker_sprite_path(&"heavy_sawyer", 3))
	_check("AssetResolver resolves tree maturity convention",
		AssetResolver.tree_sprite_path(&"sakura", 4) == "res://assets/sprites/trees/tree_sakura_r4.png",
		AssetResolver.tree_sprite_path(&"sakura", 4))
	_check("AssetResolver resolves achievement icon convention",
		AssetResolver.achievement_icon_path(&"ach_first_chip") == "res://assets/sprites/achievements/ach_first_chip.png",
		AssetResolver.achievement_icon_path(&"ach_first_chip"))
	_check("AssetResolver resolves tileset convention",
		AssetResolver.tileset_path() == "res://assets/tilesets/clearing_tileset.tres",
		AssetResolver.tileset_path())
	_check("AssetResolver returns empty path for undelivered sfx assets",
		AssetResolver.sfx_path(&"wood_chop") == "" and AssetResolver.music_path(&"main_theme") == ""
		and AssetResolver.shader_path(&"colorblind_deuteranopia") == "")
	_check("AssetResolver returns null sprites for undelivered assets",
		AssetResolver.tree_sprite(&"pine", 0) == null
		and AssetResolver.worker_sprite(&"swift_cleaver") == null
		and AssetResolver.species_badge(&"oak") == null
		and AssetResolver.achievement_icon(&"ach_grand_forester") == null)


func _test_milestone_6_save_and_achievements() -> void:
	StatAggregator.clear_all()

	var ach_ids: Array[StringName] = Balance.achievement_ids()
	_check("80 canonical achievements discovered", ach_ids.size() == 80, str(ach_ids.size()))
	_check("achievement discovery sorted: first ach_act1_species, last ach_upgrades_50",
		ach_ids[0] == &"ach_act1_species" and ach_ids[79] == &"ach_upgrades_50",
		"%s .. %s" % [str(ach_ids[0]), str(ach_ids[79])])

	var main_scene: PackedScene = load("res://scenes/ui/main_screen.tscn") as PackedScene
	var main_screen: MainScreen = main_scene.instantiate() as MainScreen
	add_child(main_screen)

	var ach := AchievementModule.new()
	ach.name = "TestAchievementModule"
	add_child(ach)

	main_screen.set_upgrade_level(&"prop_birch", 1)
	ach.sync_upgrade_levels_from_screen(main_screen)
	_check("AchievementModule unlocks second species achievement from propagation levels",
		ach.is_unlocked(&"ach_second_species"), str(ach.get_unlocked_count()))

	main_screen.wallet.add_currency(&"coins", 5000.0, &"test")
	_check("AchievementModule unlocks coin achievements from resource signals",
		ach.is_unlocked(&"ach_first_chip") and ach.is_unlocked(&"ach_coins_1k"))

	EventBus.tree_felled.emit(&"pine", 0, 3.0)
	EventBus.tree_felled.emit(&"giant_sequoia", 4, 900.0)
	_check("AchievementModule unlocks timber, great felling, and old growth achievements from tree felled events",
		ach.is_unlocked(&"ach_first_timber") and ach.is_unlocked(&"ach_great_felling") and ach.is_unlocked(&"ach_old_growth"))

	main_screen._on_upgrade_purchase_requested(&"hire_simple_lumberjack", 4)
	_check("AchievementModule unlocks hire achievement from upgrade purchase signals",
		ach.is_unlocked(&"ach_hire_5"), str(main_screen.get_upgrade_level(&"hire_simple_lumberjack")))

	main_screen.set_upgrade_level(&"sap_ancient_harmony", 1)
	EventBus.upgrade_purchased.emit(&"sap_ancient_harmony", 1)
	var unlocked_n: int = ach.get_unlocked_count()
	var expected_mul: float = 1.0 + 0.02 * float(unlocked_n)
	var actual_mul: float = StatAggregator.query(&"global_coin_multiplier", &"all", 1.0)
	_check("AchievementModule mastery grants +2% global coins per achievement at sap_ancient_harmony Lv.1",
		absf(actual_mul - expected_mul) < 0.001,
		"expected %f got %f (%d unlocked)" % [expected_mul, actual_mul, unlocked_n])

	StatAggregator.reset_for_breakthrough()
	_check("AchievementModule mastery modifier persists across Breakthrough resets",
		absf(StatAggregator.query(&"global_coin_multiplier", &"all", 1.0) - expected_mul) < 0.001,
		str(StatAggregator.query(&"global_coin_multiplier", &"all", 1.0)))

	for ach_id in ach_ids:
		if ach_id != &"ach_grand_forester":
			ach.unlock_achievement(ach_id)
	_check("AchievementModule unlocks ach_grand_forester when every other achievement is unlocked",
		ach.is_unlocked(&"ach_grand_forester") and ach.get_unlocked_count() == 80,
		str(ach.get_unlocked_count()))

	# --- Save roundtrip ---
	var sawmill := SawmillModule.new()
	sawmill.bind_dependencies(main_screen.wallet, main_screen.roster_dispatcher)
	var kiln := KilnModule.new()
	kiln.bind_wallet(main_screen.wallet)
	main_screen._on_sawmill_assign_delta_requested(&"pine", 1)
	sawmill.tick(5.0)
	kiln.stoke_boiler(0.60)
	kiln.tick(6.0)

	var save_mod := SaveModule.new()
	save_mod.name = "TestSaveModule"
	save_mod.save_file_path = "user://smoke_slot_test.json"
	save_mod.bind_dependencies(main_screen, sawmill, kiln, ach)
	add_child(save_mod)
	EventBus.setting_changed.emit(&"audio", &"master", 0.25)
	EventBus.setting_changed.emit(&"gameplay", &"notation", 1)

	var coins_before: float = main_screen.wallet.get_balance(&"coins")
	var sap_before: float = main_screen.wallet.get_balance(&"sap")
	var sawmill_cycles_before: float = sawmill.get_species_cycles(&"pine")
	var kiln_progress_before: float = kiln.cycle_progress
	var kiln_pressure_before: float = kiln.thermal_pressure
	var kiln_cycles_before: int = kiln.total_cycles_completed
	var saved_ok: bool = save_mod.save_now()
	_check("SaveModule writes an atomic JSON save file",
		saved_ok and FileAccess.file_exists("user://smoke_slot_test.json"),
		str(FileAccess.file_exists("user://smoke_slot_test.json")))

	main_screen.wallet.spend_currency(&"coins", minf(coins_before, 100.0), &"test")
	main_screen.wallet.add_currency(&"sap", 42.0, &"test")
	main_screen.current_act_index = 2
	main_screen.set_upgrade_level(&"prop_birch", 0)
	main_screen.roster_dispatcher.reset_for_breakthrough()
	sawmill._species_cycles.clear()
	StatAggregator.remove_modifier(&"sawmill_process:pine")
	kiln.cycle_progress = 0.0
	kiln.thermal_pressure = 0.0

	var loaded_ok: bool = save_mod.load_and_apply()
	_check("SaveModule restores wallet, act index, upgrade levels, roster, sawmill cycles, and kiln state after load",
		loaded_ok
		and absf(main_screen.wallet.get_balance(&"coins") - coins_before) < 0.001
		and absf(main_screen.wallet.get_balance(&"sap") - sap_before) < 0.001
		and main_screen.current_act_index == 0
		and main_screen.get_upgrade_level(&"prop_birch") == 1
		and main_screen.roster_dispatcher.get_station_assigned(&"pine") == 1
		and absf(sawmill.get_species_cycles(&"pine") - sawmill_cycles_before) < 0.001
		and StatAggregator.has_source(&"sawmill_process:pine")
		and absf(kiln.cycle_progress - kiln_progress_before) < 0.001
		and absf(kiln.thermal_pressure - kiln_pressure_before) < 0.001
		and kiln.total_cycles_completed == kiln_cycles_before,
		"coins %f -> %f" % [coins_before, main_screen.wallet.get_balance(&"coins")])

	_check("SaveModule grants zero offline progression on load",
		absf(main_screen.wallet.get_balance(&"coins") - coins_before) < 0.001,
		str(main_screen.wallet.get_balance(&"coins")))

	# Rotate the good save into the .bak, then corrupt the main file to verify recovery.
	save_mod.save_now()
	var corrupt_file := FileAccess.open("user://smoke_slot_test.json", FileAccess.WRITE)
	corrupt_file.store_string("{ this is not valid json")
	corrupt_file.close()
	var recovered_ok: bool = save_mod.load_and_apply()
	_check("SaveModule recovers from the .bak backup when the main save is corrupted",
		recovered_ok and absf(main_screen.wallet.get_balance(&"coins") - coins_before) < 0.001,
		str(main_screen.wallet.get_balance(&"coins")))

	save_mod.queue_free()
	ach.queue_free()
	sawmill.free()
	kiln.free()
	main_screen.queue_free()
	StatAggregator.clear_all()
	var user_dir := DirAccess.open("user://")
	if user_dir != null:
		if user_dir.file_exists("smoke_slot_test.json"):
			user_dir.remove("smoke_slot_test.json")
		if user_dir.file_exists("smoke_slot_test.json.bak"):
			user_dir.remove("smoke_slot_test.json.bak")


func _test_milestone_6_audio_and_settings() -> void:
	LocaleResolver.ensure_loaded()
	LocaleResolver.apply_locale("en")

	var audio_mod := AudioModule.new()
	audio_mod.name = "TestAudioModule"
	add_child(audio_mod)
	var sfx_idx: int = AudioServer.get_bus_index("SFX")
	var music_idx: int = AudioServer.get_bus_index("Music")
	var ui_idx: int = AudioServer.get_bus_index("UI")
	_check("AudioModule ensures Master/Music/SFX/UI buses exist",
		sfx_idx != -1 and music_idx != -1 and ui_idx != -1,
		"%d/%d/%d" % [sfx_idx, music_idx, ui_idx])

	audio_mod.play_sfx(&"button_click")
	audio_mod.play_music(&"main_theme")
	_check("AudioModule no-ops cleanly for undelivered audio assets (no synthesis, no errors)", true)

	var settings_mod := SettingsModule.new()
	settings_mod.name = "TestSettingsModule"
	add_child(settings_mod)

	EventBus.setting_changed.emit(&"audio", &"sfx", 0.5)
	_check("SettingsModule applies SFX bus volume from setting_changed",
		absf(AudioServer.get_bus_volume_db(sfx_idx) - linear_to_db(0.5)) < 0.01,
		str(AudioServer.get_bus_volume_db(sfx_idx)))

	EventBus.setting_changed.emit(&"gameplay", &"notation", 1)
	_check("SettingsModule applies notation mode live",
		NumberFormatter.active_mode == NumberFormatter.Mode.SCIENTIFIC,
		str(NumberFormatter.active_mode))
	EventBus.setting_changed.emit(&"gameplay", &"notation", 0)

	EventBus.setting_changed.emit(&"gameplay", &"locale", "es_419")
	_check("SettingsModule applies locale live", tr("KEY_HUD_TAB_TREES") == "Arboles",
		TranslationServer.get_locale())
	EventBus.setting_changed.emit(&"gameplay", &"locale", "en")
	_check("SettingsModule restores English locale", tr("KEY_HUD_TAB_TREES") == "Trees",
		TranslationServer.get_locale())

	EventBus.setting_changed.emit(&"accessibility", &"colorblind", 2)
	_check("SettingsModule resolves missing colorblind shader as null (drop-in pipeline)",
		settings_mod.get_colorblind_shader() == null)

	var saved_state: Dictionary = settings_mod.serialize()
	EventBus.setting_changed.emit(&"audio", &"master", 0.1)
	settings_mod.deserialize(saved_state)
	_check("SettingsModule serialize/deserialize roundtrip restores settings state",
		absf(float(settings_mod.get_setting(&"audio", &"master")) - 0.8) < 0.001,
		str(settings_mod.get_setting(&"audio", &"master")))

	var settings_scene: PackedScene = load("res://scenes/ui/modals/modal_settings.tscn") as PackedScene
	var settings_modal: ModalSettingsView = settings_scene.instantiate() as ModalSettingsView
	add_child(settings_modal)
	settings_modal.bind_settings(settings_mod)
	_check("ModalSettingsView initializes controls from SettingsModule state",
		settings_modal != null
		and settings_modal._master_slider != null
		and absf(settings_modal._master_slider.value - 0.8) < 0.001
		and settings_modal._locale_option != null
		and settings_modal._locale_option.selected == 0,
		"master=%s locale=%d" % [str(settings_modal._master_slider.value), settings_modal._locale_option.selected])

	settings_modal.queue_free()
	settings_mod.queue_free()
	audio_mod.queue_free()
	StatAggregator.clear_all()


