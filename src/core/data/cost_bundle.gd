class_name CostBundle
extends Resource
## A multi-currency cost package.
## Allows upgrades or unlocks to demand bundles (e.g. 100 Logs + 20 Planks) without
## hardcoding any resource types or formulas into game code.

@export var items: Array[CostItem] = []


## Evaluate all costs at level/count [param x].
## Returns a Dictionary mapping resource_id (StringName) -> amount (float).
func evaluate(x: float) -> Dictionary:
	var result: Dictionary = {}
	for item in items:
		if item != null and item.resource_id != &"":
			result[item.resource_id] = item.evaluate(x)
	return result


## Returns true if the provided [param wallet] (Dictionary of StringName -> float)
## contains enough of each required resource at level [param x].
func can_afford(wallet: Dictionary, x: float) -> bool:
	var reqs := evaluate(x)
	for res_id in reqs:
		var owned: float = wallet.get(res_id, 0.0)
		if owned < reqs[res_id]:
			return false
	return true


## Attempts to deduct the required resources from [param wallet].
## Returns true on success, or false without modifying the wallet if funds are insufficient.
func deduct(wallet: Dictionary, x: float) -> bool:
	if not can_afford(wallet, x):
		return false
	var reqs := evaluate(x)
	for res_id in reqs:
		wallet[res_id] = wallet.get(res_id, 0.0) - reqs[res_id]
	return true


## Convenience constructor helper for single-currency costs.
static func create_single(res_id: StringName, curve: FormulaCurve) -> CostBundle:
	var bundle := CostBundle.new()
	var item := CostItem.new()
	item.resource_id = res_id
	item.curve = curve
	bundle.items.append(item)
	return bundle
