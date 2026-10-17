class_name PlayerInput
extends Node2D


@export var enabled := true  # so we can turn off the dummy

var move_axis := 0.0
var jump_pressed := false
var aim_target := Vector2.ZERO  # world-space aim position
var fire_pressed := false       # true only on the tick the button went down
var release_pressed := false
var mode_pressed := false


func poll() -> void:
	if not enabled:
		clear()
		return
	move_axis = Input.get_axis("move_left", "move_right")
	jump_pressed = Input.is_action_just_pressed("jump")
	aim_target = get_global_mouse_position()
	fire_pressed = Input.is_action_just_pressed("grapple_fire")
	release_pressed = Input.is_action_just_pressed("grapple_release")
	mode_pressed = Input.is_action_just_pressed("grapple_mode")


func clear() -> void:
	move_axis = 0.0
	jump_pressed = false
	fire_pressed = false
	release_pressed = false
	mode_pressed = false
