extends CanvasLayer

const WEAPON_STATUS_SCRIPT := preload("res://scripts/weapon_status.gd")

@export_range(1, 99, 1) var level_number := 1

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var level: Label = $Panel/Level
@onready var status: Label = $Panel/Status
var weapon_status: Control


func _ready() -> void:
	weapon_status = WEAPON_STATUS_SCRIPT.new()
	weapon_status.name = "WeaponStatus"
	weapon_status.position = Vector2(18, 102)
	weapon_status.size = Vector2(70, 53)
	weapon_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_status.hide()
	$Panel.add_child(weapon_status)


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var hearts := "♥".repeat(player.current_health) + "♡".repeat(player.max_health - player.current_health)
	level.text = "LEVEL %d" % level_number
	status.text = "LIFE  %s    COINS  %02d    DIAMONDS  %02d" % [hearts, player.coin_count, player.diamond_count]
	weapon_status.visible = player.has_sword
	if player.has_sword:
		weapon_status.set_weapon_status(player.sword_kind, player.sword_durability, player.sword_max_durability)
