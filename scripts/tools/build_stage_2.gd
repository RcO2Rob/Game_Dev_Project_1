extends SceneTree

# Run explicitly to regenerate stage_2.tscn. The saved TileMap and all objects
# are ordinary editor nodes; runtime never rebuilds user edits.
const WIDTH := 480
const HOLES := [46, 70, 114, 135, 155, 178, 215, 257, 292, 333, 368, 424, 449]
const PRECISION_GAP_START := 398
const PRECISION_GAP_END := 419
# Two-tile landing stones separated by three empty columns. Their height changes
# force the player to release horizontal input and time the next swim pulse.
const PRECISION_STONES := [
	[399, 400, 17],
	[404, 405, 15],
	[409, 410, 17],
	[414, 415, 14],
]
# Inclusive column spans and surface rows. Adjacent steps rise at most 96 px.
const RIDGES := [
	[22, 27, 16], [28, 33, 13], [34, 39, 15],
	[57, 62, 15], [63, 67, 12], [82, 89, 15],
	[123, 128, 16], [165, 171, 15],
	[202, 207, 15], [208, 212, 12], [225, 230, 15], [231, 237, 12], [238, 244, 9], [245, 250, 12],
	[270, 277, 15], [278, 283, 12],
	[302, 308, 16], [309, 315, 13], [316, 322, 10], [323, 328, 13],
	[344, 350, 15], [351, 356, 12],
	[389, 395, 15], [435, 440, 15], [441, 446, 12], [459, 464, 15]
]
# Optional upper paths: safe ground below, with a diamond at each summit.
const LEDGES := [
	[51, 55, 14], [57, 61, 10], [64, 68, 7],
	[146, 150, 14], [152, 156, 10], [158, 162, 7],
	[263, 267, 14], [269, 273, 10], [276, 281, 7],
	[335, 339, 14], [341, 345, 10], [348, 352, 7],
	[452, 456, 14], [458, 462, 10], [465, 469, 7]
]
var stage: Node2D
var terrain: TileMapLayer
var serial := 0


func _initialize() -> void:
	call_deferred("_build")


func add_owned(parent: Node, child: Node) -> Node:
	parent.add_child(child)
	child.owner = stage
	return child


func instance_at(path: String, title: String, pos: Vector2) -> Node2D:
	var node := (load(path) as PackedScene).instantiate() as Node2D
	node.name = title
	node.position = pos
	add_owned(stage, node)
	return node


func floor_row(column: int) -> int:
	for ridge in RIDGES:
		if column >= ridge[0] and column <= ridge[1]:
			return ridge[2]
	return 18


func is_hole(column: int) -> bool:
	if column >= PRECISION_GAP_START and column <= PRECISION_GAP_END:
		return true
	for start in HOLES:
		if column >= start and column < start + 3:
			return true
	return false


func label_at(parent: Node, title: String, text_value: String, pos: Vector2, font_size := 16) -> Label:
	var label := Label.new()
	label.name = title
	label.text = text_value
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("c5f6ec"))
	add_owned(parent, label)
	return label


func _build() -> void:
	stage = Node2D.new()
	stage.name = "Stage2"
	stage.set_script(load("res://scripts/stage_2.gd"))
	var original := (load("res://scenes/stage_1.tscn") as PackedScene).instantiate()
	for node_name in ["BackgroundLayer", "HUD"]:
		var copy := original.get_node(node_name).duplicate()
		add_owned(stage, copy)
		own_children(copy)
	original.free()
	stage.get_node("HUD").level_number = 2
	stage.get_node("HUD/Panel/Level").text = "LEVEL 2"
	terrain = TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = load("res://assets/tilesets/underwater_tileset.tres")
	add_owned(stage, terrain)
	for x in range(WIDTH):
		if is_hole(x):
			continue
		var surface := floor_row(x)
		for y in range(surface, 21):
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(x % 6, 0 if y == surface else 1))
	for ledge in LEDGES:
		for x in range(ledge[0], ledge[1] + 1):
			terrain.set_cell(Vector2i(x, ledge[2]), 0, Vector2i(x % 6, 0))
	_paint_precision_stones()
	for x in [-1, WIDTH]:
		for y in range(-3, 24):
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(0, 1))
	var player := instance_at("res://scenes/player.tscn", "Player", Vector2(120, 540))
	player.get_node("Camera2D").limit_right = WIDTH * 32
	for index in range(5):
		var base := index * 3072
		var bubbles := instance_at("res://scenes/effects/ambient_bubbles.tscn", "AmbientBubbles%d" % index, Vector2(base, 648))
		bubbles.area_size = Vector2(3072, 648)
		bubbles.bubble_count = 32
		label_at(stage, "Zone%d" % index, ["01  CORAL STEPS", "02  BUBBLE RIFTS", "03  REEF CROSSROADS", "04  SUNKEN RUINS", "05  LAST CROSSING"][index], Vector2(base + 140, 430), 22)
		instance_at("res://scenes/items/stone_sword_pickup.tscn", "Sword%d" % index, Vector2(base + 270, 540))
		instance_at("res://scenes/rock.tscn", "SupplyRock%d" % index, Vector2(base + 400, 540))
	_add_holes()
	_add_precision_gap()
	_add_rewards()
	_add_enemies()
	_add_checkpoints()
	_add_decorations()
	var conch := instance_at("res://scenes/props/conch_exit.tscn", "ConchExit", Vector2(15160, 561))
	conch.set_script(load("res://scripts/stage_2_exit.gd"))
	label_at(stage, "ExitSign", "CORAL SANCTUARY →", Vector2(14800, 435), 22)
	_add_completion()
	var packed := PackedScene.new()
	assert(packed.pack(stage) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/stage_2.tscn") == OK)
	stage.free()
	print("Stage 2 saved: 15360 px, 5 zones, 4 checkpoints, 13 rifts, 1 precision chasm, 5 optional diamonds")
	quit()


func own_children(parent: Node) -> void:
	for child in parent.get_children():
		child.owner = stage
		own_children(child)


func _add_holes() -> void:
	for column in HOLES:
		var hole := instance_at("res://scenes/hazards/seabed_hole.tscn", "Rift%d" % column, Vector2(column * 32 + 48, 576))
		hole.min_bubble_delay = 4.0
		hole.max_bubble_delay = 9.0
		var approach: int = column * 32 - 100
		instance_at("res://scenes/rock.tscn", "RiftRock%d" % column, Vector2(approach, floor_row(int(approach / 32)) * 32 - 25))
		for offset in [-16, 48, 112]:
			serial += 1
			instance_at("res://scenes/items/coin.tscn", "ArcCoin%d" % serial, Vector2(column * 32 + offset, 460 if offset == 48 else 485))


func _paint_precision_stones() -> void:
	for stone in PRECISION_STONES:
		for x in range(stone[0], stone[1] + 1):
			terrain.set_cell(Vector2i(x, stone[2]), 0, Vector2i(x % 6, 0))
			terrain.set_cell(Vector2i(x, stone[2] + 1), 0, Vector2i(x % 6, 1))


func _add_precision_gap() -> void:
	var gap_width := float(PRECISION_GAP_END - PRECISION_GAP_START + 1) * 32.0
	var gap_center_x := float(PRECISION_GAP_START + PRECISION_GAP_END + 1) * 16.0
	var chasm := Area2D.new()
	chasm.name = "PrecisionChasm"
	chasm.position.x = gap_center_x
	chasm.collision_layer = 0
	chasm.collision_mask = 1
	add_owned(stage, chasm)
	var opening := Polygon2D.new()
	opening.name = "DarkOpening"
	opening.z_index = -2
	opening.polygon = PackedVector2Array([
		Vector2(-gap_width * 0.5, 568), Vector2(gap_width * 0.5, 568),
		Vector2(gap_width * 0.5, 648), Vector2(-gap_width * 0.5, 648),
	])
	opening.color = Color(0.008, 0.025, 0.065, 0.94)
	add_owned(chasm, opening)
	var kill_shape := CollisionShape2D.new()
	kill_shape.name = "KillShape"
	kill_shape.position.y = 676
	kill_shape.shape = RectangleShape2D.new()
	kill_shape.shape.size = Vector2(gap_width, 120)
	add_owned(chasm, kill_shape)
	label_at(stage, "PrecisionWarning", "PRECISION CHASM  •  CONTROL EACH LANDING", Vector2(PRECISION_GAP_START * 32 - 290, 405), 17)
	for index in range(PRECISION_STONES.size()):
		var stone: Array = PRECISION_STONES[index]
		var center_x := float(stone[0] + stone[1] + 1) * 16.0
		instance_at("res://scenes/items/coin.tscn", "PrecisionCoin%d" % (index + 1), Vector2(center_x, stone[2] * 32 - 38))
	instance_at("res://scenes/items/diamond.tscn", "PrecisionDiamond", Vector2(414.5 * 32.0, 370))


func _add_rewards() -> void:
	for column in range(12, WIDTH - 8, 9):
		if is_hole(column):
			continue
		instance_at("res://scenes/items/coin.tscn", "RouteCoin%d" % column, Vector2(column * 32 + 16, floor_row(column) * 32 - 40))
	for index in range(LEDGES.size()):
		var ledge: Array = LEDGES[index]
		instance_at("res://scenes/items/coin.tscn", "LedgeCoin%d" % index, Vector2((ledge[0] + 1) * 32 + 16, ledge[2] * 32 - 28))
	for column in [66, 160, 279, 350]:
		instance_at("res://scenes/items/diamond.tscn", "Diamond%d" % column, Vector2(column * 32 + 16, 188))
	for column in [37, 86, 129, 185, 240, 281, 320, 373, 444, 473]:
		instance_at("res://scenes/props/breakable_barrel.tscn", "Barrel%d" % column, Vector2(column * 32 + 16, floor_row(column) * 32 - 25))


func _add_enemies() -> void:
	# Patrols are deliberately short and wholly inside solid, flat landing areas.
	for column in [17, 31, 86, 106, 126, 170, 185, 205, 234, 273, 312, 347, 373, 393, 426, 462]:
		var crab := instance_at("res://scenes/enemies/crab.tscn", "Crab%d" % column, Vector2(column * 32 + 16, floor_row(column) * 32 - 26))
		crab.patrol_distance = 38.0
		crab.move_speed = 34.0 if column < 100 else 43.0
	for column in [59, 150, 246, 305, 354, 438]:
		instance_at("res://scenes/enemies/urchin.tscn", "Urchin%d" % column, Vector2(column * 32 + 16, floor_row(column) * 32 - 15))
	for column in [79, 143, 176, 254, 289, 339, 365, 430, 447]:
		var jelly := instance_at("res://scenes/enemies/jellyfish.tscn", "Jellyfish%d" % column, Vector2(column * 32, 340))
		jelly.horizontal_range = 32.0
		jelly.vertical_range = 35.0
		jelly.drift_speed = 0.9
	# Lobsters patrol calmly until the player enters their unobstructed sight
	# range, then close the distance and attack with both claws.
	for column in [42, 98, 139, 191, 220, 286, 329, 470]:
		var lobster := instance_at("res://scenes/enemies/lobster.tscn", "Lobster%d" % column, Vector2(column * 32 + 16, floor_row(column) * 32 - 28))
		lobster.detection_range = 260.0 if column < 200 else 300.0


func _add_checkpoints() -> void:
	var container := Node2D.new()
	container.name = "Checkpoints"
	add_owned(stage, container)
	for index in range(1, 5):
		var checkpoint := Area2D.new()
		checkpoint.name = "Beacon%d" % index
		checkpoint.position = Vector2(index * 3072 + 80, 576)
		checkpoint.collision_layer = 0
		checkpoint.collision_mask = 1
		add_owned(container, checkpoint)
		var shape := CollisionShape2D.new()
		shape.shape = RectangleShape2D.new()
		shape.shape.size = Vector2(64, 600)
		shape.position.y = -300
		add_owned(checkpoint, shape)
		var lamp := Polygon2D.new()
		lamp.name = "Lamp"
		lamp.polygon = PackedVector2Array([Vector2(-20, 0), Vector2(20, 0), Vector2(12, -14), Vector2(4, -14), Vector2(4, -76), Vector2(18, -92), Vector2(0, -114), Vector2(-18, -92), Vector2(-4, -76), Vector2(-4, -14), Vector2(-12, -14)])
		lamp.color = Color("e6e6a2")
		add_owned(checkpoint, lamp)
		label_at(checkpoint, "Label", "CHECKPOINT", Vector2(-48, -145), 15)


func _add_decorations() -> void:
	for column in range(5, WIDTH - 5, 11):
		if is_hole(column):
			continue
		var path := "res://scenes/props/seaweed_cluster.tscn" if column % 2 else "res://scenes/props/coral_cluster.tscn"
		var decor := instance_at(path, "Decoration%d" % column, Vector2(column * 32, floor_row(column) * 32))
		decor.scale = Vector2.ONE * (0.5 if column % 3 else 0.65)
		decor.z_index = -1


func _add_completion() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Completion"
	layer.layer = 20
	layer.visible = false
	add_owned(stage, layer)
	var panel := Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(316, 214)
	panel.size = Vector2(520, 220)
	add_owned(layer, panel)
	label_at(panel, "Result", "STAGE 2 COMPLETE", Vector2(28, 24), 22)
	var button := Button.new()
	button.name = "Retry"
	button.text = "Replay Stage 2"
	button.position = Vector2(150, 150)
	button.size = Vector2(220, 46)
	add_owned(panel, button)
