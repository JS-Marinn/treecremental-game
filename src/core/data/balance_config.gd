class_name BalanceConfig
extends Resource
## Global balance knobs that are not per-species. One .tres file = one balance "profile".
## Designers can keep several profiles (balance_fast.tres, balance_slow.tres) and swap
## the one referenced by project setting treecremental/balance/profile. Zero code changes.
##
## Design doc: design/gdd/economy-math.md

@export_group("Plateau Acts Structure")
@export var trees_per_act: int = 3
@export var worker_caps: PackedInt32Array = PackedInt32Array([30, 50, 70])
@export var tool_caps: PackedInt32Array = PackedInt32Array([3, 5, 6])
@export var sawmill_caps: PackedInt32Array = PackedInt32Array([4, 7, 10])
@export var breakthrough_gate_logs: PackedFloat64Array = PackedFloat64Array([247000.0, 7160000.0, 46200000.0])

@export_group("Milestones (per species worker count)")
@export var milestone_counts: PackedInt32Array = PackedInt32Array([10, 25, 50])
@export var milestone_multiplier: float = 1.5

@export_group("Tool upgrades")
@export var tool_multiplier: float = 2.0
@export var tool_max_level: int = 6

@export_group("Sawmill")
@export var sawmill_gain_per_level: float = 0.20
@export var sawmill_max_level: int = 10

@export_group("Ecosystem (sub-loop aggregate envelope)")
@export var ecosystem_per_species: FormulaCurve

@export_group("Tertiary Isolated Loops")
@export var tertiary_multiplier_cap: float = 1.0
@export var tertiary_half_point_minutes: float = 90.0

@export_group("Prestige: Sap & Breakthroughs")
@export var sap_gain: FormulaCurve            ## x = run score  -> sap earned
@export var sap_multiplier: FormulaCurve      ## x = lifetime sap -> global multiplier
@export var sap_start_species: FormulaCurve   ## x = lifetime sap -> extra species at run start (cap via clamp_max)
@export var prestige_min_sap: float = 5.0


func milestone_mult(worker_count: int) -> float:
	var m: float = 1.0
	for c in milestone_counts:
		if worker_count >= c:
			m *= milestone_multiplier
	return m


func get_worker_cap(act_index: int) -> int:
	if act_index < 0 or act_index >= worker_caps.size():
		return worker_caps[-1] if not worker_caps.is_empty() else 100
	return worker_caps[act_index]


func get_tool_cap(act_index: int) -> int:
	if act_index < 0 or act_index >= tool_caps.size():
		return tool_caps[-1] if not tool_caps.is_empty() else 6
	return tool_caps[act_index]


func get_sawmill_cap(act_index: int) -> int:
	if act_index < 0 or act_index >= sawmill_caps.size():
		return sawmill_caps[-1] if not sawmill_caps.is_empty() else 10
	return sawmill_caps[act_index]


func get_gate_logs(act_index: int) -> float:
	if act_index < 0 or act_index >= breakthrough_gate_logs.size():
		return INF
	return breakthrough_gate_logs[act_index]
