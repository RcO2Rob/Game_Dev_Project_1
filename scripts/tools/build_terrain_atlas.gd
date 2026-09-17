extends SceneTree

const TILE := 32
const ATLAS_SIZE := 256
const OUTPUT_PATH := "res://assets/art/tilesets/terrain_tileset_32.png"

const TRANSPARENT := Color(0, 0, 0, 0)
const SAND := Color("d9ad57")
const SAND_LIGHT := Color("f0cb72")
const SAND_DARK := Color("b9853e")
const ROCK := Color("28647b")
const ROCK_LIGHT := Color("3c8093")
const ROCK_DARK := Color("19485f")
const RUIN := Color("337889")
const RUIN_LIGHT := Color("55a0aa")
const RUIN_DARK := Color("1e5368")


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art/tilesets"))
	var image := Image.create_empty(ATLAS_SIZE, ATLAS_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)

	for x in range(8):
		_draw_sand_top(image, Vector2i(x * TILE, 0), x)
		_draw_rock_fill(image, Vector2i(x * TILE, TILE), x)
		_draw_ruin_block(image, Vector2i(x * TILE, TILE * 2), x)
		_draw_deep_block(image, Vector2i(x * TILE, TILE * 3), x)

	var save_error := image.save_png(OUTPUT_PATH)
	if save_error != OK:
		push_error("Could not save terrain atlas: %s" % error_string(save_error))
		quit(1)
		return
	print("Created exact 8x8 atlas at %s" % OUTPUT_PATH)
	quit()


func _draw_sand_top(image: Image, origin: Vector2i, variant: int) -> void:
	image.fill_rect(Rect2i(origin, Vector2i(TILE, TILE)), ROCK)
	_draw_rock_pattern(image, origin, variant)

	for local_x in range(TILE):
		var wave := sin(float(local_x) / 31.0 * PI)
		var sand_depth := 8 + int(round(wave * float((variant % 3) + 1)))
		for local_y in range(sand_depth + 1):
			_set_pixel(image, origin + Vector2i(local_x, local_y), SAND)
		_set_pixel(image, origin + Vector2i(local_x, max(sand_depth - 1, 0)), SAND_LIGHT)
		_set_pixel(image, origin + Vector2i(local_x, sand_depth), SAND_DARK)

	for dot in range(4):
		var px := 5 + ((dot * 7 + variant * 3) % 23)
		var py := 3 + ((dot * 3 + variant) % 4)
		_draw_disc(image, origin + Vector2i(px, py), 1, SAND_DARK)

	# The last two top tiles are reserved as clearly shaded hole-edge pieces.
	if variant == 6:
		image.fill_rect(Rect2i(origin + Vector2i(27, 9), Vector2i(5, 23)), ROCK_DARK)
	if variant == 7:
		image.fill_rect(Rect2i(origin + Vector2i(0, 9), Vector2i(5, 23)), ROCK_DARK)


func _draw_rock_fill(image: Image, origin: Vector2i, variant: int) -> void:
	image.fill_rect(Rect2i(origin, Vector2i(TILE, TILE)), ROCK)
	_draw_rock_pattern(image, origin, variant + 11)


func _draw_rock_pattern(image: Image, origin: Vector2i, variant: int) -> void:
	var centers := [
		Vector2i(8 + variant % 3, 16),
		Vector2i(23 - variant % 2, 20),
		Vector2i(14 + variant % 2, 28),
	]
	var radii := [6, 7, 5]
	for index in range(centers.size()):
		_draw_disc(image, origin + centers[index], radii[index], ROCK_DARK)
		_draw_disc(image, origin + centers[index] + Vector2i(-1, -1), radii[index] - 2, ROCK_LIGHT)
		_draw_disc(image, origin + centers[index], radii[index] - 3, ROCK)


func _draw_ruin_block(image: Image, origin: Vector2i, variant: int) -> void:
	image.fill_rect(Rect2i(origin, Vector2i(TILE, TILE)), RUIN)
	image.fill_rect(Rect2i(origin, Vector2i(TILE, 2)), RUIN_LIGHT)
	image.fill_rect(Rect2i(origin + Vector2i(0, 30), Vector2i(TILE, 2)), RUIN_DARK)
	var split := 13 + variant % 7
	image.fill_rect(Rect2i(origin + Vector2i(split, 2), Vector2i(2, 13)), RUIN_DARK)
	image.fill_rect(Rect2i(origin + Vector2i(0, 14), Vector2i(TILE, 2)), RUIN_DARK)
	image.fill_rect(Rect2i(origin + Vector2i(8, 16), Vector2i(2, 14)), RUIN_DARK)
	image.fill_rect(Rect2i(origin + Vector2i(23, 16), Vector2i(2, 14)), RUIN_DARK)


func _draw_deep_block(image: Image, origin: Vector2i, variant: int) -> void:
	image.fill_rect(Rect2i(origin, Vector2i(TILE, TILE)), RUIN_DARK)
	image.fill_rect(Rect2i(origin + Vector2i(1, 1), Vector2i(30, 2)), RUIN)
	for y in [10, 21]:
		image.fill_rect(Rect2i(origin + Vector2i(0, y), Vector2i(TILE, 2)), ROCK_DARK)
	var offset := 5 + variant % 5
	image.fill_rect(Rect2i(origin + Vector2i(offset, 3), Vector2i(2, 7)), ROCK_DARK)
	image.fill_rect(Rect2i(origin + Vector2i(24 - variant % 4, 12), Vector2i(2, 9)), ROCK_DARK)


func _draw_disc(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius:
				_set_pixel(image, center + Vector2i(x, y), color)


func _set_pixel(image: Image, point: Vector2i, color: Color) -> void:
	if point.x >= 0 and point.x < ATLAS_SIZE and point.y >= 0 and point.y < ATLAS_SIZE:
		image.set_pixelv(point, color)
