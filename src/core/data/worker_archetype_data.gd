class_name WorkerArchetypeData
extends Resource
## Composable data definition for one of the 3 distinct worker archetypes:
## - simple_lumberjack (16x16 px, shared between logging_camp and sawmill)
## - heavy_sawyer (20x16 px, logging_camp exclusive, armor-piercing continuous sawing)
## - swift_cleaver (16x16 px, logging_camp exclusive, high move/attack speed, crit & 2x synergy weight)

@export var id: StringName = &""
@export var tier_index: int = 0
@export var role: StringName = &""
@export var footprint_px: Vector2i = Vector2i(16, 16)

@export_group("Combat & Harvesting Stats")
@export var move_speed: float = 1.0
@export var attack_rate: float = 1.0
@export var base_damage: float = 1.0
@export var crit_chance: float = 0.05
@export var armor_penetration: int = 0
@export var ignore_all_bark_hardness: bool = false
@export var synergy_trigger_weight: float = 1.0
@export var can_chop_all_trees: bool = true

@export_group("Loop Placement & Progression Caps")
@export var allowed_loop_ids: PackedStringArray = PackedStringArray(["logging_camp"])
@export var act_roster_caps: PackedInt32Array = PackedInt32Array([14, 24, 34])
@export var hire_cost_curve: FormulaCurve
@export var gear_cost_curve: FormulaCurve

@export_group("Presentation")
@export var sprite_frames: Resource


func can_assign_to_loop(loop_id: StringName) -> bool:
	return allowed_loop_ids.has(String(loop_id))


func get_roster_cap(act_index: int) -> int:
	if act_roster_caps.is_empty():
		return 14
	var clamped_idx: int = clampi(act_index, 0, act_roster_caps.size() - 1)
	return act_roster_caps[clamped_idx]


func name_key() -> String:
	return "KEY_WORKER_%s_NAME" % String(id).to_upper()


func desc_key() -> String:
	return "KEY_WORKER_%s_DESC" % String(id).to_upper()
