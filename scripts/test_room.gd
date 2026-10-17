extends Node2D
## debug readout for the test room

@onready var label: Label = $Label
@onready var player: Player = $Player


func _process(_delta: float) -> void:
	var g := player.grapple
	var mode_name: String = Grapple.Mode.keys()[g.mode]
	var text := "Mode: %s  (Q to change)\n" % mode_name

	if g.cooldown_left > 0.0:
		text += "Cooldown: %.1f s\n" % g.cooldown_left
	else:
		text += "Ready\n"

	if g.attached:
		var target_name := "static anchor (wall/floor)"
		if g.target != null and is_instance_valid(g.target):
			target_name = str(g.target.name)
		text += "Swinging from: %s" % target_name

	label.text = text
