extends Area2D

@export_file("*.tscn") var next_scene := "res://scenes/stage_2.tscn"

var _transitioning := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _transitioning or not body.is_in_group("player"):
		return
	_transitioning = true
	set_deferred("monitoring", false)
	get_node("/root/EndShop").call_deferred("open_shop", body, next_scene)
