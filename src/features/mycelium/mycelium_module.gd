class_name MyceliumModule
extends GameModule
## Loop 5: Subterranean Mycelium Network.
## Generates Spores continuously from living root networks in the clearing (scaled by
## spores_generation). All myc_* upgrades have resets_on_breakthrough = false so the
## fungal root web persists across Heartwood Breakthroughs.

const BASE_SPORES_PER_SEC: float = 0.25
const SPORES_PER_LIVING_TREE: float = 0.08

var wallet: WalletModule
var logging_camp: LoggingCampModule


func _init() -> void:
	module_id = &"mycelium_network"


func _ready() -> void:
	is_active = true


func bind_dependencies(external_wallet: WalletModule, external_camp: LoggingCampModule = null) -> void:
	wallet = external_wallet
	logging_camp = external_camp


func _process(delta: float) -> void:
	if is_active:
		tick(delta)


func tick(delta: float) -> void:
	if delta <= 0.0 or wallet == null:
		return
	var rate: float = get_spores_rate_per_sec()
	if rate > 0.0:
		wallet.add_currency(&"spores", rate * delta, &"mycelium_network")


func get_spores_rate_per_sec() -> float:
	var living_trees: int = logging_camp.get_living_tree_count() if logging_camp != null else 5
	var gen_mult: float = StatAggregator.query(&"spores_generation", &"all", 1.0)
	var global_speed: float = StatAggregator.query(&"global_work_speed", &"all", 1.0)
	return (BASE_SPORES_PER_SEC + float(living_trees) * SPORES_PER_LIVING_TREE) * gen_mult * global_speed
