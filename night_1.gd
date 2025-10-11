extends ColorRect

var hourLength = 120 #seconds
var current_time = 0
var hour = 0 #stupid fucking AM
var power = 100.0 #float for fun
var power_usage = 1 #clamp between 1 and 4?
var power_factor = 0.13 #power modifier
var freddy_factor #not ready for freddy - soon golden freddy activity
var night = 1
var camera_open = false
var dev_mode = true
var animatronic_aggression = [10, 10, 10, 3] #Bonnie, Chica, Freddy, Foxy
var leftDoorOpen = true
var rightDoorOpen = true

var gotKilled = "NO"
var leftControlsEnabled = true
var rightControlsEnabled = true
var camDoNotOpen = false
@onready var power_meter_list = [$CameraNode/Camera2D/HUD/Time_PowerInfo/Meter/Low,
 $CameraNode/Camera2D/HUD/Time_PowerInfo/Meter/Medium,
 $CameraNode/Camera2D/HUD/Time_PowerInfo/Meter/High,
 $CameraNode/Camera2D/HUD/Time_PowerInfo/Meter/Veryhigh]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not dev_mode: #dev mode skips intro
		$CameraNode.set_visible(false)
		$GameScreen_Base.set_visible(false)
		$CameraNode/Camera2D/HUD.set_visible(false)
		$AnimationPlayer.play("Fadeout")
	else: game_start()


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
	
	#UI Update
	#Maybe too many ticks? performance
	$CameraNode/Camera2D/HUD/Time_PowerInfo/Power.set_text("Power: " + str(int(power)) + "%")
	var time_key = str(hour) if hour > 0 else "12" #Stupid fucking time system
	$CameraNode/Camera2D/HUD/Box_TimeInfo/Time.set_text(time_key + " AM")
	#Tick the AI control
	$AnimatronicAIController.tick()

func game_start():
	$GameTick.start()
	$GameScreen_Base.set_visible(true)
	$CameraNode.set_visible(true)
	$CameraNode/Camera2D/HUD.set_visible(true)
	$AnimatronicAIController.initialize(animatronic_aggression)
	
#Lights off, open doors, DISABLE AI, freddy singing blah blah
func powerout():
	pass #give freddy megalovania notes

# Stop AI, roll clock, play fanfare, load next night
func win_game():
	pass #unenthusiastic party horn, animation, load next night

#End game logic
func lose_game():
	$GameTick.stop()
	$CameraNode/Camera2D.set_position(Vector2(0,0))
	$CameraNode/Camera2D/HUD.set_visible(false)
	$CameraNode/Camera2D/JumpscareLayer.set_visible(false)
	#crrep screen
	match gotKilled:
		"BONNIE": $CameraNode/Camera2D/GameOverScreen.set_texture(load("res://Textures/BonnieDeath.png"))
		"CHICA": $CameraNode/Camera2D/GameOverScreen.set_texture(load("res://Textures/ChicaDeath.png"))
		"FREDDY": $CameraNode/Camera2D/GameOverScreen.set_texture(load("res://Textures/Outcomes/FreddyDeath.png"))
		"FOXY": $CameraNode/Camera2D/GameOverScreen.set_texture(load("res://Textures/Outcomes/FoxyDeath.png"))
	#delay
	await get_tree().create_timer(10).timeout
	#back to title
	get_tree().change_scene_to_file("res://TitleScreen.tscn")
#Affect the usage display in the corner
func power_display(change):
	power_usage += change
	power_meter_list[0].set_visible(power_usage >= 1) #Not a great solution but not the worst
	power_meter_list[1].set_visible(power_usage >= 2)
	power_meter_list[2].set_visible(power_usage >= 3)
	power_meter_list[3].set_visible(power_usage >= 4)
	
#Bonnie has 'killed' the player but jumpscare has not fired yet
func bonnieKill():
	leftControlsEnabled = false
	gotKilled = "BONNIE"
	#maybe use moan sound

func chicaKill():
	rightControlsEnabled = false
	gotKilled = "CHICA"
	#maybe use moan sound

func freddyKill():
	#play animation
	camera_flip()
	#await get_tree().create_timer(3).timeout #Pause before jump?
	camDoNotOpen = true #Stop controls
	$CameraNode.camDoNotMove = true
	$CameraNode/Camera2D/JumpscareLayer.set_texture(load("res://Textures/JumpscareAnims/FreddyJump.png"))
	$CameraNode/Camera2D/JumpscareLayer/AudioStreamPlayer2D.play()
	gotKilled = "FREDDY"
	await get_tree().create_timer(3).timeout
	lose_game() #wait for finish
	
func _on_game_tick_timeout() -> void:
	tick() #redundant

#Wait for animation, then start the game
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Fadeout":
		game_start() #This begins the game after the intro plays (not in dev mode)

#honk honk
func _on_fred_nose_button_down() -> void:
	$GameScreen_Base/FredNose/Honk.play()

func _on_left_door_toggled(toggled_on: bool) -> void:
	if not leftControlsEnabled:
		$GameScreen_Base/RightControls/RightDoor/AudioStreamPlayer2D.set_stream("res://SFX/no.wav")
		$GameScreen_Base/RightControls/RightDoor/AudioStreamPlayer2D.play()
		pass
	if toggled_on: 
		power_display(1)
		$GameScreen_Base/LeftDoor/AnimationPlayer.play("LeftDoorClose")
	else : 
		power_display(-1)
		$GameScreen_Base/LeftDoor/AnimationPlayer.play("LeftDoorOpen")
	leftDoorOpen = !toggled_on
	$GameScreen_Base/LeftControls/LeftDoor/AudioStreamPlayer2D.play()

func _on_left_light_toggled(toggled_on: bool) -> void:
	if toggled_on: 
		power_display(1)
		$LeftHallTexture.set_modulate(Color(1, 1, 1))
	else : 
		power_display(-1)
		$LeftHallTexture.set_modulate(Color(0.018, 0.018, 0.018))
	$GameScreen_Base/LeftControls/LeftLight/AudioStreamPlayer2D.play()

func _on_right_door_toggled(toggled_on: bool) -> void:
	if not rightControlsEnabled:
		$GameScreen_Base/RightControls/RightDoor/AudioStreamPlayer2D.set_stream("res://SFX/no.wav")
		$GameScreen_Base/RightControls/RightDoor/AudioStreamPlayer2D.play()
		pass
	if toggled_on: 
		power_display(1)
		$GameScreen_Base/RightDoor/AnimationPlayer.play("RightDoorClose")
	else : 
		power_display(-1)
		$GameScreen_Base/RightDoor/AnimationPlayer.play("RightDoorOpen")
	rightDoorOpen = !toggled_on
	$GameScreen_Base/RightControls/RightDoor/AudioStreamPlayer2D.play()

func _on_right_light_toggled(toggled_on: bool) -> void:
	if toggled_on: 
		power_display(1)
		$RightHallTexture.set_modulate(Color(1, 1, 1))
		#Spook noise
	else : 
		power_display(-1)
		$RightHallTexture.set_modulate(Color(0.018, 0.018, 0.018))
	$GameScreen_Base/RightControls/RightLight/AudioStreamPlayer2D.play()

#Open the camera system
func _on_cam_access_mouse_entered() -> void:
	camera_flip()
	#JUMPSCARE STUFF on cam down -> set function
	if not camera_open:
		match gotKilled:
			"BONNIE":
				#play animation
				camDoNotOpen = true #Stop controls
				$CameraNode.camDoNotMove = true
				$CameraNode/Camera2D/JumpscareLayer.set_texture(load("res://Textures/JumpscareAnims/bonniejump/bonniejump0002.png"))
				$CameraNode/Camera2D/JumpscareLayer/AudioStreamPlayer2D.play()
				await get_tree().create_timer(3).timeout
				lose_game() #wait for finish
			"CHICA":
				#play animation
				camDoNotOpen = true #Stop controls
				$CameraNode.camDoNotMove = true
				$CameraNode/Camera2D/JumpscareLayer.set_texture(load("res://Textures/JumpscareAnims/ChicaJump.png"))
				$CameraNode/Camera2D/JumpscareLayer/AudioStreamPlayer2D.play()
				await get_tree().create_timer(3).timeout
				lose_game() #wait for finish
			_:
				pass

#Development function
func _input(event):
	if event.is_action_pressed("DevCheat"):
	#if event is InputEventKey and event.keycode == KEY_L:
		#print("Cheat: End game")
		#lose_game()
		#print("Cheat: Move Bonnie to office")
		#$AnimatronicAIController.BonniePos = "Office"
		#print("Cheat: Chica to Kitchen")
		#$AnimatronicAIController.move_chica("6")
		#print("Cheat: Freddy to 4B")
		#$AnimatronicAIController.move_freddy("4B")
		$AnimatronicAIController.foxy_angy = 4000
		print("Made Foxy angy")

func camera_flip():
	#prevent cam during death
	if camDoNotOpen:
		return
	#play animation, open camera panel
	if camera_open:
		$CameraNode/Camera2D.make_current() #room view
		power_display(-1)
	else:
		$ScreenCameraNode/CameraScreenDisplay/ScreenCamera.make_current() #camera view
		power_display(1)
	camera_open = !camera_open
	$ScreenCameraNode/CameraScreenDisplay.set_visible(camera_open)
	$ScreenCameraNode/CameraScreenDisplay.update_cam()

func _on_foxy_kill_you_timer_timeout() -> void:
	if not leftDoorOpen: #Attack prevented
		print("Attack Fail Door Closed")
		#Add sfx
	else: #You die
		if camera_open:
			camera_flip()
		camDoNotOpen = true
		#foxyKill
		$CameraNode.camDoNotMove = true
		$CameraNode.moveCameraLeft()
		$CameraNode/Camera2D/JumpscareLayer/FoxyEnterOffice.play("FoxyEnterOffice")
		$CameraNode/Camera2D/JumpscareLayer/AudioStreamPlayer2D.play()
		gotKilled = "FOXY"
		await get_tree().create_timer(3).timeout
		lose_game() #wait for finish
