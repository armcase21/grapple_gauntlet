class_name SoccerMode
extends Node
## Rules for the sports mode. Finds the Goals and Players among its siblings and the ball
## through the "ball" group, assigns teams, handles scoring and resets, and builds its own HUD.
## State worth syncing over the network: `scores`, `winner`, `pause_left`, each player's `team`.

signal goal_scored(team: int)
signal match_won(team: int)

@export var win_score := 5
## true: pulling the ball into YOUR OWN goal scores (fits a pull-only game).
## false: normal soccer, where the ball must go into the other team's goal.
@export var score_in_own_goal := false
@export var goal_pause := 1.5  # seconds between a goal and the reset

const TEAM_NAMES := ["Blue", "Red"]

var goals: Array[Goal] = []
var players: Array[Player] = []
var ball: RigidBody2D
var ball_start := Vector2.ZERO
var player_starts: Dictionary = {}  # Player -> start position
var scores := [0, 0]
var winner := -1
var message := ""
var pause_left := 0.0
var hud: Label


func _ready() -> void:
	for child in get_parent().get_children():
		if child is Goal:
			goals.append(child as Goal)
		elif child is Player:
			players.append(child as Player)
	ball = get_tree().get_first_node_in_group("ball") as RigidBody2D

	if goals.size() < 2 or ball == null:
		push_error("SoccerMode needs two Goal nodes beside it and a ball in the 'ball' group.")
		set_physics_process(false)
		return

	ball_start = ball.global_position
	for i in players.size():
		var p := players[i]
		p.team = i % 2  # alternate teams in scene order
		p.modulate = Goal.TEAM_COLORS[p.team]
		player_starts[p] = p.global_position
	for g in goals:
		g.ball_entered.connect(_on_ball_entered)

	_build_hud()
	_update_hud()


func _physics_process(delta: float) -> void:
	if pause_left <= 0.0:
		return
	pause_left -= delta
	if pause_left <= 0.0:
		message = ""
		_reset_positions()
		_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_R:
		restart()


func restart() -> void:
	scores = [0, 0]
	winner = -1
	message = ""
	pause_left = 0.0
	_reset_positions()
	_update_hud()


func _on_ball_entered(goal: Goal) -> void:
	if pause_left > 0.0 or winner != -1:
		return
	var scorer := goal.team if score_in_own_goal else 1 - goal.team
	scores[scorer] += 1
	goal_scored.emit(scorer)

	if scores[scorer] >= win_score:
		winner = scorer
		message = "%s WINS!  Press R to restart" % TEAM_NAMES[scorer]
		match_won.emit(scorer)
	else:
		message = "GOAL for %s!" % TEAM_NAMES[scorer]
		pause_left = goal_pause
	_update_hud()


func _reset_positions() -> void:
	# Teleport the ball through the physics server so the engine doesn't fight the move.
	var rid := ball.get_rid()
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0.0, ball_start))
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	for p in players:
		p.global_position = player_starts[p]
		p.velocity = Vector2.ZERO
		p.grapple.release()


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
	lines.append("SOCCER  (first to %d)" % win_score)
	lines.append("%s %d - %d %s" % [TEAM_NAMES[0], scores[0], scores[1], TEAM_NAMES[1]])
	if score_in_own_goal:
		lines.append("Pull the ball into YOUR goal to score")
	else:
		lines.append("Get the ball into the OTHER team's goal")
	if message != "":
		lines.append(message)
	hud.text = "\n".join(lines)
