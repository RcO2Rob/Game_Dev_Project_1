extends SceneTree

const TILE_SIZE := 32
const MAP_WIDTH := 72
const MAP_HEIGHT := 20
const TILESET_PATH := "res://assets/tilesets/underwater_tileset.tres"
const STAGE_PATH := "res://scenes/stage_1.tscn"
const FLOOR_HOLES := [Vector2i(23, 25), Vector2i(39, 41), Vector2i(56, 58)]


func _initialize() -> void:
	call_deferred("_build")


func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/tilesets"))

	var tile_set := _build_tile_set()
	var tile_set_error := ResourceSaver.save(tile_set, TILESET_PATH)
	if tile_set_error != OK:
		push_error("Could not save TileSet: %s" % error_string(tile_set_error))
		quit(1)
		return

	# Reload the saved resource so the scene references the editable .tres file
	# instead of embedding a private copy of the TileSet.
	var saved_tile_set := load(TILESET_PATH) as TileSet
	var stage := _build_stage(saved_tile_set)
	var packed_stage := PackedScene.new()
	var pack_error := packed_stage.pack(stage)
	if pack_error != OK:
		push_error("Could not pack Stage 1: %s" % error_string(pack_error))
		quit(1)
		return

	var save_error := ResourceSaver.save(packed_stage, STAGE_PATH)
	if save_error != OK:
		push_error("Could not save Stage 1: %s" % error_string(save_error))
		quit(1)
		return

	print("Created %s and %s" % [TILESET_PATH, STAGE_PATH])
	quit()


func _build_tile_set() -> TileSet:
	var texture := load("res://assets/art/tilesets/terrain_tileset_32.png") as Texture2D
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)

	for y in range(8):
		for x in range(8):
			var atlas_coords := Vector2i(x, y)
			atlas.create_tile(atlas_coords)
	tile_set.add_source(atlas, 0)

	# The first four atlas rows are terrain pieces. Giving them a full-cell
	# collision shape makes painted platforms immediately playable and editable.
	var collision := PackedVector2Array([
		Vector2(-16, -16),
		Vector2(16, -16),
		Vector2(16, 16),
		Vector2(-16, 16),
	])
	for y in range(4):
		for x in range(8):
			var tile_data := atlas.get_tile_data(Vector2i(x, y), 0)
			tile_data.add_collision_polygon(0)
			tile_data.set_collision_polygon_points(0, 0, collision)

	return tile_set


func _build_stage(tile_set: TileSet) -> Node2D:
	var root := Node2D.new()
	root.name = "Stage1"
	_add_background(root)
	_add_pineapple_house(root)

	var terrain := TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = tile_set
	_add_owned(root, terrain, root)
	_paint_floor(terrain)
	_paint_platform(terrain, 13, 21, 14)
	_paint_platform(terrain, 28, 35, 10)
	_paint_platform(terrain, 43, 52, 14)
	_paint_platform(terrain, 59, 66, 11)

	var player_scene := load("res://scenes/player.tscn") as PackedScene
	var player := player_scene.instantiate()
	player.name = "Player"
	player.position = Vector2(55, 520)
	_add_owned(root, player, root)

	var rock_scene := load("res://scenes/rock.tscn") as PackedScene
	for rock_data in [
		["RockOne", Vector2(320, 540)],
		["RockTwo", Vector2(650, 540)],
		["RockThree", Vector2(990, 270)],
	]:
		var rock := rock_scene.instantiate()
		rock.name = rock_data[0]
		rock.position = rock_data[1]
		_add_owned(root, rock, root)

	_add_enemies(root)
	_add_seabed_holes(root)
	_add_coins(root)
	_add_diamonds(root)

	_add_hud(root)
	return root


func _add_enemies(root: Node2D) -> void:
	var enemy_data := [
		["res://scenes/enemies/crab.tscn", "CrabOne", Vector2(500, 520)],
		["res://scenes/enemies/jellyfish.tscn", "JellyfishOne", Vector2(750, 390)],
		["res://scenes/enemies/urchin.tscn", "UrchinOne", Vector2(930, 520)],
		["res://scenes/enemies/crab.tscn", "CrabTwo", Vector2(1030, 270)],
	]
	for data in enemy_data:
		var enemy_scene := load(data[0]) as PackedScene
		var enemy := enemy_scene.instantiate()
		enemy.name = data[1]
		enemy.position = data[2]
		_add_owned(root, enemy, root)


func _add_seabed_holes(root: Node2D) -> void:
	var hole_scene := load("res://scenes/hazards/seabed_hole.tscn") as PackedScene
	for index in range(FLOOR_HOLES.size()):
		var hole_range: Vector2i = FLOOR_HOLES[index]
		var center_column := (hole_range.x + hole_range.y + 1) * 0.5
		var hole := hole_scene.instantiate()
		hole.name = "BubbleHole%d" % (index + 1)
		hole.position = Vector2(center_column * TILE_SIZE, 560)
		_add_owned(root, hole, root)


func _add_coins(root: Node2D) -> void:
	var coin_scene := load("res://scenes/items/coin.tscn") as PackedScene
	var coin_positions := [
		Vector2(360, 505),
		Vector2(480, 390),
		Vector2(570, 390),
		Vector2(670, 505),
		Vector2(990, 505),
		Vector2(1040, 260),
		Vector2(1280, 390),
		Vector2(1480, 405),
		Vector2(1780, 505),
	]
	for index in range(coin_positions.size()):
		var coin := coin_scene.instantiate()
		coin.name = "Coin%d" % (index + 1)
		coin.position = coin_positions[index]
		_add_owned(root, coin, root)


func _add_diamonds(root: Node2D) -> void:
	var diamond_scene := load("res://scenes/items/diamond.tscn") as PackedScene
	var diamond_positions := [
		Vector2(1015, 235),
		Vector2(1940, 340),
	]
	for index in range(diamond_positions.size()):
		var diamond := diamond_scene.instantiate()
		diamond.name = "Diamond%d" % (index + 1)
		diamond.position = diamond_positions[index]
		_add_owned(root, diamond, root)


func _add_background(root: Node2D) -> void:
	var background_layer := CanvasLayer.new()
	background_layer.name = "BackgroundLayer"
	background_layer.layer = -10
	_add_owned(root, background_layer, root)

	var background := TextureRect.new()
	background.name = "UnderwaterBackground"
	background.position = Vector2.ZERO
	background.size = Vector2(1152, 648)
	background.texture = load("res://assets/art/backgrounds/underwater_background.png") as Texture2D
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_owned(background_layer, background, root)


func _add_pineapple_house(root: Node2D) -> void:
	var house_scene := load("res://scenes/props/pineapple_house.tscn") as PackedScene
	var house := house_scene.instantiate()
	house.name = "PineappleHouse"
	# Centering the house on x=0 leaves exactly its right half visible.
	house.position = Vector2(0, 488)
	_add_owned(root, house, root)


func _paint_floor(terrain: TileMapLayer) -> void:
	for x in range(MAP_WIDTH):
		if _is_hole_column(x):
			continue
		var top_tile_x := x % 6
		if _is_hole_column(x + 1):
			top_tile_x = 6
		elif _is_hole_column(x - 1):
			top_tile_x = 7
		terrain.set_cell(Vector2i(x, 18), 0, Vector2i(top_tile_x, 0), 0)
		terrain.set_cell(Vector2i(x, 19), 0, Vector2i(x % 6, 1), 0)


func _is_hole_column(x: int) -> bool:
	for hole_range in FLOOR_HOLES:
		if x >= hole_range.x and x <= hole_range.y:
			return true
	return false


func _paint_platform(terrain: TileMapLayer, start_x: int, end_x: int, y: int) -> void:
	for x in range(start_x, end_x + 1):
		terrain.set_cell(Vector2i(x, y), 0, Vector2i((x - start_x) % 6, 0), 0)
		terrain.set_cell(Vector2i(x, y + 1), 0, Vector2i((x - start_x) % 6, 1), 0)


func _add_hud(root: Node2D) -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(load("res://scripts/hud.gd"))
	_add_owned(root, hud, root)

	var panel := ColorRect.new()
	panel.name = "Panel"
	panel.position = Vector2(24, 22)
	panel.size = Vector2(438, 88)
	panel.color = Color(0.01, 0.07, 0.12, 0.78)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_owned(hud, panel, root)

	var level := Label.new()
	level.name = "Level"
	level.position = Vector2(18, 9)
	level.size = Vector2(395, 25)
	level.text = "LEVEL 1"
	level.add_theme_font_size_override("font_size", 18)
	level.add_theme_color_override("font_color", Color("f2d75b"))
	_add_owned(panel, level, root)

	var status := Label.new()
	status.name = "Status"
	status.position = Vector2(18, 42)
	status.size = Vector2(410, 30)
	status.text = "LIFE  ♥♥♥    COINS  00    DIAMONDS  00"
	status.add_theme_font_size_override("font_size", 18)
	status.add_theme_color_override("font_color", Color("ffffff"))
	_add_owned(panel, status, root)


func _add_owned(parent: Node, child: Node, owner: Node) -> void:
	parent.add_child(child)
	child.owner = owner
