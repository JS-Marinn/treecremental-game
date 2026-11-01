class_name AchievementDefinitionData
extends Resource
## Composable data definition for one of the ~80 canonical achievements.
## Trigger parameters and thresholds live entirely in data/achievements/*.tres so
## unlock criteria can be tuned or extended with zero GDScript changes.

enum Trigger {
	LIFETIME_CURRENCY = 0,        ## cumulative currency earned (currency_id, threshold)
	TREES_FELLED_TOTAL = 1,       ## total trees felled (threshold)
	TREES_FELLED_SPECIES = 2,     ## trees felled of one species (species_id, threshold)
	OLD_GROWTH_FELLED = 3,        ## maturity rank >= 4 trees felled (threshold)
	UPGRADES_PURCHASED_TOTAL = 4, ## cumulative upgrade levels purchased (threshold)
	UPGRADE_LEVEL = 5,            ## specific upgrade level reached (upgrade_id, threshold)
	CATEGORY_UPGRADES = 6,        ## cumulative levels in a category (category_id, threshold)
	WORKER_ROSTER_LEVEL = 7,      ## hire_<worker_id> level reached (worker_id, threshold)
	ALL_WORKER_TYPES = 8,         ## all three archetypes hired to the level (threshold)
	SAWMILL_ASSIGNED = 9,         ## cumulative sawmill assignment actions (threshold)
	KILN_CYCLES = 10,             ## carbonization cycles completed (threshold)
	BOILER_PRESSURE = 11,         ## max thermal pressure reached (threshold in 0..1)
	SPECIES_UNLOCKED = 12,        ## distinct propagated species (threshold)
	SYNERGIES_TRIGGERED = 13,     ## species synergy events triggered (threshold)
	BREAKTHROUGH_INDEX = 14,      ## highest breakthrough act index (threshold)
	SAP_BANKED = 15,              ## max sap balance reached (threshold)
	ALL_ACHIEVEMENTS = 16,        ## every other achievement unlocked
}

@export var id: StringName = &""
@export var trigger: Trigger = Trigger.LIFETIME_CURRENCY
@export var currency_id: StringName = &"coins"
@export var species_id: StringName = &""
@export var worker_id: StringName = &""
@export var upgrade_id: StringName = &""
@export var category_id: StringName = &""
@export var threshold: float = 1.0


func name_key() -> String:
	return "KEY_ACH_%s_NAME" % String(id).to_upper()


func desc_key() -> String:
	return "KEY_ACH_%s_DESC" % String(id).to_upper()
