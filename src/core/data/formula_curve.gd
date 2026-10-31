class_name FormulaCurve
extends Resource
## A designer-editable math curve. Every cost, yield, multiplier and threshold in the
## game is a FormulaCurve (or a plain exported number) stored in a .tres file.
## GDScript game logic only ever calls [method evaluate]; it never contains a formula.
##
## Design doc: design/gdd/economy-math.md  (Formulas section)
## Swapping a curve's [member kind] or parameters in the inspector needs zero code change.

enum Kind {
	CONSTANT,            ## base
	LINEAR,              ## base + scale * x
	POLYNOMIAL,          ## base + scale * x^exponent
	EXPONENTIAL,         ## base * growth^x                 (classic cost curve: growth 1.07-1.15)
	LOGARITHMIC,         ## base + scale * ln(1 + x)
	HYPERBOLIC_SOFTCAP,  ## base + cap * x / (x + half_point)   (asymptote = base + cap)
	POWER_SOFTCAP,       ## below soft_start: base+scale*x ; above: grows with x^exponent (diminishing)
	EXPRESSION,          ## free-form text, evaluated with Godot's Expression class
	TABLE,               ## linear interpolation through [member table]
}

@export var kind: Kind = Kind.LINEAR
@export var base: float = 0.0
@export var scale: float = 1.0
@export var exponent: float = 1.0
@export var growth: float = 1.0
@export var cap: float = 0.0
@export var half_point: float = 1.0
@export var soft_start: float = 0.0
@export_multiline var expression: String = ""
@export var table: PackedFloat64Array = PackedFloat64Array()
enum Rounding { NONE, FLOOR, ROUND, CEIL }

@export_group("Clamp / Rounding")
@export var rounding: Rounding = Rounding.NONE
@export var clamp_min: float = -INF
@export var clamp_max: float = INF

var _expr: Expression = null
var _expr_ok: bool = false
var _expr_source: String = ""

const _EXPR_VARS: PackedStringArray = ["x", "base", "scale", "exponent", "growth", "cap", "half_point", "soft_start"]


## Evaluate the curve at [param x] (owned count, level, lifetime total, ...).
func evaluate(x: float) -> float:
	var v: float = 0.0
	match kind:
		Kind.CONSTANT:
			v = base
		Kind.LINEAR:
			v = base + scale * x
		Kind.POLYNOMIAL:
			v = base + scale * pow(maxf(x, 0.0), exponent)
		Kind.EXPONENTIAL:
			v = base * pow(growth, x)
		Kind.LOGARITHMIC:
			v = base + scale * log(1.0 + maxf(x, 0.0))
		Kind.HYPERBOLIC_SOFTCAP:
			v = base + cap * x / (x + half_point) if (x + half_point) != 0.0 else base
		Kind.POWER_SOFTCAP:
			if x <= soft_start:
				v = base + scale * x
			else:
				# continuous at soft_start with slope scale; exponent < 1 => diminishing returns
				v = base + scale * (soft_start + (pow(x - soft_start + 1.0, exponent) - 1.0) / maxf(exponent, 0.0001))
		Kind.EXPRESSION:
			v = _eval_expression(x)
		Kind.TABLE:
			v = _eval_table(x)
	v = clampf(v, clamp_min, clamp_max)
	match rounding:
		Rounding.FLOOR:
			v = floorf(v + 1e-9)
		Rounding.ROUND:
			v = roundf(v)
		Rounding.CEIL:
			v = ceilf(v - 1e-9)
	return v


## Total cost of buying [param count] units starting from [param owned]
## (sums [method evaluate] over owned .. owned+count-1; closed form for EXPONENTIAL).
func sum_over(owned: int, count: int) -> float:
	if count <= 0:
		return 0.0
	if kind == Kind.EXPONENTIAL and not is_equal_approx(growth, 1.0) and is_inf(clamp_max) and is_inf(clamp_min):
		return base * pow(growth, owned) * (pow(growth, count) - 1.0) / (growth - 1.0)
	var total: float = 0.0
	for i in count:
		total += evaluate(float(owned + i))
	return total


## How many units can be bought with [param budget] starting at [param owned] (capped at [param max_count]).
func max_affordable(owned: int, budget: float, max_count: int = 1000000) -> int:
	if kind == Kind.EXPONENTIAL and not is_equal_approx(growth, 1.0) and is_inf(clamp_max) and is_inf(clamp_min):
		var first: float = base * pow(growth, owned)
		if first <= 0.0 or budget < first:
			return 0
		var n: float = floor(log(budget * (growth - 1.0) / first + 1.0) / log(growth))
		return mini(int(n), max_count)
	var n_i: int = 0
	var spent: float = 0.0
	while n_i < max_count:
		var c: float = evaluate(float(owned + n_i))
		if spent + c > budget:
			break
		spent += c
		n_i += 1
	return n_i


func _eval_table(x: float) -> float:
	if table.is_empty():
		return base
	if x <= 0.0:
		return table[0]
	var last: int = table.size() - 1
	if x >= float(last):
		return table[last]
	var i: int = int(floor(x))
	return lerpf(table[i], table[i + 1], x - float(i))


func _eval_expression(x: float) -> float:
	if _expr == null or _expr_source != expression:
		_expr = Expression.new()
		_expr_source = expression
		_expr_ok = _expr.parse(expression, _EXPR_VARS) == OK
		if not _expr_ok:
			push_error("FormulaCurve: cannot parse expression '%s'" % expression)
	if not _expr_ok:
		return base
	var out: Variant = _expr.execute([x, base, scale, exponent, growth, cap, half_point, soft_start], null, false)
	if _expr.has_execute_failed():
		push_error("FormulaCurve: execution failed for '%s'" % expression)
		return base
	return float(out)
