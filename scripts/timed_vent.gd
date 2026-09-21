extends Area2D

@export var phase_offset := 0.0
@export var tutorial_mode := false
var _time := 0.0
var active := false

func _physics_process(delta: float) -> void:
	_time += delta
	var phase := fmod(_time + phase_offset, 4.8)
	active = phase >= 3.4
	var warning := phase >= 2.65 and not active
	var idle_alpha := 0.14 if tutorial_mode else 0.06
	$Jet.modulate.a = 0.82 if active else (0.38 if warning else idle_alpha)
	$Warning.text = ("↑ ↑" if active else ("! !" if warning else "○  ○")) if tutorial_mode else ("JET!" if active else ("! ! !" if warning else "WAIT / GO"))
	$Warning.modulate = Color("ffba73") if warning or active else Color("85ead8")
	var bubbles := get_node_or_null("Bubbles") as Node2D
	if bubbles:
		bubbles.position.y = -fmod(_time * (28.0 if active else 15.0), 25.0)
		bubbles.modulate.a = 1.0 if active else (0.85 if warning else 0.62)
	if active:
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				body.take_damage()
