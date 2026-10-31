extends Node
## Smoke test for the data-driven math layer. Run scene directly (run_project scene=...).
## Prints PASS/FAIL lines; quits with exit code 0 only if everything passes.

var _fails: int = 0


func _ready() -> void:
	_test_registry()
	_test_plateau_structure()
	_test_exponential()
	_test_bulk_buy()
	_test_sap()
	_test_softcaps()
	_test_expression()
	_test_notation()
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


func _test_plateau_structure() -> void:
	var cfg: BalanceConfig = Balance.config
	_check("trees per act = 3", cfg.trees_per_act == 3, str(cfg.trees_per_act))
	_check("worker caps [30, 50, 70]", cfg.get_worker_cap(0) == 30 and cfg.get_worker_cap(1) == 50 and cfg.get_worker_cap(2) == 70)
	_check("tool caps [3, 5, 6]", cfg.get_tool_cap(0) == 3 and cfg.get_tool_cap(1) == 5 and cfg.get_tool_cap(2) == 6)
	_check("sawmill caps [4, 7, 10]", cfg.get_sawmill_cap(0) == 4 and cfg.get_sawmill_cap(1) == 7 and cfg.get_sawmill_cap(2) == 10)
	_check("breakthrough gate 1 = 247K logs", is_equal_approx(cfg.get_gate_logs(0), 247000.0), str(cfg.get_gate_logs(0)))
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
	# 2.0e7 / 2000 = 10000 -> sqrt(10000) = 100
	_check("sap gain at score 2.0e7 = floor(sqrt(10000)) = 100", gain == 100.0, str(gain))
	var mult: float = cfg.sap_multiplier.evaluate(100.0)
	# 1 + 0.6 * sqrt(100) = 1 + 6.0 = 7.0
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
