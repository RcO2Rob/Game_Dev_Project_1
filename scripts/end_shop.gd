extends CanvasLayer

const ICON_SCRIPT := preload("res://scripts/shop_icon.gd")
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
	var kinds := ["sword", "heal", "heart"]
	if not kinds.has(kind):
		return false
	var price: int = {"sword": 2, "heal": 1, "heart": 3}[kind]
	if buyer.diamond_count < price:
		_flash(cards[kinds.find(kind)], false)
		return false
	if kind == "sword":
		if buyer.has_sword or not buyer.equip_sword():
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
	buyer.diamond_count -= price
	_flash(cards[kinds.find(kind)], true)
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
	balance_icon.set_status(buyer.diamond_count, buyer.current_health, buyer.max_health)
	cards[0].disabled = buyer.has_sword or buyer.diamond_count < 2
	cards[1].disabled = buyer.current_health >= buyer.max_health or buyer.diamond_count < 1
	cards[2].disabled = buyer.max_health >= 5 or buyer.diamond_count < 3

func _flash(card: Button, success: bool) -> void:
	var tween := create_tween()
	card.modulate = Color("89ffd2") if success else Color("ff7c86")
	tween.tween_property(card, "modulate", Color.WHITE, 0.28)

func _card(kind: String, price: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(210, 180)
	button.text = ""
	var icon := ICON_SCRIPT.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.configure(kind, price)
	button.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	balance_icon.custom_minimum_size = Vector2(740, 72)
	column.add_child(balance_icon)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	column.add_child(row)
	row.add_child(_card("sword", 2))
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
	continue_button.pressed.connect(continue_run)
	column.add_child(continue_button)
