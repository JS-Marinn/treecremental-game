class_name AviaryModule
extends GameModule
## Loop 4: Canopy Aviary.
## Generates Birdseed passively and on tree fell (scaled by birdseed_generation)
## and amplifies active bird perch bonuses via aviary_suet_cakes (aviary_buff_potency).

const BASE_BIRDSEED_PER_SEC: float = 0.40
const FELL_BIRDSEED_BURST: float = 0.75

var wallet: WalletModule


func _init() -> void:
	module_id = &"canopy_aviary"


func _ready() -> void:
	is_active = true


func bind_wallet(external_wallet: WalletModule) -> void:
	wallet = external_wallet


func _process(delta: float) -> void:
	if is_active:
		tick(delta)


func tick(delta: float) -> void:
	if delta <= 0.0 or wallet == null:
		return
	var rate: float = get_birdseed_rate_per_sec()
	if rate > 0.0:
		wallet.add_currency(&"birdseed", rate * delta, &"canopy_aviary")


func get_birdseed_rate_per_sec() -> float:
	var gen_mult: float = StatAggregator.query(&"birdseed_generation", &"all", 1.0)
	var global_speed: float = StatAggregator.query(&"global_work_speed", &"all", 1.0)
	return BASE_BIRDSEED_PER_SEC * gen_mult * global_speed


func on_tree_felled() -> void:
	if wallet == null:
		return
	var gen_mult: float = StatAggregator.query(&"birdseed_generation", &"all", 1.0)
	wallet.add_currency(&"birdseed", FELL_BIRDSEED_BURST * gen_mult, &"canopy_aviary_fell")
