class_name CompoundLandmark
extends Node2D
## Renders the lower-left Compound Landmark inside the 3/4 Logging Clearing
## (occupying the reserved exclusion rect Rect2(0, 224, 144, 108)):
## - Water-Powered Sawmill shed with rotating waterwheel
## - Brick Charcoal Kiln & Steam Boiler with animated firebox glow
## Clicking the Brick Kiln stokes the Steam Boiler thermal overclock gauge.

signal stoke_requested()

@export var custom_sawmill_texture: Texture2D
@export var custom_kiln_texture: Texture2D

var wheel_phase: float = 0.0
var thermal_pressure: float = 0.25
var active_sawmill_workers: int = 0

var _sawmill_sprite: Sprite2D
var _wheel_sprite: Sprite2D
var _kiln_sprite: Sprite2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_sprites()


func _process(delta: float) -> void:
	if _wheel_sprite != null:
		var speed_factor: float = 1.2 + float(active_sawmill_workers) * 1.1 + thermal_pressure * 1.5
		wheel_phase = fmod(wheel_phase + delta * speed_factor, TAU)
		_wheel_sprite.rotation = wheel_phase
	if _kiln_sprite != null:
		var glow: float = 0.85 + 0.25 * thermal_pressure
		_kiln_sprite.modulate = Color(glow, 0.85 + 0.15 * thermal_pressure, 0.82, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var local_pos: Vector2 = to_local(get_global_mouse_position())
			# Kiln click region in local landmark coordinates
			if Rect2(Vector2(66.0, 8.0), Vector2(56.0, 56.0)).has_point(local_pos):
				stoke_requested.emit()


func set_visual_state(sawmill_workers: int, boiler_pressure: float) -> void:
	active_sawmill_workers = maxi(0, sawmill_workers)
	thermal_pressure = clampf(boiler_pressure, 0.0, 1.0)


func _build_sprites() -> void:
	_sawmill_sprite = Sprite2D.new()
	_sawmill_sprite.name = "SawmillShedSprite"
	_sawmill_sprite.centered = false
	_sawmill_sprite.position = Vector2(6.0, 12.0)
	_sawmill_sprite.texture = custom_sawmill_texture if custom_sawmill_texture != null else _make_sawmill_texture()
	add_child(_sawmill_sprite)

	_wheel_sprite = Sprite2D.new()
	_wheel_sprite.name = "WaterwheelSprite"
	_wheel_sprite.centered = true
	_wheel_sprite.position = Vector2(18.0, 44.0)
	_wheel_sprite.texture = _make_waterwheel_texture()
	add_child(_wheel_sprite)

	_kiln_sprite = Sprite2D.new()
	_kiln_sprite.name = "BrickKilnSprite"
	_kiln_sprite.centered = false
	_kiln_sprite.position = Vector2(72.0, 14.0)
	_kiln_sprite.texture = custom_kiln_texture if custom_kiln_texture != null else _make_kiln_texture()
	add_child(_kiln_sprite)


func _make_sawmill_texture() -> ImageTexture:
	var img := Image.create(56, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Stone foundation & mill race channel
	img.fill_rect(Rect2i(4, 34, 48, 12), Color(0.28, 0.30, 0.33, 1.0))
	img.fill_rect(Rect2i(2, 38, 30, 8), Color(0.18, 0.44, 0.62, 1.0))
	# Timber walls
	img.fill_rect(Rect2i(10, 16, 38, 20), Color(0.46, 0.30, 0.17, 1.0))
	img.fill_rect(Rect2i(14, 20, 30, 14), Color(0.32, 0.20, 0.11, 1.0))
	# Silver sawblade inside shed
	img.fill_rect(Rect2i(24, 22, 10, 10), Color(0.78, 0.82, 0.86, 1.0))
	# Pitched shingle roof
	img.fill_rect(Rect2i(6, 10, 46, 7), Color(0.36, 0.22, 0.13, 1.0))
	img.fill_rect(Rect2i(12, 5, 34, 6), Color(0.42, 0.26, 0.15, 1.0))
	return ImageTexture.create_from_image(img)


func _make_waterwheel_texture() -> ImageTexture:
	var img := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(9.5, 9.5)
	for y in range(20):
		for x in range(20):
			var d: float = Vector2(float(x), float(y)).distance_to(center)
			if d >= 7.0 and d <= 9.2:
				img.set_pixel(x, y, Color(0.52, 0.34, 0.18, 1.0))
			elif d <= 2.5:
				img.set_pixel(x, y, Color(0.72, 0.74, 0.78, 1.0))
			elif x == 9 or x == 10 or y == 9 or y == 10:
				if d < 8.5:
					img.set_pixel(x, y, Color(0.42, 0.27, 0.14, 1.0))
	return ImageTexture.create_from_image(img)


func _make_kiln_texture() -> ImageTexture:
	var img := Image.create(48, 44, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Base & brick dome
	img.fill_rect(Rect2i(4, 32, 40, 10), Color(0.30, 0.28, 0.28, 1.0))
	img.fill_rect(Rect2i(8, 16, 32, 18), Color(0.58, 0.26, 0.18, 1.0))
	img.fill_rect(Rect2i(12, 10, 24, 8), Color(0.64, 0.30, 0.20, 1.0))
	# Chimney stack & copper steam boiler pipe
	img.fill_rect(Rect2i(20, 2, 8, 9), Color(0.44, 0.20, 0.15, 1.0))
	img.fill_rect(Rect2i(36, 18, 8, 14), Color(0.74, 0.48, 0.24, 1.0))
	# Glowing firebox arch
	img.fill_rect(Rect2i(18, 24, 12, 10), Color(0.22, 0.10, 0.08, 1.0))
	img.fill_rect(Rect2i(20, 26, 8, 8), Color(0.96, 0.52, 0.14, 1.0))
	img.fill_rect(Rect2i(22, 28, 4, 5), Color(1.0, 0.84, 0.32, 1.0))
	return ImageTexture.create_from_image(img)
