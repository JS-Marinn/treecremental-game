class_name BalanceConfig
extends Resource
## Global balance knobs that are not per-species. One .tres file = one balance "profile".
## Designers can keep several profiles (balance_fast.tres, balance_slow.tres) and swap
## the one referenced by project setting treecremental/balance/profile. Zero code changes.

@export_group("Plateau Acts Structure (v0.6)")
@export var trees_per_act: int = 3
@export var prop_caps: PackedInt32Array = PackedInt32Array([4, 7, 10])
@export var worker_caps: PackedInt32Array = PackedInt32Array([25, 46, 67])
@export var tool_caps: PackedInt32Array = PackedInt32Array([3, 5, 6])
@export var gear_caps: PackedInt32Array = PackedInt32Array([3, 5, 6])
@export var sawmill_caps: PackedInt32Array = PackedInt32Array([4, 7, 10])
@export var breakthrough_gate_coins: PackedFloat64Array = PackedFloat64Array([247000.0, 7160000.0, 46200000.0])
@export var breakthrough_gate_logs: PackedFloat64Array = PackedFloat64Array([247000.0, 7160000.0, 46200000.0])

@export_group("Clearing Spawner & Maturity Scaling (v0.6)")
@export var initial_max_trees_on_map: int = 14
@export var maturity_hp_base: float = 4.0
@export var maturity_yield_base: float = 4.2
@export var chip_yield_fraction: float = 0.30
@export var timberfall_yield_fraction: float = 0.70

@export_group("Milestones (per worker tier count)")
@export var milestone_counts: PackedInt32Array = PackedInt32Array([10, 25, 50])
@export var milestone_multiplier: float = 1.5

@export_group("Gear & Tool Upgrades")
@export var tool_multiplier: float = 2.0
@export var tool_max_level: int = 6

@export_group("Sawmill Value Amplification")
@export var sawmill_gain_per_level: float = 0.25
@export var sawmill_max_level: int = 10
@export var sawmill_initial_worker_slots: int = 2

@export_group("Ecosystem (sub-loop aggregate envelope)")
@export var ecosystem_per_species: FormulaCurve

@export_group("Tertiary Isolated Loops")
@export var tertiary_multiplier_cap: float = 1.0
@export var tertiary_half_point_minutes: float = 90.0

@export_group("Prestige: Sap & Breakthroughs")
@export var sap_gain: FormulaCurve
@export var sap_multiplier: FormulaCurve
@export var sap_start_species: FormulaCurve
@export var prestige_min_sap: float = 5.0


func milestone_mult(worker_count: int) -> float:
	var m: float = 1.0
	for c in milestone_counts:
		if worker_count >= c:
			m *= milestone_multiplier
	return m


func get_prop_cap(act_index: int) -> int:
	if act_index < 0 or act_index >= prop_caps.size():
		return prop_caps[-1] if not prop_caps.is_empty() else 10
	return prop_caps[act_index]


func get_worker_cap(act_index: int) -> int:
	if act_index < 0 or act_index >= worker_caps.size():
		return worker_caps[-1] if not worker_caps.is_empty() else 67
	return worker_caps[act_index]


func get_tool_cap(act_index: int) -> int:
	if act_index < 0 or act_index >= tool_caps.size():
		return tool_caps[-1] if not tool_caps.is_empty() else 6
	return tool_caps[act_index]


func get_gear_cap(act_index: int) -> int:
	if act_index < 0 or act_index >= gear_caps.size():
		return gear_caps[-1] if not gear_caps.is_empty() else 6
	return gear_caps[act_index]


func get_sawmill_cap(act_index: int) -> int:
	if act_index < 0 or act_index >= sawmill_caps.size():
		return sawmill_caps[-1] if not sawmill_caps.is_empty() else 10
	return sawmill_caps[act_index]


func get_gate_coins(act_index: int) -> float:
	if act_index < 0 or act_index >= breakthrough_gate_coins.size():
		return INF
	return breakthrough_gate_coins[act_index]


func get_gate_logs(act_index: int) -> float:
	if act_index < 0 or act_index >= breakthrough_gate_logs.size():
		return INF
	return breakthrough_gate_logs[act_index]
