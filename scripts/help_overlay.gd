extends CanvasLayer

const CONTROL_ROWS := [
	["A / D", "Move left / right"],
	["SPACE", "Swim upward (up to 3 jumps)"],
	["S", "Dive downward"],
	["N", "Pick up / throw a rock; pick up / drop a sword"],
	["M", "Swing the sword when holding one"],
	["H", "Open / close this help panel"],
]

@onready var overlay: Control = $Overlay
@onready var badge: Button = $Badge
@onready var rows: VBoxContainer = $Overlay/HelpPanel/Margin/Content/Rows

var _was_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_rows()
	overlay.hide()
	badge.pressed.connect(toggle)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("help") and not event.is_echo():
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if overlay.visible:
		close_help()
	else:
		open_help()


func open_help() -> void:
	if overlay.visible:
		return
	_was_paused = get_tree().paused
	overlay.show()
	badge.text = "H  CLOSE"
	get_tree().paused = true


func close_help() -> void:
	if not overlay.visible:
		return
	overlay.hide()
	badge.text = "H  HELP"
	get_tree().paused = _was_paused


func _build_rows() -> void:
	for entry in CONTROL_ROWS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		rows.add_child(row)

		var key := Label.new()
		key.text = entry[0]
		key.custom_minimum_size = Vector2(105, 32)
		key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		key.add_theme_color_override("font_color", Color("ffd76e"))
		key.add_theme_font_size_override("font_size", 18)
		row.add_child(key)

		var description := Label.new()
		description.text = entry[1]
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		description.add_theme_color_override("font_color", Color("e6f9ff"))
		description.add_theme_font_size_override("font_size", 16)
		row.add_child(description)
