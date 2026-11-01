class_name NumberFormatter
extends RefCounted
## Formats numerical values for UI display according to NotationConfig.

enum Mode { STANDARD, SCIENTIFIC, ENGINEERING }

static var active_mode: Mode = Mode.STANDARD
static var _default_cfg: NotationConfig


static func format(value: float, mode: Mode = active_mode, cfg: NotationConfig = null) -> String:
	if cfg == null:
		if _default_cfg == null:
			_default_cfg = load("res://data/settings/notation_default.tres") as NotationConfig
		cfg = _default_cfg
	if is_nan(value):
		return "NaN"
	if is_inf(value):
		return "INF" if value > 0.0 else "-INF"
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
	if absf(value) >= pow(cfg.group_size, idx + 1):
		idx += 1
	if idx >= cfg.suffixes.size():
		return _sci(value, 1, cfg)
	var scaled: float = value / pow(cfg.group_size, idx)
	return _trim(scaled, cfg.decimals) + cfg.suffixes[idx]


static func _sci(value: float, step: int, cfg: NotationConfig) -> String:
	var exp10: int = int(floor(log(absf(value)) / log(10.0)))
	if absf(value) >= pow(10.0, exp10 + 1):
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
