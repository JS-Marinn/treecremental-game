class_name WalletModule
extends GameModule
## Core resource wallet and accounting ledger.
## Holds all currencies (logs, planks, charcoal, ash, seeds, sap, amber, etc.).
## Exposes operations strictly via EventBus signals and commands.

var balances: Dictionary = {}         # StringName -> float
var run_totals: Dictionary = {}       # StringName -> float (resets on breakthrough/prestige)
var lifetime_totals: Dictionary = {}  # StringName -> float (persists forever)


func _init() -> void:
	module_id = &"economy"


func setup(context: Node) -> void:
	super.setup(context)
	EventBus.command_requested.connect(_on_command_requested)


func _exit_tree() -> void:
	if EventBus.command_requested.is_connected(_on_command_requested):
		EventBus.command_requested.disconnect(_on_command_requested)


func get_balance(res_id: StringName) -> float:
	return balances.get(res_id, 0.0)


func get_run_total(res_id: StringName) -> float:
	return run_totals.get(res_id, 0.0)


func get_lifetime_total(res_id: StringName) -> float:
	return lifetime_totals.get(res_id, 0.0)


func add_resource(res_id: StringName, amount: float, source_id: StringName = &"") -> void:
	if amount <= 0.0 or is_nan(amount):
		return
	var cur: float = balances.get(res_id, 0.0) + amount
	balances[res_id] = cur
	run_totals[res_id] = run_totals.get(res_id, 0.0) + amount
	lifetime_totals[res_id] = lifetime_totals.get(res_id, 0.0) + amount

	EventBus.resource_gained.emit(res_id, amount, source_id)
	EventBus.resource_total_changed.emit(res_id, cur)


func spend_resource(res_id: StringName, amount: float, sink_id: StringName = &"") -> bool:
	if amount <= 0.0:
		return true
	var cur: float = balances.get(res_id, 0.0)
	if cur < amount:
		return false
	var updated: float = cur - amount
	balances[res_id] = updated

	EventBus.resource_spent.emit(res_id, amount, sink_id)
	EventBus.resource_total_changed.emit(res_id, updated)
	return true


func can_afford(res_id: StringName, amount: float) -> bool:
	return balances.get(res_id, 0.0) >= amount


func reset_run() -> void:
	run_totals.clear()


func _on_command_requested(command_name: StringName, payload: Dictionary) -> void:
	match command_name:
		&"earn_resource":
			var res_id: StringName = payload.get("resource_id", &"")
			var amount: float = float(payload.get("amount", 0.0))
			var source_id: StringName = payload.get("source_id", &"")
			add_resource(res_id, amount, source_id)
		&"spend_resource":
			var res_id: StringName = payload.get("resource_id", &"")
			var amount: float = float(payload.get("amount", 0.0))
			var sink_id: StringName = payload.get("sink_id", &"")
			spend_resource(res_id, amount, sink_id)


func serialize() -> Dictionary:
	return {
		"balances": balances.duplicate(),
		"run_totals": run_totals.duplicate(),
		"lifetime_totals": lifetime_totals.duplicate(),
	}


func deserialize(data: Dictionary) -> void:
	if data.has("balances") and data["balances"] is Dictionary:
		balances = data["balances"].duplicate()
	if data.has("run_totals") and data["run_totals"] is Dictionary:
		run_totals = data["run_totals"].duplicate()
	if data.has("lifetime_totals") and data["lifetime_totals"] is Dictionary:
		lifetime_totals = data["lifetime_totals"].duplicate()
