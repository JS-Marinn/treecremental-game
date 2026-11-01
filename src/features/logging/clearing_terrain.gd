class_name ClearingTerrain
extends Node2D
## Manages the 3-layer Godot 4.7 TileMapLayer stack (%GroundBaseLayer, %TerrainDetailLayer,
## %PerimeterTreelineLayer) inside the 432x332 px logging clearing and provides
## grid-free Poisson-disc random coordinate sampling over `can_spawn_tree == true` tiles.

const TILE_SIZE_PX: int = 16
const GRID_COLS: int = 27 # 27 * 16 = 432 px
const GRID_ROWS: int = 21 # 21 * 16 = 336 px (covers 332 px height)
const CUSTOM_DATA_CAN_SPAWN: String = "can_spawn_tree"

const ATLAS_MEADOW: Vector2i = Vector2i(0, 0)
const ATLAS_CLOVER: Vector2i = Vector2i(1, 0)
const ATLAS_DIRT_PATH: Vector2i = Vector2i(2, 0)
const ATLAS_PERIMETER: Vector2i = Vector2i(3, 0)

@onready var ground_base_layer: TileMapLayer = get_node_or_null("%GroundBaseLayer") as TileMapLayer
@onready var terrain_detail_layer: TileMapLayer = get_node_or_null("%TerrainDetailLayer") as TileMapLayer
@onready var perimeter_treeline_layer: TileMapLayer = get_node_or_null("%PerimeterTreelineLayer") as TileMapLayer

var _tileset: TileSet
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 133742
	_build_runtime_tileset()
	_populate_default_clearing_map()


func is_position_spawnable(local_pos: Vector2) -> bool:
	if ground_base_layer == null or ground_base_layer.tile_set == null:
		return false
	# Keep a clean margin inside the 432x332 viewport so canopies and HP bars stay visible
	if local_pos.x < 28.0 or local_pos.x > 404.0 or local_pos.y < 42.0 or local_pos.y > 308.0:
		return false
	var cell: Vector2i = ground_base_layer.local_to_map(local_pos)
	var tile_data: TileData = ground_base_layer.get_cell_tile_data(cell)
	if tile_data == null:
		return false
	return bool(tile_data.get_custom_data(CUSTOM_DATA_CAN_SPAWN))


## Grid-free continuous Poisson-disc candidate sampler with minimum separation radius.
## Returns Vector2(-1, -1) if all k_attempts fail.
func sample_poisson_tree_position(
	candidate_radius: float,
	existing_trees: Array,
	k_attempts: int = 24
) -> Vector2:
	for _i in range(k_attempts):
		var px: float = roundf(_rng.randf_range(32.0, 400.0))
		var py: float = roundf(_rng.randf_range(46.0, 304.0))
		var candidate := Vector2(px, py)
		if not is_position_spawnable(candidate):
			continue
		var overlaps: bool = false
		for item in existing_trees:
			if item == null or not is_instance_valid(item):
				continue
			var other_pos: Vector2 = item.position
			var other_radius: float = float(item.get("clearance_radius")) if item.get("clearance_radius") != null else 14.0
			var min_dist: float = candidate_radius + other_radius
			if candidate.distance_squared_to(other_pos) < (min_dist * min_dist):
				overlaps = true
				break
		if not overlaps:
			return candidate
	return Vector2(-1.0, -1.0)


func _build_runtime_tileset() -> void:
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(TILE_SIZE_PX, TILE_SIZE_PX)
	_tileset.add_custom_data_layer()
	_tileset.set_custom_data_layer_name(0, CUSTOM_DATA_CAN_SPAWN)
	_tileset.set_custom_data_layer_type(0, TYPE_BOOL)

	var img: Image = Image.create(TILE_SIZE_PX * 4, TILE_SIZE_PX, false, Image.FORMAT_RGBA8)
	# Tile 0: Meadow grass (spawnable)
	_fill_tile(img, 0, Color(0.22, 0.36, 0.18, 1.0), Color(0.26, 0.41, 0.21, 1.0))
	# Tile 1: Clover / mossy grass (spawnable)
	_fill_tile(img, 1, Color(0.20, 0.34, 0.17, 1.0), Color(0.32, 0.48, 0.25, 1.0))
	# Tile 2: Dirt skid road (non-spawnable)
	_fill_tile(img, 2, Color(0.36, 0.27, 0.18, 1.0), Color(0.42, 0.32, 0.22, 1.0))
	# Tile 3: Perimeter / compound reserve (non-spawnable)
	_fill_tile(img, 3, Color(0.15, 0.24, 0.13, 1.0), Color(0.18, 0.28, 0.15, 1.0))

	var tex: ImageTexture = ImageTexture.create_from_image(img)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(TILE_SIZE_PX, TILE_SIZE_PX)

	for tx in range(4):
		var coords := Vector2i(tx, 0)
		atlas.create_tile(coords)
		var td: TileData = atlas.get_tile_data(coords, 0)
		if td != null:
			td.set_custom_data(CUSTOM_DATA_CAN_SPAWN, tx == 0 or tx == 1)

	_tileset.add_source(atlas, 0)

	if ground_base_layer != null:
		ground_base_layer.tile_set = _tileset
	if terrain_detail_layer != null:
		terrain_detail_layer.tile_set = _tileset
	if perimeter_treeline_layer != null:
		perimeter_treeline_layer.tile_set = _tileset


func _fill_tile(img: Image, tile_idx: int, base_col: Color, accent_col: Color) -> void:
	var x0: int = tile_idx * TILE_SIZE_PX
	img.fill_rect(Rect2i(x0, 0, TILE_SIZE_PX, TILE_SIZE_PX), base_col)
	# Subtle pixel-art dither specks
	img.set_pixel(x0 + 3, 4, accent_col)
	img.set_pixel(x0 + 11, 6, accent_col)
	img.set_pixel(x0 + 6, 12, accent_col)
	img.set_pixel(x0 + 13, 13, accent_col)


func _populate_default_clearing_map() -> void:
	if ground_base_layer == null:
		return
	ground_base_layer.clear()
	for y in range(GRID_ROWS):
		for x in range(GRID_COLS):
			var cell := Vector2i(x, y)
			var is_border: bool = (x == 0 or x == GRID_COLS - 1 or y <= 1 or y >= GRID_ROWS - 1)
			# Reserve lower-left corner for Sawmill & Charcoal Kiln compound landmark
			var is_compound_corner: bool = (x <= 5 and y >= 15)
			# Subtle horizontal dirt skid path leading from the lower-left compound
			var is_skid_path: bool = (y == 17 and x >= 5 and x <= 10)
			if is_border or is_compound_corner:
				ground_base_layer.set_cell(cell, 0, ATLAS_PERIMETER)
			elif is_skid_path:
				ground_base_layer.set_cell(cell, 0, ATLAS_DIRT_PATH)
			elif ((x * 7 + y * 13) % 5) == 0:
				ground_base_layer.set_cell(cell, 0, ATLAS_CLOVER)
			else:
				ground_base_layer.set_cell(cell, 0, ATLAS_MEADOW)
