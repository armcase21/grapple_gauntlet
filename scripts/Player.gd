class_name Player
extends CharacterBody2D
## the dummy is the same scene with PlayerInput.enabled = false.
 
@export var move_speed := 300.0
@export var ground_accel := 2000.0
@export var air_accel := 900.0
@export var ground_friction := 1800.0
@export var jump_velocity := -450.0
@export var gravity := 1200.0
@export var push_speed := 150.0


@export var max_jumps := 2

var jumps_remaining := 0
var team := 0

 
@onready var input: PlayerInput = $PlayerInput
@onready var grapple: Grapple = $Grapple
@onready var grappleable: Grappleable = $Grappleable
 
 
func _physics_process(delta: float) -> void:
	input.poll()
 
	velocity.y += gravity * delta
	_apply_horizontal_input(delta)
	if is_on_floor():
		jumps_remaining = max_jumps
	if input.jump_pressed and jumps_remaining > 0:
		velocity.y = jump_velocity
		jumps_remaining -= 1
 
	grapple.tick(input, delta)  # adds pull velocity or constrains the swing
	move_and_slide()
	_push_bodies()
	
	
	
	
	
 
func _apply_horizontal_input(delta: float) -> void:
	var axis := input.move_axis
	if axis == 0.0:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)
		return
 
	# dont brake momentum gained from a pull or swing just because a key is held
	var already_faster := signf(velocity.x) == signf(axis) and absf(velocity.x) > move_speed
	if already_faster:
		return
 
	var accel := ground_accel if is_on_floor() else air_accel
	velocity.x = move_toward(velocity.x, axis * move_speed, accel * delta)
	
func _push_bodies() -> void:
	if input.move_axis == 0.0:
		return
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var normal := c.get_normal()
		# only push sideways, and only in the direction the player is pressing
		var dir := signf(-normal.x)
		if absf(normal.x) <= 0.5 or dir != signf(input.move_axis):
			continue

		var collider := c.get_collider()
		if collider is RigidBody2D:
			var body := collider as RigidBody2D
			var speed := push_speed / body.mass
			if body.linear_velocity.x * dir < speed:
				body.linear_velocity.x = dir * speed
		elif collider is Player:
			var other := collider as Player
			var speed := push_speed / other.grappleable.mass_value
			if other.velocity.x * dir < speed:
				other.velocity.x = dir * speed
