class_name WorkerAgent
extends Node2D
## Autonomous worker unit operating in the 3/4 logging clearing.
## Differentiates behavior and visuals strictly from WorkerArchetypeData and StatAggregator:
## - simple_lumberjack (16x16 px, red plaid tunic + axe, balanced chopper)
## - heavy_sawyer (20x16 px, amber leather apron + wide bucking saw, ignores 100% Bark Hardness & shreds armor)
## - swift_cleaver (16x16 px, teal ranger cloak + twin hatchets, 1.4x speed, +20% crit, 2.0x synergy weight)

signal chop_strike_performed(worker: WorkerAgent, target: TreeEntity, was_crit: bool, result: Dictionary)

const BASE_WALK_PX_PER_SEC: float = 48.0
const CHOP_REACH_PX: float = 16.0

var archetype: WorkerArchetypeData
var worker_id: StringName = &"simple_lumberjack"
var target_tree: TreeEntity
var attack_cooldown: float = 0.0
var facing_dir: float = 1.0

var _swing_anim_timer: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _visual_root: Node2D = get_node_or_null("%VisualRoot") as Node2D
@onready var _sprite_slot: Sprite2D = get_node_or_null("%SpriteSlot") as Sprite2D


func _ready() -> void:
	_rng.randomize()


func setup_worker(data: WorkerArchetypeData, rng_seed: int = 0) -> void:
	archetype = data
	if data != null:
		worker_id = data.id
	if rng_seed != 0:
		_rng.seed = rng_seed
	queue_redraw()


func compute_move_speed_px() -> float:
	if archetype == null:
		return BASE_WALK_PX_PER_SEC
	var speed_mult: float = StatAggregator.query(&"worker_move_speed", worker_id, 1.0)
	var global_speed: float = StatAggregator.query(&"global_work_speed", &"all", 1.0)
	return BASE_WALK_PX_PER_SEC * archetype.move_speed * speed_mult * global_speed


func compute_attack_rate() -> float:
	if archetype == null:
		return 1.0
	var rate_mult: float = StatAggregator.query(&"worker_attack_rate", worker_id, 1.0)
	var global_speed: float = StatAggregator.query(&"global_work_speed", &"all", 1.0)
	return maxf(0.1, archetype.attack_rate * rate_mult * global_speed)


func compute_hit_damage(out_crit: Array = []) -> float:
	if archetype == null:
		return 1.0
	var power_mult: float = StatAggregator.query(&"worker_chop_power", worker_id, 1.0)
	var raw: float = archetype.base_damage * power_mult
	var crit_c: float = clampf(
		archetype.crit_chance + StatAggregator.query(&"worker_crit_chance", worker_id, 0.0),
		0.0,
		0.95
	)
	var is_crit: bool = _rng.randf() < crit_c
	if not out_crit.is_empty():
		out_crit[0] = is_crit
	if is_crit:
		var crit_mult: float = 2.5 + StatAggregator.query(&"worker_crit_damage", worker_id, 0.0)
		raw *= crit_mult
	return raw


func tick_worker(delta: float, available_trees: Array) -> void:
	if _swing_anim_timer > 0.0:
		_swing_anim_timer = maxf(0.0, _swing_anim_timer - delta)
		queue_redraw()

	if target_tree == null or not is_instance_valid(target_tree) or target_tree.is_felled:
		target_tree = _pick_target_tree(available_trees)
		if target_tree == null:
			return

	var stand_offset := Vector2(-12.0 if position.x <= target_tree.position.x else 12.0, 2.0)
	var goal_pos: Vector2 = target_tree.position + stand_offset
	var to_goal: Vector2 = goal_pos - position
	var dist: float = to_goal.length()
	if absf(target_tree.position.x - position.x) > 0.5:
		facing_dir = 1.0 if target_tree.position.x >= position.x else -1.0

	if dist > CHOP_REACH_PX:
		var step: float = compute_move_speed_px() * delta
		position = (position + to_goal.normalized() * minf(dist, step)).round()
		queue_redraw()
		return

	attack_cooldown -= delta
	if attack_cooldown <= 0.0:
		var rate: float = compute_attack_rate()
		attack_cooldown = 1.0 / rate
		_perform_strike(target_tree)


func _perform_strike(tree: TreeEntity) -> void:
	if tree == null or tree.is_felled or archetype == null:
		return
	var crit_box: Array = [false]
	var dmg: float = compute_hit_damage(crit_box)
	var was_crit: bool = bool(crit_box[0])
	var pen: int = archetype.armor_penetration + int(StatAggregator.query(&"bark_penetration", worker_id, 0.0))

	if worker_id == &"heavy_sawyer":
		var shred: float = StatAggregator.query(&"sawyer_armor_shred", &"heavy_sawyer", 0.0)
		if shred > 0.0:
			tree.apply_kerf_shred(shred)

	_swing_anim_timer = 0.12
	queue_redraw()
	var res: Dictionary = tree.apply_chop_damage(
		dmg,
		pen,
		archetype.ignore_all_bark_hardness,
		worker_id,
		archetype.synergy_trigger_weight
	)
	chop_strike_performed.emit(self, tree, was_crit, res)


func _pick_target_tree(available_trees: Array) -> TreeEntity:
	var best: TreeEntity = null
	var best_score: float = INF
	for item in available_trees:
		var t: TreeEntity = item as TreeEntity
		if t == null or not is_instance_valid(t) or t.is_felled:
			continue
		var d: float = position.distance_to(t.position)
		# Heavy Sawyers prioritize high bark-hardness trees
		if worker_id == &"heavy_sawyer":
			d -= float(t.bark_hardness) * 18.0
		if d < best_score:
			best_score = d
			best = t
	return best


func _draw() -> void:
	if _sprite_slot != null and _sprite_slot.texture != null:
		return
	var swing_shift: float = (3.0 * facing_dir) if _swing_anim_timer > 0.0 else 0.0
	match worker_id:
		&"heavy_sawyer":
			# 20x16 px wide silhouette: dark boots, amber leather apron, brass cap, wide bucking saw
			draw_rect(Rect2(-9.0, -2.0, 18.0, 3.0), Color(0.05, 0.08, 0.04, 0.55))
			draw_rect(Rect2(-7.0 + swing_shift, -12.0, 14.0, 10.0), Color(0.82, 0.54, 0.16, 1.0))
			draw_rect(Rect2(-5.0 + swing_shift, -16.0, 10.0, 5.0), Color(0.92, 0.76, 0.34, 1.0))
			# Long bucking saw blade
			draw_rect(Rect2(2.0 * facing_dir + swing_shift, -8.0, 10.0 * facing_dir, 3.0), Color(0.82, 0.86, 0.90, 1.0))
		&"swift_cleaver":
			# 16x16 px agile silhouette: teal ranger cloak, hood, twin silver hatchets
			draw_rect(Rect2(-6.0, -2.0, 12.0, 3.0), Color(0.05, 0.08, 0.04, 0.55))
			draw_rect(Rect2(-5.0 + swing_shift, -12.0, 10.0, 10.0), Color(0.18, 0.72, 0.64, 1.0))
			draw_rect(Rect2(-4.0 + swing_shift, -16.0, 8.0, 5.0), Color(0.26, 0.88, 0.76, 1.0))
			# Twin hatchets
			draw_rect(Rect2(4.0 * facing_dir + swing_shift, -11.0, 4.0 * facing_dir, 5.0), Color(0.92, 0.96, 1.0, 1.0))
		_:
			# simple_lumberjack: 16x16 px red plaid tunic, brown cap, felling axe
			draw_rect(Rect2(-6.0, -2.0, 12.0, 3.0), Color(0.05, 0.08, 0.04, 0.55))
			draw_rect(Rect2(-5.0 + swing_shift, -12.0, 10.0, 10.0), Color(0.84, 0.24, 0.20, 1.0))
			draw_rect(Rect2(-4.0 + swing_shift, -16.0, 8.0, 5.0), Color(0.52, 0.34, 0.18, 1.0))
			# Felling axe head
			draw_rect(Rect2(4.0 * facing_dir + swing_shift, -10.0, 5.0 * facing_dir, 4.0), Color(0.78, 0.82, 0.86, 1.0))
