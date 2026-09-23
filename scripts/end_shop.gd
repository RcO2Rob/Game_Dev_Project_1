extends CanvasLayer

const ICON_SCRIPT := preload("res://scripts/shop_icon.gd")
const COINS_PER_DIAMOND := 30
const KINDS := ["sword", "diamond_sword", "heal", "heart"]
const PRICES := {"sword": 2, "diamond_sword": 6, "heal": 1, "heart": 3}
var buyer: CharacterBody2D
var destination := ""
var finish_callback := Callable()
var opened := false
var balance_icon: Control
var cards: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	_build()
	hide()

func open_shop(player: CharacterBody2D, next_scene := "", callback := Callable()) -> void:
	if opened:
		return
	buyer = player
	destination = next_scene
	finish_callback = callback
	opened = true
	show()
	get_tree().paused = true
	_refresh()
	for card in cards:
		if not card.disabled:
			card.grab_focus()
			break

func purchase(kind: String) -> bool:
	if not opened or not is_instance_valid(buyer):
		return false
	if not KINDS.has(kind):
		return false
	var price: int = PRICES[kind]
	var coin_units: int = 0 if kind == "heart" else mini(price, buyer.coin_count / COINS_PER_DIAMOND)
	var diamonds_needed: int = price - coin_units
	if buyer.diamond_count < diamonds_needed:
		_flash(cards[KINDS.find(kind)], false)
		return false
	if kind == "sword":
		if not buyer.equip_sword("stone", -1, true):
			return false
	elif kind == "diamond_sword":
		if not buyer.equip_sword("diamond", -1, true):
			return false
	elif kind == "heal":
		if buyer.current_health >= buyer.max_health:
			return false
		buyer.current_health += 1
	elif buyer.max_health < 5:
		buyer.max_health += 1
		buyer.current_health += 1
	else:
		return false
	# Spend whole coin equivalents first; the permanent heart uses only diamonds.
	buyer.coin_count -= coin_units * COINS_PER_DIAMOND
	buyer.diamond_count -= diamonds_needed
	_flash(cards[KINDS.find(kind)], true)
	_refresh()
	return true

func continue_run() -> void:
	if not opened:
		return
	var player := buyer
	var next := destination
	var callback := finish_callback
	_hide_shop()
	if not next.is_empty():
		get_node("/root/RunState").capture(player, next)
		get_tree().call_deferred("change_scene_to_file", next)
	elif callback.is_valid():
		callback.call_deferred()

func _hide_shop() -> void:
	opened = false
	hide()
	get_tree().paused = false
	buyer = null
	destination = ""
	finish_callback = Callable()

func _refresh() -> void:
	balance_icon.set_status(buyer.coin_count, buyer.diamond_count, buyer.current_health, buyer.max_health)
	var can_replace_sword: bool = not buyer.has_sword or buyer.sword_kind == "wood"
	cards[0].disabled = not can_replace_sword or not _can_afford(2)
	cards[1].disabled = not can_replace_sword or not _can_afford(6)
	cards[2].disabled = buyer.current_health >= buyer.max_health or not _can_afford(1)
	cards[3].disabled = buyer.max_health >= 5 or buyer.diamond_count < 3

func _can_afford(price: int) -> bool:
	return buyer.diamond_count + buyer.coin_count / COINS_PER_DIAMOND >= price

func _flash(card: Button, success: bool) -> void:
	var tween := create_tween()
	card.modulate = Color("89ffd2") if success else Color("ff7c86")
	tween.tween_property(card, "modulate", Color.WHITE, 0.28)

func _card(kind: String, price: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(174, 180)
	button.text = ""
	var icon := ICON_SCRIPT.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.configure(kind, price, price * COINS_PER_DIAMOND if kind != "heart_up" else 0)
	button.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var descriptions := {
		"sword": "STONE SWORD · 15 HITS",
		"diamond_sword": "DIAMOND SWORD · 50 HITS",
		"heal": "RESTORE 1 LIFE",
		"heart_up": "PERMANENT +1 MAX LIFE",
	}
	var description := Label.new()
	description.name = "Description"
	description.text = descriptions[kind]
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.add_theme_color_override("font_color", Color("eafff7"))
	description.add_theme_font_size_override("font_size", 12)
	button.add_child(description)
	description.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	description.offset_top = -34
	description.offset_bottom = -8
	button.pressed.connect(purchase.bind("heart" if kind == "heart_up" else kind))
	cards.append(button)
	return button

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.035, 0.09, 0.88)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 560)
	center.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102f42")
	style.border_color = Color("66e6dc")
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	balance_icon = ICON_SCRIPT.new()
	balance_icon.kind = "balance"
	balance_icon.coins_per_diamond = COINS_PER_DIAMOND
	balance_icon.custom_minimum_size = Vector2(740, 72)
	column.add_child(balance_icon)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	row.add_child(_card("sword", 2))
	row.add_child(_card("diamond_sword", 6))
	row.add_child(_card("heal", 1))
	row.add_child(_card("heart_up", 3))
	var continue_button := Button.new()
	continue_button.custom_minimum_size = Vector2(740, 155)
	continue_button.text = ""
	var continue_icon := ICON_SCRIPT.new()
	continue_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_icon.configure("continue")
	continue_button.add_child(continue_icon)
	continue_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var next_label := Label.new()
	next_label.name = "NextLabel"
	next_label.text = "NEXT"
	next_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_label.add_theme_color_override("font_color", Color("eafff7"))
	next_label.add_theme_font_size_override("font_size", 22)
	continue_button.add_child(next_label)
	next_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	next_label.offset_top = -38
	next_label.offset_bottom = -8
	continue_button.pressed.connect(continue_run)
	column.add_child(continue_button)
