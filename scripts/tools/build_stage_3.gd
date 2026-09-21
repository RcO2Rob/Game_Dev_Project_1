extends SceneTree

# Creates only Stage 3. Never calls the Stage 1 or Stage 2 generators.
const WIDTH := 672
const GAPS := [[46, 48], [93, 95], [147, 149], [193, 195], [244, 255], [285, 297], [321, 323], [376, 378], [414, 416], [468, 483], [514, 526], [596, 606], [637, 639]]
const RIDGES := [
	[24, 29, 16], [30, 35, 13], [36, 40, 16], [63, 68, 16], [69, 74, 13], [75, 79, 10], [80, 85, 13],
	[137, 142, 16], [158, 163, 15], [164, 169, 12], [170, 175, 15], [206, 212, 15],
	[264, 269, 15], [270, 275, 12], [276, 280, 15], [308, 313, 15],
	[355, 361, 16], [362, 368, 13], [387, 393, 16], [394, 400, 13], [429, 437, 15],
	[458, 462, 16], [492, 497, 15], [498, 504, 12], [539, 545, 15],
	[580, 585, 16], [586, 590, 13], [619, 624, 16], [625, 630, 13], [647, 652, 16]]
const LEDGES := [[54, 58, 14], [60, 64, 10], [66, 70, 7], [181, 185, 14], [187, 191, 10], [197, 201, 7],
	[302, 305, 14], [308, 311, 10], [316, 319, 7], [403, 407, 14], [409, 413, 10], [419, 423, 7],
	[530, 533, 14], [537, 540, 10], [545, 548, 7], [607, 611, 14], [613, 617, 10], [620, 624, 7]]
const STONES := [[247, 248, 16], [251, 252, 14], [292, 293, 14], [470, 471, 16], [475, 476, 14], [480, 481, 16],
	[516, 517, 16], [520, 521, 14], [524, 525, 16], [601, 602, 14]]
var stage: Node2D
var terrain: TileMapLayer

func _initialize() -> void:
	call_deferred("build")

func own(parent: Node, child: Node) -> Node:
	parent.add_child(child)
	child.owner = stage
	return child

func own_descendants(node: Node) -> void:
	for child in node.get_children():
		child.owner = stage
		own_descendants(child)

func item(path: String, title: String, pos: Vector2) -> Node2D:
	var node := (load(path) as PackedScene).instantiate() as Node2D
	node.name = title
	node.position = pos
	own(stage, node)
	return node

func label(parent: Node, title: String, value: String, pos: Vector2, font_size := 18) -> Label:
	var node := Label.new()
	node.name = title
	node.position = pos
	node.text = value
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", Color("b4ede7"))
	own(parent, node)
	return node

func polygon(parent: Node, title: String, points: PackedVector2Array, color: Color) -> Polygon2D:
	var node := Polygon2D.new()
	node.name = title
	node.polygon = points
	node.color = color
	own(parent, node)
	return node

func rectangle(parent: Node, title: String, size: Vector2, pos: Vector2, color: Color) -> Polygon2D:
	var half := size * 0.5
	var node := polygon(parent, title, PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]), color)
	node.position = pos
	return node

func collision(parent: Node, size: Vector2, pos := Vector2.ZERO) -> void:
	var node := CollisionShape2D.new()
	node.name = "CollisionShape2D"
	node.shape = RectangleShape2D.new()
	node.shape.size = size
	node.position = pos
	own(parent, node)

func row(x: int) -> int:
	for ridge in RIDGES:
		if x >= ridge[0] and x <= ridge[1]:
			return ridge[2]
	return 18

func gap(x: int) -> bool:
	for span in GAPS:
		if x >= span[0] and x <= span[1]:
			return true
	return false

func build() -> void:
	stage = Node2D.new()
	stage.name = "Stage3"
	stage.set_script(load("res://scripts/stage_3.gd"))
	var source := (load("res://scenes/stage_2.tscn") as PackedScene).instantiate()
	for name in ["BackgroundLayer", "HUD"]:
		var copy := source.get_node(name).duplicate()
		own(stage, copy)
		own_descendants(copy)
	stage.get_node("BackgroundLayer/UnderwaterBackground").modulate = Color(0.65, 0.77, 0.87)
	stage.get_node("HUD").level_number = 3
	stage.get_node("HUD/Panel/Level").text = "LEVEL 3"
	var checkpoints := Node2D.new()
	checkpoints.name = "Checkpoints"
	own(stage, checkpoints)
	for index in range(1, 6):
		var beacon := source.get_node("Checkpoints/Beacon1").duplicate()
		beacon.name = "Beacon%d" % index
		beacon.position = Vector2(index * 3584 + 96, 576)
		own(checkpoints, beacon)
		own_descendants(beacon)
	source.free()
	terrain = TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = load("res://assets/tilesets/underwater_tileset.tres")
	own(stage, terrain)
	for x in range(WIDTH):
		if gap(x):
			continue
		for y in range(row(x), 21):
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(x % 6, 0 if y == row(x) else 1))
	for ledge in LEDGES + STONES:
		for x in range(ledge[0], ledge[1] + 1):
			terrain.set_cell(Vector2i(x, ledge[2]), 0, Vector2i(x % 6, 0))
	for x in [-1, WIDTH]:
		for y in range(-4, 24):
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(0, 1))
	item("res://scenes/player.tscn", "Player", Vector2(120, 540))
	for index in range(6):
		var base := index * 3584
		var ambient := item("res://scenes/effects/ambient_bubbles.tscn", "Ambient%d" % index, Vector2(base, 648))
		ambient.area_size = Vector2(3584, 648)
		ambient.bubble_count = 30
		label(stage, "Zone%d" % index, ["TEMPLE GARDEN", "CORAL PASSAGE →", "DRIFTING REEFS", "STEAM VAULT", "SILENT CHASM", "HEART OF THE SEA"][index], Vector2(base + 120, 360), 26)
	for span in GAPS:
		if span[1] - span[0] == 2:
			var hole := item("res://scenes/hazards/seabed_hole.tscn", "Rift%d" % span[0], Vector2((span[0] + 1.5) * 32, 576))
			hole.min_bubble_delay = 4.5
			hole.max_bubble_delay = 9.5
		else:
			var width: float = (span[1] - span[0] + 1) * 32
			rectangle(stage, "Chasm%d" % span[0], Vector2(width, 80), Vector2((span[0] + span[1] + 1) * 16, 620), Color("081525")).z_index = -2
	_add_obstacles()
	_add_collectibles()
	_add_enemies()
	for x in range(9, 661, 13):
		if gap(x):
			continue
		var decoration := item("res://scenes/props/seaweed_cluster.tscn" if x % 2 else "res://scenes/props/coral_cluster.tscn", "Decor%d" % x, Vector2(x * 32, row(x) * 32))
		decoration.scale = Vector2.ONE * 0.58
		decoration.z_index = -1
	var exit := item("res://scenes/props/conch_exit.tscn", "ConchExit", Vector2(21240, 561))
	exit.set_script(load("res://scripts/stage_2_exit.gd"))
	label(stage, "FinishSign", "THE HEART OF THE SEA →", Vector2(20800, 400), 24)
	_add_result()
	var packed := PackedScene.new()
	assert(packed.pack(stage) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/stage_3.tscn") == OK)
	stage.free()
	print("Stage 3 saved: 21504 px, six zones, five checkpoints")
	quit()

func _add_obstacles() -> void:
	for data in [[245, 530, 36], [288, 510, 46], [296, 525, 42], [598, 520, 40], [605, 530, 38]]:
		var platform := item("res://scenes/props/moving_reef.tscn", "MovingReef%d" % data[0], Vector2(data[0] * 32 + 16, data[1]))
		platform.travel = Vector2(data[2], 0)
	for index in range(6):
		var x: int = [349, 353, 383, 387, 409, 427][index]
		var vent := Area2D.new()
		vent.name = "Vent%d" % x
		vent.position = Vector2(x * 32 + 16, row(x) * 32)
		vent.collision_layer = 0
		vent.collision_mask = 1
		vent.set_script(load("res://scripts/timed_vent.gd"))
		vent.phase_offset = index * 0.8
		own(stage, vent)
		collision(vent, Vector2(44, 108), Vector2(0, -54))
		polygon(vent, "Jet", PackedVector2Array([Vector2(-22, 0), Vector2(-12, -116), Vector2(0, -140), Vector2(14, -116), Vector2(22, 0)]), Color("7cf5e4"))
		rectangle(vent, "Base", Vector2(50, 12), Vector2(0, -6), Color("304954"))
		label(vent, "Warning", "WAIT / GO", Vector2(-36, -168), 14)
	label(stage, "VentHint", "Flashing jets erupt soon. Wait, or swim above them.", Vector2(10800, 415), 18)
	label(stage, "MovingHint", "Ride the glowing reefs; release A/D to steady your landing.", Vector2(7430, 310), 18)
	label(stage, "NarrowHint", "Land on each stone to recharge your three jumps.", Vector2(14720, 340), 18)

func _add_collectibles() -> void:
	# Three entrance diamonds let a direct F6 tester use the first shop.
	for x in [7, 10, 13, 44, 91, 120, 154, 191, 231, 261, 300, 345, 381, 425, 455, 488, 529, 570, 611, 642]:
		item("res://scenes/items/diamond.tscn", "RouteDiamond%d" % x, Vector2(x * 32 + 16, row(x) * 32 - 38))
	for x in [68, 199, 317, 421, 546, 622]:
		item("res://scenes/items/diamond.tscn", "SecretDiamond%d" % x, Vector2(x * 32 + 16, 184))
	for x in range(17, 659, 7):
		if not gap(x):
			item("res://scenes/items/coin.tscn", "Coin%d" % x, Vector2(x * 32 + 16, row(x) * 32 - 42))
	for stone in STONES + LEDGES:
		item("res://scenes/items/coin.tscn", "LandingCoin%d" % stone[0], Vector2((stone[0] + 1) * 32, stone[2] * 32 - 34))
	for x in [21, 43, 89, 136, 190, 241, 283, 319, 374, 410, 466, 511, 594, 635]:
		item("res://scenes/rock.tscn", "Rock%d" % x, Vector2(x * 32, row(x) * 32 - 24))
	for x in [84, 208, 310, 431, 540, 648]:
		item("res://scenes/props/breakable_barrel.tscn", "Barrel%d" % x, Vector2(x * 32 + 16, row(x) * 32 - 24))
	# A lost weapon never makes progress impossible: rocks and stomps remain useful.
	for x in [113, 338, 563]:
		item("res://scenes/items/stone_sword_pickup.tscn", "SpareSword%d" % x, Vector2(x * 32, row(x) * 32 - 25))

func _add_enemies() -> void:
	for x in [27, 66, 83, 140, 161, 172, 209, 267, 278, 311, 359, 390, 432, 495, 542, 583, 621, 650]:
		var crab := item("res://scenes/enemies/crab.tscn", "Crab%d" % x, Vector2(x * 32 + 16, row(x) * 32 - 24))
		crab.patrol_distance = 30.0
		crab.move_speed = 43.0
	for x in [38, 76, 168, 274, 365, 397, 502, 588, 628]:
		item("res://scenes/enemies/urchin.tscn", "Urchin%d" % x, Vector2(x * 32 + 16, row(x) * 32 - 16))
	for x in [55, 180, 215, 304, 405, 445, 535, 612, 642]:
		var jelly := item("res://scenes/enemies/jellyfish.tscn", "Jelly%d" % x, Vector2(x * 32, 315))
		jelly.horizontal_range = 32
		jelly.vertical_range = 28
	for x in [100, 152, 218, 327, 440, 552, 658]:
		var lobster := item("res://scenes/enemies/lobster.tscn", "Lobster%d" % x, Vector2(x * 32, row(x) * 32 - 26))
		lobster.patrol_distance = 40
		lobster.detection_range = 200

func _add_result() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Completion"
	layer.layer = 20
	layer.visible = false
	own(stage, layer)
	var panel := Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(276, 174)
	panel.size = Vector2(600, 300)
	own(layer, panel)
	label(panel, "Result", "COMPLETE", Vector2(24, 24), 23)
	var button := Button.new()
	button.name = "Replay"
	button.text = "Replay Stage 3 (fresh run)"
	button.position = Vector2(150, 238)
	button.size = Vector2(300, 44)
	own(panel, button)
