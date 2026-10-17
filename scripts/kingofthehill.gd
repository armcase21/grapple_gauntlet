class_name KingOfTheHill
extends Node
## rules for the koth mode. scoring runs in _physics_process using delta, so a server can own it
## everything worth syncing over the network lives in scores and winner.
## finds the Hill and all Player nodes among its siblings, and builds its own HUD.

signal winner_declared(winner_name: String)

@export var win_score := 30.0  # seconds of uncontested time on the hill

const EMPTY_COLOR := Color(1.0, 0.9, 0.2, 0.35)
const OWNED_COLOR := Color(0.2, 1.0, 0.3, 0.35)
const CONTESTED_COLOR := Color(1.0, 0.2, 0.2, 0.35)

var hill: Hill
var players: Array[Player] = []
var scores: Dictionary = {}  # player name -> seconds on the hill
var winner := ""
var status := "Empty"
var hud: Label


func _ready() -> void:
	for child in get_parent().get_children():
		if child is Hill and hill == null:
			hill = child as Hill
		elif child is Player:
			players.append(child as Player)

	if hill == null:
		push_error("KingOfTheHill: no Hill node found next to this node.")
		set_physics_process(false)
		return

	_build_hud()
	reset()


func reset() -> void:
	winner = ""
	scores.clear()
	for p in players:
		scores[str(p.name)] = 0.0
	_update_hud()


func _physics_process(delta: float) -> void:
	if winner != "":
		return

	var inside := hill.occupants
	if inside.size() == 1:
		var p_name := str(inside[0].name)
		scores[p_name] += delta
		status = "%s is king" % p_name
		hill.set_color(OWNED_COLOR)
		if scores[p_name] >= win_score:
			winner = p_name
			winner_declared.emit(p_name)
	elif inside.size() > 1:
		status = "Contested"
		hill.set_color(CONTESTED_COLOR)
	else:
		status = "Empty"
		hill.set_color(EMPTY_COLOR)

	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_R:
		reset()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(20, 20)
	hud.add_theme_font_size_override("font_size", 20)
	hud.add_theme_color_override("font_outline_color", Color.BLACK)
	hud.add_theme_constant_override("outline_size", 6)
	layer.add_child(hud)


func _update_hud() -> void:
	var lines: PackedStringArray = []
	lines.append("KING OF THE HILL  (first to %d s)" % int(win_score))
	for p_name in scores:
		lines.append("%s: %.1f" % [p_name, scores[p_name]])
	lines.append("Hill: %s" % status)
	if winner != "":
		lines.append("%s WINS!  Press R to restart" % winner)
	hud.text = "\n".join(lines)
