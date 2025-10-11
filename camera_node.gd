extends Node2D

var movespeed = 2 #Multiplier for camera pan
var camera_tolerance = 200 # Pixels from edge of screen to activate camera pan.
var moving = 0
var minPos = 0 #
var maxPos = 260
var center = 130
var camDoNotMove = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not camDoNotMove:
		#Camera movement logic
		var mouse_pos = get_viewport().get_mouse_position()
		if mouse_pos.x - ($Camera2D/LeftCameraNode.get_global_position().x + camera_tolerance) <= 0:
			moving = -1
		elif mouse_pos.x - ($Camera2D/RightCameraNode.get_global_position().x - camera_tolerance) >= 0:
			moving = 1
		else:
			moving = 0
		var xpos_temp = $Camera2D.get_position().x + moving * movespeed
		xpos_temp = clamp(xpos_temp, -130, 130) #Keep camera (and children) within screen frame
		$Camera2D.set_position(Vector2(xpos_temp, 0))

#For Foxy attak
func moveCameraLeft():
	$Camera2D.set_position(Vector2(minPos, 0))
