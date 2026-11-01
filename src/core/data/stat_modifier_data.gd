class_name StatModifierData
extends Resource
## Declarative stat modifier attached to an UpgradeDefinitionData or active buff.
## Evaluated by StatAggregator without coupling the source module to the consumer module.

enum Operation {
	ADD = 0,          ## Flat addition to the domain/stat_key additive bucket
	MUL_ADD = 1,      ## Additive percentage bonus (1.0 + sum of MUL_ADD values)
	MUL_COMPOUND = 2, ## Independent compounding multiplier (product of MUL_COMPOUND values)
	OVERRIDE = 3,     ## Overrides the final stat value (highest priority)
}

@export var modifier_id: StringName = &""
@export var target_domain: StringName = &""
@export var stat_key: StringName = &"all"
@export var operation: Operation = Operation.ADD
@export var curve: FormulaCurve


func evaluate(level: int) -> float:
	if level <= 0:
		match operation:
			Operation.MUL_COMPOUND:
				return 1.0
			_:
				return 0.0
	if curve == null:
		match operation:
			Operation.MUL_COMPOUND:
				return 1.0
			_:
				return float(level)
	return curve.evaluate(float(level))
