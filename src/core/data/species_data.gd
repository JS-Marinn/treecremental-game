class_name SpeciesData
extends Resource
## One tree species. Dropping a new SpeciesData .tres into res://data/species/ adds a tree
## to the game with NO code change (SpeciesRegistry discovers it).
##
## Design doc: design/gdd/tree-species.md
## Localization keys are derived: KEY_TREE_<ID>_NAME / KEY_TREE_<ID>_DESC (see [method name_key]).

@export var id: StringName = &""
@export var tier: int = 0                     ## unlock order / biome tier
@export var biome: StringName = &"temperate"
@export var base_chop_time_s: float = 2.0     ## seconds per log for one worker
@export var logs_per_chop: float = 1.0
@export var score_weight: float = 1.0         ## weight of this species' logs in Sap score
@export_group("Curves (x = owned / level)")
@export var unlock_cost: FormulaCurve         ## paid in logs of the previous tier
@export var hire_cost: FormulaCurve           ## x = workers owned
@export var tool_cost: FormulaCurve           ## x = tool level
@export var sawmill_cost: FormulaCurve        ## x = sawmill level
@export_group("Presentation")
@export var sprite_frames: Resource
@export var tint: Color = Color.WHITE


func name_key() -> String:
	return "KEY_TREE_%s_NAME" % String(id).to_upper()


func desc_key() -> String:
	return "KEY_TREE_%s_DESC" % String(id).to_upper()
