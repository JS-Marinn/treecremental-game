class_name CostItem
extends Resource
## A single currency cost component evaluated through a FormulaCurve.
## Part of a CostBundle.

@export var resource_id: StringName = &""
@export var curve: FormulaCurve


func evaluate(x: float) -> float:
	if curve == null:
		return 0.0
	return curve.evaluate(x)


func sum_over(owned: int, count: int) -> float:
	if curve == null:
		return 0.0
	return curve.sum_over(owned, count)
