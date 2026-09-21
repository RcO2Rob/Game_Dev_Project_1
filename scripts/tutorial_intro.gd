extends CanvasLayer

var active := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_pause_for_intro")


func _pause_for_intro() -> void:
	if active and is_inside_tree():
		get_tree().paused = true


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("swim") or event.is_action_pressed("ui_accept"):
		dismiss()
		get_viewport().set_input_as_handled()


func dismiss() -> void:
	if not active:
		return
	active = false
	get_tree().paused = false
	hide()
