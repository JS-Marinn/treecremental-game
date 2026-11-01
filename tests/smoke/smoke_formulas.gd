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
	var right_dock: Control = main_screen.get_node_or_null("%RightCommandDock") as Control
	_check("MainScreen 432+208 Right-Hand Docked split geometry",
		left_col != null and left_col.custom_minimum_size == Vector2(432, 360)
		and top_bar != null and top_bar.custom_minimum_size == Vector2(432, 28)
		and clearing_vp != null and clearing_vp.custom_minimum_size == Vector2(432, 332)
		and right_dock != null and right_dock.custom_minimum_size == Vector2(208, 360))

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
		int(main_screen._sawmill_assigned.get(&"pine", 0)) == 1)

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


