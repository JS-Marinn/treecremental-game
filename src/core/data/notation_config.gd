class_name NotationConfig
extends Resource
## Data for big-number formatting. Suffix names, group size and decimals are data, not code.
## Design doc: design/gdd/settings-accessibility.md

@export var group_size: float = 1000.0
@export var decimals: int = 2
@export var below_threshold_decimals: int = 0   ## decimals for numbers < group_size
@export var suffixes: PackedStringArray = PackedStringArray()   ## index 0 = "" (units), 1 = "K", ...
@export var scientific_format: String = "%se%d"   ## mantissa string, exponent
@export var engineering_step: int = 3
