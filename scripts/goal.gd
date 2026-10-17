@tool
class_name Goal
extends Area2D
## self building goal zone. add an Area2D, attach this script, then set Team and Size and place it
## `team` is the team that defends this goal. The zone shows in the editor as a tinted box.
## anything in the "ball" group that overlaps the zone counts as a goal

signal ball_entered(goal: Goal)

const TEAM_COLORS := [Color(0.3, 0.5, 1.0), Color(1.0, 0.35, 0.35)]  # 0 = blue, 1 = red

@export var team := 0:
	set(value):
		team = clampi(value, 0, 1)
		queue_redraw()

@export var size := Vector2(80, 200):
	set(value):
		size = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)


func _draw() -> void:
	var c: Color = TEAM_COLORS[team]
	c.a = 0.35
	draw_rect(Rect2(-size / 2.0, size), c)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		ball_entered.emit(self)
