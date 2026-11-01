class_name LoggingCampModule
extends GameModule
## Primary Loop 1 controller managing the 432x332 px 3/4 logging clearing:
## - Hosts ClearingTerrain (TileMapLayer stack + Poisson-disc random coordinate sampler)
## - Spawns TreeEntity instances by Species Propagation weight (W_i) and max quantity cap (Q_i)
## - Scales Old-Growth Maturity Rank (m in 0..4) to prevent 1-frame insta-chopping
## - Synchronizes autonomous WorkerAgent instances across the 3 worker types
## - Triggers the 9 species synergies via SynergyController and awards Coins to WalletModule

const TREE_ENTITY_SCENE: PackedScene = preload("res://scenes/world/tree_entity.tscn")
const WORKER_AGENT_SCENE: PackedScene = preload("res://scenes/world/worker_agent.tscn")

var wallet: WalletModule
var spawn_check_interval: float = 0.35
var _spawn_timer: float = 0.0
var _trees: Array[TreeEntity] = []
var _workers_by_type: Dictionary = {
	&"simple_lumberjack": [],
	&"heavy_sawyer": [],
	&"swift_cleaver": [],
}
var _desired_worker_counts: Dictionary = {
	&"simple_lumberjack": 1,
	&"heavy_sawyer": 0,
	&"swift_cleaver": 0,
}
var _floating_popups: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var terrain: ClearingTerrain = get_node_or_null("%ClearingTerrain") as ClearingTerrain
@onready var entities_root: Node2D = get_node_or_null("%EntitiesRoot") as Node2D
@onready var floating_text_root: Node2D = get_node_or_null("%FloatingTextRoot") as Node2D
@onready var synergy_controller: SynergyController = get_node_or_null("%SynergyController") as SynergyController


func _init() -> void:
	module_id = &"logging_camp"


func _ready() -> void:
	_rng.seed = 424242
	is_active = true
	sync_workers_from_stat_aggregator()
	fill_clearing_to_capacity()


func bind_wallet(external_wallet: WalletModule) -> void:
	wallet = external_wallet


func _process(delta: float) -> void:
	if is_active:
		tick(delta)


func tick(delta: float) -> void:
	if synergy_controller != null:
		synergy_controller.tick_synergies(delta)

	_spawn_timer += delta
	if _spawn_timer >= spawn_check_interval:
		_spawn_timer = 0.0
		_try_spawn_next_tree()

	for wid in _workers_by_type.keys():
		var list: Array = _workers_by_type[wid]
		for w in list:
			var agent: WorkerAgent = w as WorkerAgent
			if agent != null and is_instance_valid(agent):
				agent.tick_worker(delta, _trees)

	_tick_floating_popups(delta)


func get_living_tree_count(species_filter: StringName = &"") -> int:
	var count: int = 0
	for t in _trees:
		if t != null and is_instance_valid(t) and not t.is_felled:
			if species_filter == &"" or t.species_id == species_filter:
				count += 1
	return count


func get_active_worker_count(worker_id: StringName) -> int:
	if not _workers_by_type.has(worker_id):
		return 0
	return (_workers_by_type[worker_id] as Array).size()


func get_max_clearing_trees() -> int:
	var base_cap: int = Balance.config.initial_max_trees_on_map if Balance.config != null else 14
	var bonus_cap: int = int(StatAggregator.query(&"clearing_max_trees", &"all", 0.0))
	return base_cap + bonus_cap


func set_worker_clearing_counts(simple_count: int, heavy_count: int, swift_count: int) -> void:
	_desired_worker_counts[&"simple_lumberjack"] = maxi(0, simple_count)
	_desired_worker_counts[&"heavy_sawyer"] = maxi(0, heavy_count)
	_desired_worker_counts[&"swift_cleaver"] = maxi(0, swift_count)
	_reconcile_worker_nodes()


func sync_workers_from_stat_aggregator(sawmill_assigned_simple: int = 0) -> void:
	var hired_simple: int = maxi(1, int(StatAggregator.query(&"worker_roster_count", &"simple_lumberjack", 0.0)))
	var hired_heavy: int = int(StatAggregator.query(&"worker_roster_count", &"heavy_sawyer", 0.0))
	var hired_swift: int = int(StatAggregator.query(&"worker_roster_count", &"swift_cleaver", 0.0))
	set_worker_clearing_counts(
		maxi(0, hired_simple - sawmill_assigned_simple),
		hired_heavy,
		hired_swift
	)


func fill_clearing_to_capacity() -> void:
	var target: int = get_max_clearing_trees()
	var guard: int = 0
	while get_living_tree_count() < target and guard < 40:
		guard += 1
		if not _try_spawn_next_tree():
			break


func compute_spawn_probabilities() -> Dictionary:
	var weights: Dictionary = {}
	var total_weight: float = 0.0
	for sid in Balance.species_ids():
		var sp: SpeciesData = Balance.species(sid)
		if sp == null:
			continue
		var w: float = StatAggregator.query(&"species_spawn_weight", sid, 0.0)
		var max_q: int = int(StatAggregator.query(&"species_max_quantity", sid, 0.0))
		if w > 0.0 and get_living_tree_count(sid) < max_q:
			weights[sid] = w
			total_weight += w
	var probs: Dictionary = {}
	if total_weight > 0.0:
		for sid in weights.keys():
			probs[sid] = float(weights[sid]) / total_weight
	return probs


func compute_maturity_rank_for_species(sp: SpeciesData) -> int:
	if sp == null:
		return 0
	var max_unlocked_rank: int = clampi(int(StatAggregator.query(&"old_growth_max_rank", &"all", 0.0)), 0, 4)
	if max_unlocked_rank <= 0:
		return 0
	# Estimate total clearing DPS to prevent 1-frame insta-chopping (clamp target chop time >= 2.5s)
	var est_dps: float = _estimate_clearing_dps()
	var hp_base: float = Balance.config.maturity_hp_base if Balance.config != null else 4.0
	var rank: int = 0
	while rank < max_unlocked_rank:
		var hp_at_rank: float = sp.base_hp * pow(hp_base, float(rank))
		if est_dps > 0.0 and (hp_at_rank / est_dps) < 2.5:
			rank += 1
		else:
			break
	return rank


func _estimate_clearing_dps() -> float:
	var total_dps: float = 0.0
	for wid in _workers_by_type.keys():
		var list: Array = _workers_by_type[wid]
		for w in list:
			var agent: WorkerAgent = w as WorkerAgent
			if agent != null and is_instance_valid(agent):
				total_dps += agent.compute_hit_damage() * agent.compute_attack_rate()
	return maxf(1.0, total_dps)


func _try_spawn_next_tree() -> bool:
	if terrain == null or entities_root == null:
		return false
	if get_living_tree_count() >= get_max_clearing_trees():
		return false

	var probs: Dictionary = compute_spawn_probabilities()
	if probs.is_empty():
		return false

	var roll: float = _rng.randf()
	var accum: float = 0.0
	var chosen_id: StringName = &""
	for sid in probs.keys():
		accum += float(probs[sid])
		if roll <= accum:
			chosen_id = sid
			break
	if chosen_id == &"":
		chosen_id = probs.keys()[-1]

	var sp: SpeciesData = Balance.species(chosen_id)
	if sp == null:
		return false

	var rank: int = compute_maturity_rank_for_species(sp)
	var clearance: float = sp.trunk_clearance_radius + float(rank) * 1.5
	var pos: Vector2 = terrain.sample_poisson_tree_position(clearance, _trees, 28)
	if pos.x < 0.0:
		return false

	var tree: TreeEntity = TREE_ENTITY_SCENE.instantiate() as TreeEntity
	tree.position = pos
	entities_root.add_child(tree)
	tree.setup_tree(sp, rank)
	tree.chip_yield_awarded.connect(_on_tree_chip_yield)
	tree.tree_felled.connect(_on_tree_felled)
	_trees.append(tree)
	return true


func _reconcile_worker_nodes() -> void:
	if entities_root == null:
		return
	for wid in _workers_by_type.keys():
		var desired: int = int(_desired_worker_counts.get(wid, 0))
		var list: Array = _workers_by_type[wid]
		while list.size() > desired:
			var last: WorkerAgent = list.pop_back() as WorkerAgent
			if last != null and is_instance_valid(last):
				last.queue_free()
		var arch: WorkerArchetypeData = Balance.worker(wid)
		while list.size() < desired and arch != null:
			var agent: WorkerAgent = WORKER_AGENT_SCENE.instantiate() as WorkerAgent
			var idx: int = list.size()
			agent.position = Vector2(
				roundf(72.0 + float((idx * 37) % 280)),
				roundf(250.0 + float((idx * 19) % 45))
			)
			entities_root.add_child(agent)
			agent.setup_worker(arch, 1000 + idx * 17)
			list.append(agent)


func _on_tree_chip_yield(tree: TreeEntity, coins: float) -> void:
	if wallet != null and coins > 0.0:
		wallet.add_currency(&"coins", coins, tree.species_id)
	_spawn_floating_coin_text(tree.position + Vector2(0.0, -24.0), coins, false)


func _on_tree_felled(tree: TreeEntity, jackpot_coins: float, _attacker_id: StringName, synergy_weight: float) -> void:
	if wallet != null and jackpot_coins > 0.0:
		wallet.add_currency(&"coins", jackpot_coins, tree.species_id)
	_spawn_floating_coin_text(tree.position + Vector2(0.0, -32.0), jackpot_coins, true)

	_trees.erase(tree)
	if synergy_controller != null and tree.species_data != null:
		synergy_controller.try_trigger_on_fell(tree.species_data, synergy_weight, wallet, _trees)
	if is_instance_valid(tree):
		tree.queue_free()


func _spawn_floating_coin_text(world_pos: Vector2, coins: float, is_jackpot: bool) -> void:
	if floating_text_root == null or coins < 0.05:
		return
	var lbl := Label.new()
	lbl.text = "+$%s" % NumberFormatter.format(coins)
	lbl.position = world_pos + Vector2(-14.0, 0.0)
	lbl.add_theme_font_size_override("font_size", 9 if is_jackpot else 7)
	lbl.add_theme_color_override(
		"font_color",
		Color(1.0, 0.90, 0.28, 1.0) if is_jackpot else Color(0.88, 0.96, 0.78, 0.9)
	)
	floating_text_root.add_child(lbl)
	_floating_popups.append({"node": lbl, "ttl": 0.65})


func _tick_floating_popups(delta: float) -> void:
	var keep: Array[Dictionary] = []
	for item in _floating_popups:
		var lbl: Label = item.get("node") as Label
		var ttl: float = float(item.get("ttl", 0.0)) - delta
		if lbl != null and is_instance_valid(lbl):
			if ttl <= 0.0:
				lbl.queue_free()
			else:
				lbl.position.y -= 18.0 * delta
				item["ttl"] = ttl
				keep.append(item)
	_floating_popups = keep
