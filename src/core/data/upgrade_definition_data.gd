class_name UpgradeDefinitionData
extends Resource
## Composable data definition for any upgrade across all 6 loops (87 canonical upgrades).
## Each upgrade carries its cost currency, cost curve, per-Act level caps, and an array
## of StatModifierData entries pushed directly to StatAggregator when leveled.

@export var id: StringName = &""
@export var loop_id: StringName = &"logging_camp"
@export var category: StringName = &"species_propagation"
@export var target_entity_id: StringName = &""

@export_group("Costs & Caps")
@export var cost_currency_id: StringName = &"coins"
@export var secondary_cost_currency_id: StringName = &""
@export var cost_curve: FormulaCurve
@export var secondary_cost_curve: FormulaCurve
@export var act_level_caps: PackedInt32Array = PackedInt32Array([4, 7, 10])
@export var max_level: int = 10
@export var initial_level: int = 0
@export var resets_on_breakthrough: bool = true

@export_group("Modifiers")
@export var modifiers: Array[StatModifierData] = []


func get_act_cap(act_index: int) -> int:
	if act_level_caps.is_empty():
		return max_level
	var clamped_idx: int = clampi(act_index, 0, act_level_caps.size() - 1)
	return mini(act_level_caps[clamped_idx], max_level)


func evaluate_cost(current_level: int, count: int = 1) -> float:
	if cost_curve == null or count <= 0:
		return 0.0
	return cost_curve.sum_over(current_level, count)


func evaluate_secondary_cost(current_level: int, count: int = 1) -> float:
	if secondary_cost_curve == null or secondary_cost_currency_id == &"" or count <= 0:
		return 0.0
	return secondary_cost_curve.sum_over(current_level, count)


func name_key() -> String:
	return "KEY_UPGRADE_%s_NAME" % String(id).to_upper()


func desc_key() -> String:
	return "KEY_UPGRADE_%s_DESC" % String(id).to_upper()
