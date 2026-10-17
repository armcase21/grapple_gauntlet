class_name Hill
extends Area2D
## add an Area2D, attach this script, and set Size in the Inspector.
## builds its own collision shape at runtime and only tracks who is inside.
## scoring rules live in king_of_hill.gd.

@export var size := Vector2(300, 60)

var occupants: Array[Player] = []
var color := Color(1.0, 0.9, 0.2, 0.35)


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func set_color(new_color: Color) -> void:
	if new_color != color:
		color = new_color
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), color)


func _on_body_entered(body: Node2D) -> void:
	var p := body as Player
	if p != null and not occupants.has(p):
		occupants.append(p)


func _on_body_exited(body: Node2D) -> void:
	var p := body as Player
	if p != null:
		occupants.erase(p)
