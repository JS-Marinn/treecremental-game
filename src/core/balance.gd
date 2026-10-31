extends Node
## Autoload "Balance": the ONLY gateway from game logic to balance data.
## Loads the active BalanceConfig profile and discovers every SpeciesData under data/species/.
## Game systems call Balance.species(id), Balance.config ... and never contain numbers.

const SETTING_PROFILE: String = "treecremental/balance/profile"
const SETTING_SPECIES_DIR: String = "treecremental/balance/species_dir"

var config: BalanceConfig
var _species: Dictionary = {}          # StringName -> SpeciesData
var _species_order: Array[StringName] = []


func _ready() -> void:
	reload()


## Hot-reload entry point: designers can call this from a debug key after editing .tres files.
func reload() -> void:
	var profile_path: String = ProjectSettings.get_setting(SETTING_PROFILE, "res://data/balance/balance_default.tres")
	config = load(profile_path) as BalanceConfig
	assert(config != null, "Balance: cannot load profile %s" % profile_path)
	_load_species(ProjectSettings.get_setting(SETTING_SPECIES_DIR, "res://data/species"))


func species(id: StringName) -> SpeciesData:
	return _species.get(id)


## Species ids sorted by tier (unlock order).
func species_ids() -> Array[StringName]:
	return _species_order


func _load_species(dir_path: String) -> void:
	_species.clear()
	_species_order.clear()
	var dir: DirAccess = DirAccess.open(dir_path)
	assert(dir != null, "Balance: species dir missing: %s" % dir_path)
	for file_name in dir.get_files():
		# exported builds list resources as *.tres.remap; strip the suffix.
		var clean: String = file_name.trim_suffix(".remap")
		if not clean.ends_with(".tres"):
			continue
		var res: SpeciesData = load(dir_path.path_join(clean)) as SpeciesData
		if res == null or res.id == &"":
			push_warning("Balance: skipped invalid species file %s" % clean)
			continue
		_species[res.id] = res
	_species_order.assign(_species.keys())
	_species_order.sort_custom(func(a: StringName, b: StringName) -> bool:
		return (_species[a] as SpeciesData).tier < (_species[b] as SpeciesData).tier)
