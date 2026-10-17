class_name Grapple
extends Node2D
## child of Player. Hitscan hook. pull modes fire one sharp impulse and let go;
## swing keeps the hook attached as a rope.

enum Mode { PULL_SELF, PULL_TARGET, SWING }

@export var max_range := 700.0
@export var pull_impulse := 800.0  # velocity change for a mass-1 object; heavier objects move less
@export var cooldown := 0.5        # seconds between pulls; 0 disables the cooldown

# --- state: this is what the network layer will need to sync ---
var attached := false              # only true while swinging
var mode := Mode.PULL_SELF
var target: Node2D = null          # null = static world anchor (wall, floor)
var local_anchor := Vector2.ZERO   # anchor in the target's local space, so it follows moving targets
var world_anchor := Vector2.ZERO   # used when target == null
var rope_length := 0.0             # used by SWING
var cooldown_left := 0.0

# visual only: brief line flash after a pull
var flash_left := 0.0
var flash_end := Vector2.ZERO

@onready var player: Player = get_parent()


func tick(inp: PlayerInput, delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if flash_left > 0.0:
		flash_left -= delta
		queue_redraw()

	if inp.mode_pressed:
		mode = ((mode + 1) % Mode.size()) as Mode
		release()
	if inp.release_pressed:
		release()
	if inp.fire_pressed:
		_fire(inp.aim_target)

	if attached:
		_tick_swing()


func release() -> void:
	attached = false
	target = null
	queue_redraw()


func anchor_position() -> Vector2:
	if target != null:
		return target.to_global(local_anchor)
	return world_anchor


func _fire(aim: Vector2) -> void:
	release()
	if mode != Mode.SWING and cooldown_left > 0.0:
		return

	var from := player.global_position
	if aim.is_equal_approx(from):
		return
	var dir := (aim - from).normalized()

	var query := PhysicsRayQueryParameters2D.create(from, from + dir * max_range)
	query.exclude = [player.get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var collider := hit.collider as Node2D
	var g := collider.get_node_or_null("Grappleable") as Grappleable
	var hit_pos: Vector2 = hit.position

	if mode == Mode.SWING:
		if g != null:
			target = collider
			local_anchor = collider.to_local(hit_pos)
		else:
			world_anchor = hit_pos
		attached = true
		rope_length = from.distance_to(hit_pos)
	else:
		_apply_pull(g, hit_pos)
	queue_redraw()


## one sharp pull. velocity change = impulse / mass, so mass decides who moves how far.
func _apply_pull(g: Grappleable, hit_pos: Vector2) -> void:
	var dir := (hit_pos - player.global_position).normalized()
	var impulse := dir * pull_impulse

	if mode == Mode.PULL_TARGET and g != null:
		g.apply_impulse(-impulse)  # target flies toward you
	else:
		# Pull Self, or Pull Target aimed at a wall (a wall can't be pulled to you)
		player.velocity += impulse / player.grappleable.mass_value

	cooldown_left = cooldown
	flash_end = hit_pos
	flash_left = 0.12


func _tick_swing() -> void:
	if target != null and not is_instance_valid(target):
		release()
		return
	var to_anchor := anchor_position() - player.global_position
	var dist := to_anchor.length()
	if dist < 1.0:
		return
	_swing(to_anchor / dist, dist)
	queue_redraw()


## rope constraint: you can't get farther than rope_length, and outward velocity is removed.
## gravity does the rest to give a pendulem
func _swing(dir_to_anchor: Vector2, dist: float) -> void:
	if dist <= rope_length:
		return
	player.global_position += dir_to_anchor * (dist - rope_length)
	var outward := -dir_to_anchor
	var v_out := player.velocity.dot(outward)
	if v_out > 0.0:
		player.velocity -= outward * v_out


func _draw() -> void:
	if attached and (target == null or is_instance_valid(target)):
		draw_line(Vector2.ZERO, to_local(anchor_position()), Color.WHITE, 2.0)
	elif flash_left > 0.0:
		draw_line(Vector2.ZERO, to_local(flash_end), Color.WHITE, 2.0)
