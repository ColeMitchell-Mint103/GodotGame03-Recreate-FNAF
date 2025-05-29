extends Camera2D

var movespeed = 0.2 #Multiplier for camera pan
var moving = 1
var minPos = 0 #
var maxPos = 260
var center = 130
var panning = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	maxPos = DisplayServer.window_get_size()[0]
	center = maxPos - (maxPos / get_zoom().x)  #Setting window based on current size
	#Current resolution is 1150 x 648px wide 
	#offset = (resolution / zoom) - (maxresolutionx)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if panning:
		var currentX = get_position().x
		if currentX >= center: #Center x value is the left side of the camera when it reaches the rightmost position [___]
			moving = -1
			pause()
		if currentX <= minPos:
			moving = 1
			pause()
		var xpos_temp = currentX + moving * movespeed
		xpos_temp = clamp(xpos_temp, (0), center) #Keep camera (and children) within screen frame
		set_position(Vector2(xpos_temp, 0))

func pause():
	panning = false
	$CamPauseTimer.start(2)


func _on_cam_pause_timer_timeout() -> void:
	panning = true
