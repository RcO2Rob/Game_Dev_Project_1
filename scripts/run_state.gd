extends Node

# One-shot handoff between levels, not a save file. Direct F6 starts fresh.
var pending: Dictionary = {}

func capture(player: Node, destination: String) -> void:
	pending = {"scene": destination, "coins": player.coin_count,
		"diamonds": player.diamond_count, "health": player.current_health,
		"max_health": player.max_health, "sword": player.has_sword,
		"sword_kind": player.sword_kind, "sword_durability": player.sword_durability}

func restore(player: Node) -> void:
	if pending.is_empty() or player.get_parent().scene_file_path != pending.scene:
		return
	player.coin_count = pending.coins
	player.diamond_count = pending.diamonds
	player.max_health = pending.max_health
	player.current_health = pending.health
	if pending.sword:
		player.equip_sword(pending.get("sword_kind", "stone"), pending.get("sword_durability", 15))
	pending.clear()
