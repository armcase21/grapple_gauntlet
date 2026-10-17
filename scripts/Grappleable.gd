class_name Grappleable
extends Node
## add as a child node named exactly "Grappleable" to anything that can be grappled(crate, ball, player, dummy). Objects without it act as static anchors (walls, floor).

@export var mass_value := 1.0


func _ready() -> void:
	var rb := get_parent() as RigidBody2D
	if rb:
		rb.mass = mass_value


## called once when something pulls on this object. velocity changes by impulse / mass.
func apply_impulse(impulse: Vector2) -> void:
	var parent := get_parent()
	if parent is RigidBody2D:
		(parent as RigidBody2D).apply_central_impulse(impulse)
	elif parent is CharacterBody2D:
		var cb := parent as CharacterBody2D
		cb.velocity += impulse / mass_value
