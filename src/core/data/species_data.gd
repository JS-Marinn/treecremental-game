class_name SpeciesData
extends Resource
## Composable data definition for one of the 9 tree species across Acts I-III.
## Dropping or editing a SpeciesData .tres in res://data/species/ updates tree durability,
## bark hardness, base coin value, Poisson-disc clearance radius, propagation curves,
## and ecological synergy parameters with zero code changes.

@export var id: StringName = &""
@export var tier: int = 0
@export var act_index: int = 1
@export var biome: StringName = &"meadow"

@export_group("Durability, Spatial & Economy (v0.6)")
@export var base_hp: float = 20.0
@export var bark_hardness: int = 0
@export var base_coin_value: float = 1.0
@export var trunk_clearance_radius: float = 14.0
@export var base_chop_time_s: float = 2.0
@export var logs_per_chop: float = 1.0
@export var score_weight: float = 1.0

@export_group("Ecological Synergy (v0.6)")
@export var synergy_id: StringName = &""
@export var synergy_proc_chance: float = 0.15
@export var synergy_duration_s: float = 8.0
@export var synergy_magnitude: float = 0.25

@export_group("Propagation & Economy Curves")
@export var spawn_weight_curve: FormulaCurve
@export var max_quantity_curve: FormulaCurve
@export var prop_cost_curve: FormulaCurve
@export var unlock_cost: FormulaCurve
@export var hire_cost: FormulaCurve
@export var tool_cost: FormulaCurve
@export var sawmill_cost: FormulaCurve

@export_group("Presentation")
@export var sprite_frames: Resource
@export var tint: Color = Color.WHITE


func evaluate_spawn_weight(prop_level: int) -> float:
	if prop_level <= 0:
		return 0.0
	if spawn_weight_curve == null:
		return 100.0 * pow(1.35, float(prop_level - 1))
	return spawn_weight_curve.evaluate(float(prop_level))


func evaluate_max_quantity(prop_level: int) -> int:
	if prop_level <= 0:
		return 0
	if max_quantity_curve == null:
		return 2 + int(floor(1.5 * float(prop_level)))
	return int(round(max_quantity_curve.evaluate(float(prop_level))))


func name_key() -> String:
	return "KEY_TREE_%s_NAME" % String(id).to_upper()


func desc_key() -> String:
	return "KEY_TREE_%s_DESC" % String(id).to_upper()


func synergy_name_key() -> String:
	return "KEY_SYNERGY_%s_NAME" % String(synergy_id).to_upper()


func synergy_desc_key() -> String:
	return "KEY_SYNERGY_%s_DESC" % String(synergy_id).to_upper()
