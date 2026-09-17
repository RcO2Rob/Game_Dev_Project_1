extends CanvasLayer

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var status: Label = $Panel/Status


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var hearts := "♥".repeat(player.current_health) + "♡".repeat(player.max_health - player.current_health)
	status.text = "LIFE  %s\nCOINS  %02d    DIAMONDS  %02d" % [hearts, player.coin_count, player.diamond_count]
