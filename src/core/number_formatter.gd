class_name NumberFormatter
extends RefCounted
## Formats big numbers for display. Mode comes from user settings; thresholds/suffixes from NotationConfig.
## Pure function: no state, trivially unit-testable.

enum Mode { STANDARD, SCIENTIFIC, ENGINEERING }


static func format(value: float, mode: Mode, cfg: NotationConfig) -> String:
	if is_nan(value):
		return "NaN"
	if is_inf(value):
		return "∞" if value > 0.0 else "-∞"
	if absf(value) < cfg.group_size:
		return _trim(value, cfg.below_threshold_decimals)
	match mode:
		Mode.SCIENTIFIC:
			return _sci(value, 1, cfg)
		Mode.ENGINEERING:
			return _sci(value, cfg.engineering_step, cfg)
		_:
			return _standard(value, cfg)


static func _standard(value: float, cfg: NotationConfig) -> String:
	var idx: int = int(floor(log(absf(value)) / log(cfg.group_size)))
	# log() ratios can land one below the true integer (e.g. 999.9999 -> 1000); renormalize.
	if absf(value) >= pow(cfg.group_size, idx + 1):
		idx += 1
	if idx >= cfg.suffixes.size():
		return _sci(value, 1, cfg)   # out of suffixes: graceful fallback
	var scaled: float = value / pow(cfg.group_size, idx)
	return _trim(scaled, cfg.decimals) + cfg.suffixes[idx]


static func _sci(value: float, step: int, cfg: NotationConfig) -> String:
	var exp10: int = int(floor(log(absf(value)) / log(10.0)))
	if absf(value) >= pow(10.0, exp10 + 1):   # float rounding guard (1e60 -> exponent 59)
		exp10 += 1
	if step > 1:
		exp10 = int(floor(float(exp10) / float(step))) * step
	var mantissa: float = value / pow(10.0, exp10)
	return cfg.scientific_format % [_trim(mantissa, cfg.decimals), exp10]


static func _trim(v: float, decimals: int) -> String:
	var s: String = String.num(v, decimals)
	if s.contains("."):
		s = s.rstrip("0").rstrip(".")
	return s
