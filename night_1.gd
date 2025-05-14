extends ColorRect

var hourLength = 60 #seconds
var current_time = 0
var hour = 0 #stupid fucking AM
var power = 100.0 #float for fun
var power_usage = 1 #clamp between 1 and 4
var power_factor = 0.23 #power modifier
var freddy_factor #not ready for freddy
var night = 1
var left_door_open = true
var right_door_open = true
var camera_open = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#core game loop
func tick():
	current_time += 1
	hour = current_time / hourLength
	power -= power_usage * power_factor
	if power <= 0:
		powerout()
	if hour == 6:
		win_game()

#Lights off, open doors, DISABLE AI, freddy singing blah blah
func powerout():
	pass

# Stop AI, roll clock, play fanfare, load next night
func win_game():
	pass

func _on_game_tick_timeout() -> void:
	tick()

#Wait for animation, then start the game
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Fadeout":
		$GameTick.start()
		$GameScreen_Base.set_visible(true)
		$CameraNode.set_visible(true)

#honk honk
func _on_fred_nose_button_down() -> void:
	$GameScreen_Base/TextureRect/FredNose/Honk.play()


func _on_left_door_toggled(toggled_on: bool) -> void:
	if toggled_on: power_usage += 1
	else : power_usage -= 1
	left_door_open = !toggled_on
	#play sound

func _on_left_light_toggled(toggled_on: bool) -> void:
	if toggled_on: power_usage += 1
	else : power_usage -= 1
	#play light sound

func _on_right_door_toggled(toggled_on: bool) -> void:
	if toggled_on: power_usage += 1
	else : power_usage -= 1
	right_door_open = !toggled_on

func _on_right_light_toggled(toggled_on: bool) -> void:
	if toggled_on: power_usage += 1
	else : power_usage -= 1
	#play light sound

#Open the camera system
func _on_cam_access_mouse_entered() -> void:
	if not camera_open:
		#play animation, open camera panel
		pass
