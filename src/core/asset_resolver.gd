class_name AssetResolver
extends RefCounted
## Centralized asset path resolver for the drop-in Aseprite pixel-art and audio pipeline.
##
## This project does NOT generate any visual or audio content. Artists and audio designers
## drop finished files into the conventional locations below and the game loads them
## automatically at runtime. When a file is absent, every caller keeps its current
## fallback presentation, so gameplay never depends on asset delivery.
##
## Conventions:
##   assets/sprites/workers/worker_<worker_id>.png           (base worker sprite)
##   assets/sprites/workers/worker_<worker_id>_gear<k>.png   (gear tier overlay, k in 1..6)
##   assets/sprites/trees/tree_<species_id>.png              (base tree sprite)
##   assets/sprites/trees/tree_<species_id>_r<rank>.png      (maturity rank sprite, r in 0..4)
##   assets/sprites/species/<species_id>.png                 (small UI wood badge icon)
##   assets/sprites/achievements/ach_<achievement_id>.png    (32x32 achievement icon)
##   assets/sprites/ui/<name>.png                            (UI chrome)
##   assets/tilesets/clearing_tileset.tres                   (16x16 clearing tileset)
##   assets/audio/sfx/<event_id>.wav or <event_id>.ogg       (sound effects)
##   assets/audio/music/<track_id>.ogg                       (music tracks)
##   assets/shaders/<name>.gdshader                          (post-process shaders)

const SPRITES_WORKERS_DIR: String = "res://assets/sprites/workers/"
const SPRITES_TREES_DIR: String = "res://assets/sprites/trees/"
const SPRITES_SPECIES_DIR: String = "res://assets/sprites/species/"
const SPRITES_ACHIEVEMENTS_DIR: String = "res://assets/sprites/achievements/"
const SPRITES_UI_DIR: String = "res://assets/sprites/ui/"
const TILESETS_DIR: String = "res://assets/tilesets/"
const AUDIO_SFX_DIR: String = "res://assets/audio/sfx/"
const AUDIO_MUSIC_DIR: String = "res://assets/audio/music/"
const SHADERS_DIR: String = "res://assets/shaders/"

const CLEARING_TILESET_NAME: String = "clearing_tileset.tres"


## Builds the canonical sprite path for a worker archetype (optionally a gear tier overlay).
static func worker_sprite_path(worker_id: StringName, gear_tier: int = 0) -> String:
	if gear_tier > 0:
		return "%sworker_%s_gear%d.png" % [SPRITES_WORKERS_DIR, String(worker_id), gear_tier]
	return "%sworker_%s.png" % [SPRITES_WORKERS_DIR, String(worker_id)]


## Builds the canonical sprite path for a tree species at a maturity rank.
static func tree_sprite_path(species_id: StringName, maturity_rank: int = 0) -> String:
	return "%stree_%s_r%d.png" % [SPRITES_TREES_DIR, String(species_id), maturity_rank]


## Builds the canonical path for a species UI badge icon.
static func species_badge_path(species_id: StringName) -> String:
	return "%s%s.png" % [SPRITES_SPECIES_DIR, String(species_id)]


## Builds the canonical path for an achievement icon.
static func achievement_icon_path(achievement_id: StringName) -> String:
	return "%s%s.png" % [SPRITES_ACHIEVEMENTS_DIR, String(achievement_id)]


## Builds the canonical path for a UI chrome texture.
static func ui_texture_path(texture_name: StringName) -> String:
	return "%s%s.png" % [SPRITES_UI_DIR, String(texture_name)]


## Returns the first existing sound effect path for an event, or "" when the asset
## has not been delivered yet.
static func sfx_path(event_id: StringName) -> String:
	var base: String = "%s%s" % [AUDIO_SFX_DIR, String(event_id)]
	if ResourceLoader.exists(base + ".wav"):
		return base + ".wav"
	if ResourceLoader.exists(base + ".ogg"):
		return base + ".ogg"
	return ""


## Returns the music track path for a track id, or "" when the asset is missing.
static func music_path(track_id: StringName) -> String:
	var path: String = "%s%s.ogg" % [AUDIO_MUSIC_DIR, String(track_id)]
	return path if ResourceLoader.exists(path) else ""


## Returns the shader path for a post-process shader, or "" when the asset is missing.
static func shader_path(shader_name: StringName) -> String:
	var path: String = "%s%s.gdshader" % [SHADERS_DIR, String(shader_name)]
	return path if ResourceLoader.exists(path) else ""


## Returns the path of the canonical clearing tileset resource.
static func tileset_path() -> String:
	return TILESETS_DIR + CLEARING_TILESET_NAME


## Loads the worker sprite (with gear overlay when available), or null when absent.
static func worker_sprite(worker_id: StringName, gear_tier: int = 0) -> Texture2D:
	if gear_tier > 0:
		var overlay_path: String = worker_sprite_path(worker_id, gear_tier)
		if ResourceLoader.exists(overlay_path):
			return load(overlay_path) as Texture2D
	return _load_texture(worker_sprite_path(worker_id))


## Loads the tree sprite for the maturity rank, falling back to the base sprite, or null.
static func tree_sprite(species_id: StringName, maturity_rank: int = 0) -> Texture2D:
	var ranked: Texture2D = _load_texture(tree_sprite_path(species_id, maturity_rank))
	if ranked != null:
		return ranked
	return _load_texture(tree_sprite_path(species_id))


## Loads the species UI badge icon, or null when absent.
static func species_badge(species_id: StringName) -> Texture2D:
	return _load_texture(species_badge_path(species_id))


## Loads the achievement icon, or null when absent.
static func achievement_icon(achievement_id: StringName) -> Texture2D:
	return _load_texture(achievement_icon_path(achievement_id))


## Loads a UI chrome texture, or null when absent.
static func ui_texture(texture_name: StringName) -> Texture2D:
	return _load_texture(ui_texture_path(texture_name))


static func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
