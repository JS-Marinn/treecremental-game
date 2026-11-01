class_name WalletModule
extends GameModule
## Decoupled currency ledger managing the 7 canonical currencies from design/registry/entities.yaml:
## - coins (main loop currency, resets on Breakthrough)
## - processed_logs (Sawmill currency, resets on Breakthrough)
## - charcoal (Kiln primary currency, resets on Breakthrough)
## - ash (Kiln secondary currency, resets on Breakthrough)
## - birdseed (Canopy Aviary tertiary currency, persists across Breakthroughs when bonded)
## - spores (Mycelium Network tertiary currency, persists across Breakthroughs)
## - sap (Heartwood Ascension prestige currency, permanent)

const CANONICAL_CURRENCIES: Array[StringName] = [
	&"coins",
	&"processed_logs",
	&"charcoal",
	&"ash",
	&"birdseed",
	&"spores",
	&"sap",
]

const BREAKTHROUGH_RESET_CURRENCIES: Array[StringName] = [
	&"coins",
	&"processed_logs",
	&"charcoal",
	&"ash",
]

var _balances: Dictionary = {}
var run_coins_earned: float = 0.0
var lifetime_coins_earned: float = 0.0
var lifetime_sap: float = 0.0


func _init() -> void:
	module_id = &"wallet"
	_init_zero_balances()


func setup(context: Node) -> void:
	super.setup(context)
	_init_zero_balances()


func _init_zero_balances() -> void:
	for cid in CANONICAL_CURRENCIES:
		if not _balances.has(cid):
			_balances[cid] = 0.0


func get_balance(currency_id: StringName) -> float:
	return float(_balances.get(currency_id, 0.0))


func can_afford(currency_id: StringName, amount: float) -> bool:
	if amount <= 0.0:
		return true
	return get_balance(currency_id) + 1e-6 >= amount


func can_afford_upgrade(upgrade: UpgradeDefinitionData, current_level: int, count: int = 1) -> bool:
	if upgrade == null or count <= 0:
		return false
	var primary_cost: float = upgrade.evaluate_cost(current_level, count)
	if not can_afford(upgrade.cost_currency_id, primary_cost):
		return false
	if upgrade.secondary_cost_currency_id != &"":
		var sec_cost: float = upgrade.evaluate_secondary_cost(current_level, count)
		if not can_afford(upgrade.secondary_cost_currency_id, sec_cost):
			return false
	return true


func add_currency(currency_id: StringName, amount: float, source_id: StringName = &"system") -> void:
	if amount <= 0.0:
		return
	var current: float = get_balance(currency_id)
	var updated: float = current + amount
	_balances[currency_id] = updated

	if currency_id == &"coins":
		run_coins_earned += amount
		lifetime_coins_earned += amount
	elif currency_id == &"sap":
		lifetime_sap += amount

	if is_instance_valid(EventBus):
		EventBus.resource_gained.emit(currency_id, amount, source_id)
		EventBus.resource_total_changed.emit(currency_id, updated)


func spend_currency(currency_id: StringName, amount: float, sink_id: StringName = &"system") -> bool:
	if amount <= 0.0:
		return true
	if not can_afford(currency_id, amount):
		return false
	var current: float = get_balance(currency_id)
	var updated: float = maxf(0.0, current - amount)
	_balances[currency_id] = updated

	if is_instance_valid(EventBus):
		EventBus.resource_spent.emit(currency_id, amount, sink_id)
		EventBus.resource_total_changed.emit(currency_id, updated)
	return true


func spend_for_upgrade(upgrade: UpgradeDefinitionData, current_level: int, count: int = 1) -> bool:
	if not can_afford_upgrade(upgrade, current_level, count):
		return false
	var primary_cost: float = upgrade.evaluate_cost(current_level, count)
	spend_currency(upgrade.cost_currency_id, primary_cost, upgrade.id)
	if upgrade.secondary_cost_currency_id != &"":
		var sec_cost: float = upgrade.evaluate_secondary_cost(current_level, count)
		spend_currency(upgrade.secondary_cost_currency_id, sec_cost, upgrade.id)
	return true


func reset_for_breakthrough(starting_coins: float = 0.0) -> void:
	for cid in BREAKTHROUGH_RESET_CURRENCIES:
		_balances[cid] = 0.0
		if is_instance_valid(EventBus):
			EventBus.resource_total_changed.emit(cid, 0.0)
	run_coins_earned = 0.0
	if starting_coins > 0.0:
		add_currency(&"coins", starting_coins, &"sap_pioneer_charter")


func serialize() -> Dictionary:
	var raw_balances: Dictionary = {}
	for cid in CANONICAL_CURRENCIES:
		raw_balances[String(cid)] = get_balance(cid)
	return {
		"balances": raw_balances,
		"run_coins_earned": run_coins_earned,
		"lifetime_coins_earned": lifetime_coins_earned,
		"lifetime_sap": lifetime_sap,
	}


func deserialize(data: Dictionary) -> void:
	_init_zero_balances()
	var saved_balances: Dictionary = data.get("balances", {})
	for cid in CANONICAL_CURRENCIES:
		var key: String = String(cid)
		if saved_balances.has(key):
			_balances[cid] = maxf(0.0, float(saved_balances[key]))
	run_coins_earned = maxf(0.0, float(data.get("run_coins_earned", 0.0)))
	lifetime_coins_earned = maxf(0.0, float(data.get("lifetime_coins_earned", 0.0)))
	lifetime_sap = maxf(0.0, float(data.get("lifetime_sap", 0.0)))
