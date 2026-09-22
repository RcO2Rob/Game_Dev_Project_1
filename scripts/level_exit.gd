extends Area2D

@export_file("*.tscn") var next_scene := "res://scenes/stage_2.tscn"
@export var show_entry_hint := false

var _transitioning := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if show_entry_hint:
		_build_entry_hint()


func _build_entry_hint() -> void:
	var panel := PanelContainer.new()
	panel.name = "EntryHint"
	panel.position = Vector2(-190, -185)
	panel.size = Vector2(260, 64)
	panel.scale = Vector2(
		1.0 / maxf(absf(global_scale.x), 0.001),
		1.0 / maxf(absf(global_scale.y), 0.001)
	)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.105, 0.17, 0.94)
	style.border_color = Color(0.25, 0.86, 0.9, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.name = "Message"
	label.text = "ENTER THE SHELL\nNEXT LEVEL"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("eafff7"))
	label.add_theme_font_size_override("font_size", 18)
	panel.add_child(label)
	add_child(panel)


func _on_body_entered(body: Node) -> void:
	if _transitioning or not body.is_in_group("player"):
		return
	_transitioning = true
	set_deferred("monitoring", false)
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager:
		audio_manager.play_conch_enter()
	get_node("/root/EndShop").call_deferred("open_shop", body, next_scene)
