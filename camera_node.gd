extends Node2D

var movespeed = 2
var moving = 0
var minPos = 0
var maxPos = 260
var center = 130

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position.x += moving * movespeed
	global_position.x = clamp(global_position.x, minPos, maxPos)

func _on_right_camera_pan_mouse_entered() -> void:
	moving = 1


func _on_right_camera_pan_mouse_exited() -> void:
	moving = 0


func _on_left_camera_pan_mouse_entered() -> void:
	moving = -1


func _on_left_camera_pan_mouse_exited() -> void:
	moving = 0
