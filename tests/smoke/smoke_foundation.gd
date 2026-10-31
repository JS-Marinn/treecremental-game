extends Node
## Smoke test for Foundation Architecture (CostBundle, ModuleRegistry, Wallet, Tertiary Loops, i18n).
## Prints PASS/FAIL lines; quits with exit code 0 if all tests pass.

var _fails: int = 0


func _ready() -> void:
	_test_cost_bundle()
	_test_wallet_and_events()
	_test_module_registry()
	_test_tertiary_amber_wheel()
	_test_tertiary_aviary()
	_test_locale_resolver()
	print("FOUNDATION SMOKE RESULT: %s (%d failures)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	get_tree().quit(_fails)


func _check(label: String, ok: bool, detail: String = "") -> void:
	if not ok:
		_fails += 1
	print("[%s] %s %s" % ["PASS" if ok else "FAIL", label, detail])


func _test_cost_bundle() -> void:
	var curve_logs := FormulaCurve.new()
	curve_logs.kind = FormulaCurve.Kind.LINEAR
	curve_logs.base = 100.0
	curve_logs.scale = 20.0

	var curve_planks := FormulaCurve.new()
	curve_planks.kind = FormulaCurve.Kind.CONSTANT
	curve_planks.base = 15.0

	var bundle := CostBundle.new()
	var item1 := CostItem.new()
	item1.resource_id = &"logs_pine"
	item1.curve = curve_logs
	bundle.items.append(item1)

	var item2 := CostItem.new()
	item2.resource_id = &"planks_pine"
	item2.curve = curve_planks
	bundle.items.append(item2)

	var reqs := bundle.evaluate(2.0)
	_check("CostBundle evaluate logs=140", is_equal_approx(reqs.get(&"logs_pine", 0.0), 140.0))
	_check("CostBundle evaluate planks=15", is_equal_approx(reqs.get(&"planks_pine", 0.0), 15.0))

	var wallet := {&"logs_pine": 100.0, &"planks_pine": 20.0}
	_check("can_afford is false when logs insufficient", not bundle.can_afford(wallet, 2.0))

	wallet[&"logs_pine"] = 200.0
	_check("can_afford is true when sufficient", bundle.can_afford(wallet, 2.0))

	var deducted := bundle.deduct(wallet, 2.0)
	_check("deduct succeeds", deducted)
	_check("wallet deducted correctly", is_equal_approx(wallet[&"logs_pine"], 60.0) and is_equal_approx(wallet[&"planks_pine"], 5.0))


func _test_wallet_and_events() -> void:
	var wallet := WalletModule.new()
	var box := {"count": 0, "amt": 0.0}

	var cb := func(res_id: StringName, amount: float, _source: StringName) -> void:
		if res_id == &"logs_pine":
			box["count"] = int(box["count"]) + 1
			box["amt"] = amount

	EventBus.resource_gained.connect(cb)

	wallet.add_resource(&"logs_pine", 50.0, &"test")
	_check("wallet balance updated", is_equal_approx(wallet.get_balance(&"logs_pine"), 50.0))
	_check("wallet run total updated", is_equal_approx(wallet.get_run_total(&"logs_pine"), 50.0))
	_check("wallet lifetime total updated", is_equal_approx(wallet.get_lifetime_total(&"logs_pine"), 50.0))
	_check("event bus received signal", int(box["count"]) == 1 and is_equal_approx(float(box["amt"]), 50.0))

	var spent := wallet.spend_resource(&"logs_pine", 20.0, &"test_sink")
	_check("spend succeeds", spent and is_equal_approx(wallet.get_balance(&"logs_pine"), 30.0))

	wallet.reset_run()
	_check("run total cleared on reset", is_equal_approx(wallet.get_run_total(&"logs_pine"), 0.0))
	_check("lifetime total preserved", is_equal_approx(wallet.get_lifetime_total(&"logs_pine"), 50.0))

	EventBus.resource_gained.disconnect(cb)


func _test_module_registry() -> void:
	var registry := ModuleRegistry.new()
	add_child(registry)

	var mod_a := GameModule.new()
	mod_a.module_id = &"mod_a"
	mod_a.dependencies = [&"mod_b"]

	var mod_b := GameModule.new()
	mod_b.module_id = &"mod_b"

	# Register A before B to test topological sort
	registry.register_module(mod_a)
	registry.register_module(mod_b)

	var ordered := registry.get_all_modules()
	_check("two modules registered", ordered.size() == 2)
	_check("dependency B ordered before A", ordered[0].module_id == &"mod_b" and ordered[1].module_id == &"mod_a")

	registry.queue_free()


func _test_tertiary_amber_wheel() -> void:
	var wheel := AmberWheelModule.new()
	add_child(wheel)
	wheel.setup(self)

	_check("initial token present", wheel.available_tokens >= 1)
	var mult_initial := wheel.get_effective_multiplier()
	_check("initial amber mult is 1.0", is_equal_approx(mult_initial, 1.0))

	var did_spin := wheel.spin()
	_check("spin executed successfully", did_spin)
	_check("token decremented", wheel.available_tokens == 0)

	# Simulate 120s offline step
	wheel.offline_step(120.0)
	_check("tokens recharged offline", wheel.available_tokens >= 2)

	wheel.queue_free()


func _test_tertiary_aviary() -> void:
	var aviary := CanopyAviaryModule.new()
	add_child(aviary)
	aviary.setup(self)

	# Give seeds
	aviary.birdseed = 100.0
	var success := aviary.attract_bird(&"owl")
	_check("attract owl succeeds", success)
	_check("owl bonus active", is_equal_approx(aviary.get_offline_mult(), 1.15))

	var success2 := aviary.attract_bird(&"woodpecker")
	_check("attract woodpecker succeeds", success2)
	_check("woodpecker bonus active", is_equal_approx(aviary.get_log_yield_mult(), 1.10))

	aviary.queue_free()


func _test_locale_resolver() -> void:
	var R := LocaleResolver
	_check("Steam latam -> es_419", R.from_steam("latam") == "es_419")
	_check("Steam spanish -> es_ES", R.from_steam("spanish") == "es_ES")
	_check("Steam english -> en", R.from_steam("english") == "en")
	_check("Sanitize regional es_MX -> es_419", R.sanitize_locale("es_MX") == "es_419")
	_check("Sanitize unknown -> default en", R.sanitize_locale("unknown_xyz") == "en")
