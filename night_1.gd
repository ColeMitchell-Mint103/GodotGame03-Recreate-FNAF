extends ColorRect

var hourLength = 120.0 #seconds
var current_time = 0
var hour = 0.0 #stupid fucking AM
var power = 100.0 #float for fun
var power_usage = 1 #clamp between 1 and 4?
var power_factor = 0.08 #power drain modifier
var golden_freddy = false
var power_dead = false
var his_power_factor = 0.25 #not ready for freddy 
var night = 1
var camera_open = false
var dev_mode = false #turn off
var animatronic_aggression = [5, 5, 5, 5] #Bonnie, Chica, Freddy, Foxy
var leftDoorOpen = true
var rightDoorOpen = true
var phoneActive = false

var gotKilled = "NO"
var leftControlsEnabled = true
var rightControlsEnabled = true
var camDoNotOpen = false
@onready var power_meter_list = [$CameraNode/Camera2D/HUD/Time_PowerInfo/Meter/Low,
 $CameraNode/Camera2D/HUD/Time_PowerInfo/Meter/Medium,
 $CameraNode/Camera2D/HUD/Time_PowerInfo/Meter/High,
 $CameraNode/Camera2D/HUD/Time_PowerInfo/Meter/Veryhigh,
 $CameraNode/Camera2D/HUD/Time_PowerInfo/Meter/StupidHigh]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not dev_mode: #dev mode skips intro
		$CameraNode.set_visible(false)
		$GameScreen_Base.set_visible(false)
		$CameraNode/Camera2D/HUD.set_visible(false)
		$AnimationPlayer.play("Fadeout")
		$LeftHallTexture/BonnieOffice/Spook.play() #Reuse boom sound
	else: game_start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

var AI_ramp = 0 #Holder for increasing AI aggression as night progresses
#core game loop
func tick():
	current_time += 1.0
	hour = floor(current_time / hourLength)
	#Clock handling: USE FLOATS
	var minute = floor((current_time - (hour * hourLength)) * (60.0 / hourLength))#Converting hourlength "minute" into 60 scale
	minute = str(minute) if minute > 9 else "0" + str(minute)
	$GameScreen_Base/ClockText.set_text("0" + str(hour) + ":" + minute)
	
	power -= power_usage * power_factor
	$GameScreen_Base/BatteryIndicator.set_scale(Vector2($GameScreen_Base/BatteryIndicator.get_scale().x,(-1.36 * power / 100.0)))
	if power <= 0 and not power_dead:
		power_dead = true
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
	golden_action()
	
	#AI ramping for single night
	if AI_ramp == 0 and hour >= 1:
		$AnimatronicAIController.updateAI([10,10,10,10])
		AI_ramp = 1
	elif AI_ramp == 1 and hour >= 3:
		$AnimatronicAIController.updateAI([15,15,15,15])
		AI_ramp = 2
	elif AI_ramp == 2 and hour >= 5:
		$AnimatronicAIController.updateAI([20,20,20,20])
		AI_ramp = 3

func game_start():
	$GameTick.start()
	$GameScreen_Base.set_visible(true)
	$CameraNode.set_visible(true)
	$CameraNode/Camera2D/HUD.set_visible(true)
	$CameraNode.camDoNotMove = false
	$AnimatronicAIController.initialize(animatronic_aggression)
	$FanAmbient.begin(his_power_factor)
	
#Player has run out of power. Game ends soon. Should the kill time be variable?
func powerout():
	#Disable animatronic AI? Can Foxy rush over Freddy?
	$CameraNode/Camera2D/HUD/Time_PowerInfo.set_visible(false)
	$AnimatronicAIController.allHalt = true #Stop AI
	$FanAmbient.stop()
	$GameScreen_Base/Fan.stop()
	$GameScreen_Base/ClockText.set_visible(false)
	$AnimatronicAIController.allHalt = true
	leftControlsEnabled = false
	rightControlsEnabled = false
	#Make dark, disable controls, open doors, Freddy jingle, jumpscare
	if camera_open: 
		camera_flip()
	camDoNotOpen = true
	$GameScreen_Base.set_modulate(Color(0.2,0.2,0.2))
	$GameScreen_Base/PowerOutPlayer.play()
	if not leftDoorOpen:
		_on_left_door_toggled(false)
	if not rightDoorOpen:
		_on_right_door_toggled(false)
	if $LeftHallTexture.get_modulate().is_equal_approx(Color(1, 1, 1)): #Rough way to check if light is on
		_on_left_light_toggled(false)
	if $RightHallTexture.get_modulate().is_equal_approx(Color(1, 1, 1)):
		_on_right_light_toggled(false)
	leftControlsEnabled = false
	rightControlsEnabled = false
	var freddyTimer = randf_range(50, 65) * 2 / $AnimatronicAIController.FreddyAI
	await get_tree().create_timer(freddyTimer).timeout #waiting for freddy timer
	#Freddy animation -> screen black -> jump -> dead
	$FreddyStare.set_visible(true)
	$FreddyStare/FreddyStare_Anim.play("FreddySing")
	#$FreddyStare/FreddyStare_SongTimer.start(randf_range(0.8, 1.5)) #Config song time for balance later
	await get_tree().create_timer(randf_range(3, 12)).timeout #singing timer
	$FreddyStare/FreddyStare_Anim.play("RESET")
	$FreddyStare.set_visible(false)
	await get_tree().create_timer(randf_range(10, 20)).timeout #dark pause timer
	$CameraNode/Camera2D/JumpscareLayer/FoxyEnterOffice.set_animation("FreddyPowerOutAttack")
	$CameraNode/Camera2D/JumpscareLayer/FoxyEnterOffice.play()
	$CameraNode/Camera2D/JumpscareLayer/AudioStreamPlayer2D.play()
	await get_tree().create_timer(1.0).timeout
	gotKilled = "NOPOWER"
	lose_game()
	

# Stop AI, roll clock, play fanfare, load next night
func win_game():
	#Stop all the controls, lock the cam and play the overlay
	$GameTick.stop()
	$FanAmbient.stop()
	AudioServer.set_bus_solo(AudioServer.get_bus_index("Master"), true)
	$CameraNode/Camera2D.set_position(Vector2(0,0))
	$CameraNode/Camera2D/HUD.set_visible(false)
	$CameraNode/Camera2D/JumpscareLayer.set_visible(false)
	$VictoryOverlay.set_visible(true)
	$CameraNode/Camera2D.set_zoom(Vector2(1,1))
	$CameraNode.camDoNotMove = true
	$VictoryOverlay/VictorySFX.play()
	#Stop freddy sing song if you win
	if $FreddyStare.is_visible():
		$FreddyStare.set_visible(false)
		$FreddyStare/FreddyStare_Anim.stop()
	#delay
	await get_tree().create_timer(10).timeout
	#load next night
	get_tree().change_scene_to_file("res://TitleScreen.tscn")

#End game logic
func lose_game():
	$GameScreen_Base/PlayerWarnDeath/PlayerWarnTimer.stop()
	$GameScreen_Base/PlayerWarnDeath.stop()
	$GameTick.stop()
	$CameraNode/Camera2D.set_position(Vector2(0,0))
	$CameraNode/Camera2D/HUD.set_visible(false)
	$CameraNode/Camera2D/JumpscareLayer.set_visible(false)
	#creep screen
	match gotKilled:
		"BONNIE": $CameraNode/Camera2D/GameOverScreen.set_texture(load("res://Textures/Outcomes/BonnieDeath.png"))
		"CHICA": $CameraNode/Camera2D/GameOverScreen.set_texture(load("res://Textures/Outcomes/ChicaDeath.png"))
		"FREDDY": $CameraNode/Camera2D/GameOverScreen.set_texture(load("res://Textures/Outcomes/FreddyDeath.png"))
		"FOXY": $CameraNode/Camera2D/GameOverScreen.set_texture(load("res://Textures/Outcomes/FoxyDeath.png"))
		"NOPOWER": $CameraNode/Camera2D/GameOverScreen.set_texture(load("res://Textures/Outcomes/PowerOutDeath.png"))
	#delay
	await get_tree().create_timer(10).timeout
	#back to title
	get_tree().change_scene_to_file("res://TitleScreen.tscn")

var power_textures = ["res://Textures/RoomFiles/Office/PowerMeter/Power_Low.png",
"res://Textures/RoomFiles/Office/PowerMeter/Power_Moderate.png",
"res://Textures/RoomFiles/Office/PowerMeter/Power_High.png",
"res://Textures/RoomFiles/Office/PowerMeter/Power_VeryHigh.png",
"res://Textures/RoomFiles/Office/PowerMeter/Power_StupidHigh.png"]

#Affect the usage display in the corner
func power_display(change):
	power_usage += change
	power_meter_list[0].set_visible(power_usage >= 1) #Not a great solution but not the worst
	power_meter_list[1].set_visible(power_usage >= 2)
	power_meter_list[2].set_visible(power_usage >= 3)
	power_meter_list[3].set_visible(power_usage >= 4)
	power_meter_list[4].set_visible(power_usage >= 5)
	$GameScreen_Base/PowerMeter.set_texture(load(power_textures[power_usage-1]))
	
	
#Bonnie has 'killed' the player but jumpscare has not fired yet
func bonnieKill():
	if $GameScreen_Base/LeftControls/LeftLight.is_pressed():
		$GameScreen_Base/LeftControls/LeftLight.set_pressed(false)
	leftControlsEnabled = false
	gotKilled = "BONNIE"
	$GameScreen_Base/PlayerWarnDeath/PlayerWarnTimer.start()

func chicaKill():
	if $GameScreen_Base/RightControls/RightLight.is_pressed():
		$GameScreen_Base/RightControls/RightLight.set_pressed(false)
	rightControlsEnabled = false
	gotKilled = "CHICA"
	$GameScreen_Base/PlayerWarnDeath/PlayerWarnTimer.start()

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

var texture_DoorOn = load("res://Textures/RoomFiles/Office/Button_Door_On.png")
var texture_DoorOff = load("res://Textures/RoomFiles/Office/Button_Door_Off.png")
var texture_LightOn = load("res://Textures/RoomFiles/Office/Button_Light_On.png")
var texture_LightOff = load("res://Textures/RoomFiles/Office/Button_Light_Off.png")
func _on_left_door_toggled(toggled_on: bool) -> void:
	if not leftControlsEnabled:
		$GameScreen_Base/LeftControls/LeftDoor/AudioStreamPlayer2D.set_stream(load("res://SFX/no.wav"))
		$GameScreen_Base/LeftControls/LeftDoor/AudioStreamPlayer2D.play()
		return
	if toggled_on: 
		power_display(1)
		$GameScreen_Base/LeftDoor.play("LeftDoorClose")
		$GameScreen_Base/LeftDoor/LeftDoorAudio.set_stream(load("res://SFX/DoorClose.wav"))
		$GameScreen_Base/LeftDoor/LeftDoorAudio.play()
		$GameScreen_Base/LeftControls/LeftDoor.set_button_icon(texture_DoorOn)
	else : 
		power_display(-1)
		$GameScreen_Base/LeftDoor.play("LeftDoorOpen")
		$GameScreen_Base/LeftDoor/LeftDoorAudio.set_stream(load("res://SFX/DoorOpen.wav"))
		$GameScreen_Base/LeftDoor/LeftDoorAudio.play()
		$GameScreen_Base/LeftControls/LeftDoor.set_button_icon(texture_DoorOff)
	leftDoorOpen = !toggled_on
	$GameScreen_Base/LeftControls/LeftDoor/AudioStreamPlayer2D.play()

func _on_left_light_toggled(toggled_on: bool) -> void:
	if not leftControlsEnabled:
		$GameScreen_Base/LeftControls/LeftDoor/AudioStreamPlayer2D.set_stream(load("res://SFX/no.wav"))
		$GameScreen_Base/LeftControls/LeftDoor/AudioStreamPlayer2D.play()
		return
	if toggled_on: 
		power_display(1)
		$GameScreen_Base/RightControls/RightLight.set_pressed(false)
		$LeftHallTexture.set_modulate(Color(1, 1, 1))
		$GameScreen_Base/LeftControls/LeftLight.set_button_icon(texture_LightOn)
		if $LeftHallTexture/BonnieOffice.is_visible():
			$LeftHallTexture/BonnieOffice/Spook.play()
	else : 
		power_display(-1)
		$LeftHallTexture.set_modulate(Color(0.005, 0.005, 0.005))
		$GameScreen_Base/LeftControls/LeftLight.set_button_icon(texture_LightOff)
	$GameScreen_Base/LeftControls/LeftLight/AudioStreamPlayer2D.play()

func _on_right_door_toggled(toggled_on: bool) -> void:
	if not rightControlsEnabled:
		$GameScreen_Base/RightControls/RightDoor/AudioStreamPlayer2D.set_stream(load("res://SFX/no.wav"))
		$GameScreen_Base/RightControls/RightDoor/AudioStreamPlayer2D.play()
		return
	if toggled_on: 
		power_display(1)
		$GameScreen_Base/RightDoor.play("RightDoorClose")
		$GameScreen_Base/RightDoor/RightDoorAudio.set_stream(load("res://SFX/DoorClose.wav"))
		$GameScreen_Base/RightDoor/RightDoorAudio.play()
		$GameScreen_Base/RightControls/RightDoor.set_button_icon(texture_DoorOn)
	else : 
		power_display(-1)
		$GameScreen_Base/RightDoor.play("RightDoorOpen")
		$GameScreen_Base/RightDoor/RightDoorAudio.set_stream(load("res://SFX/DoorOpen.wav"))
		$GameScreen_Base/RightDoor/RightDoorAudio.play()
		$GameScreen_Base/RightControls/RightDoor.set_button_icon(texture_DoorOff)
	rightDoorOpen = !toggled_on
	$GameScreen_Base/RightControls/RightDoor/AudioStreamPlayer2D.play()

func _on_right_light_toggled(toggled_on: bool) -> void:
	if not rightControlsEnabled:
		$GameScreen_Base/RightControls/RightDoor/AudioStreamPlayer2D.set_stream(load("res://SFX/no.wav"))
		$GameScreen_Base/RightControls/RightDoor/AudioStreamPlayer2D.play()
		return
	if toggled_on: 
		$GameScreen_Base/LeftControls/LeftLight.set_pressed(false)
		power_display(1)
		$RightHallTexture.set_modulate(Color(1, 1, 1))
		$GameScreen_Base/RightControls/RightLight.set_button_icon(texture_LightOn)
		if $RightHallTexture/ChicaOffice.is_visible():
			$RightHallTexture/ChicaOffice/Spook2.play()
	else : 
		power_display(-1)
		$RightHallTexture.set_modulate(Color(0.005, 0.005, 0.005))
		$GameScreen_Base/RightControls/RightLight.set_button_icon(texture_LightOff)
	$GameScreen_Base/RightControls/RightLight/AudioStreamPlayer2D.play()

#Open the camera system
func _on_cam_access_mouse_entered() -> void:
	if camDoNotOpen: return
	$CameraNode/Camera2D/HUD/ReferenceRect/CamAccess.set_visible(false)
	camera_flip()

#Development function
func _input(event):
	if event.is_action_pressed("DevCheat"):
		pass
	#if event is InputEventKey and event.keycode == KEY_L:
		#print("Cheat: End game")
		#lose_game()
		#print("Cheat: Move Bonnie to office")
		#$AnimatronicAIController.move_bonnie("Office")
		#print("Cheat: Moved Chica")
		#$AnimatronicAIController.move_chica("Office")
		#print("Cheat: Freddy to 4B")
		#$AnimatronicAIController.move_freddy("4B")
		#$AnimatronicAIController.foxy_angy = 4000
		#print("Made Foxy angy")
		#power = 1.00
		#print("Low power")
		#current_time = 6*hourLength
		#print("Win night")
		#print('Force gold')
		#$AnimatronicAIController/HimTimer.start(0.2)

func camera_jumpscare(Character):
	match Character:
		"NO":
			return
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

func camera_flip():
	#prevent cam during death
	if camDoNotOpen:
		return
	if camera_open: #Closing the cam
		$ScreenCameraNode/ReferenceRect/Monitor.play("Reverse")
		$CameraNode/Camera2D/CameraSounds_DARK.set_stream(load("res://SFX/dark2.mp3"))
		$CameraNode/Camera2D/CameraSounds_DARK.play()
		$CameraNode/Camera2D.make_current() #room view
		power_display(-1)
		if golden_freddy:
			if $Fredbear.is_visible():
				$Fredbear/HimTimer.start(3)
			golden_freddy = false
			$ScreenCameraNode/CameraScreenDisplay.room_textures["2B"] = "res://Textures/RoomFiles/WestHallCorner_Base.png"
		camera_jumpscare(gotKilled)
	
	else: #Opening the cam
		$GameScreen_Base/LeftControls/LeftLight.set_pressed(false) #Light turns off if cam opened.
		$GameScreen_Base/RightControls/RightLight.set_pressed(false)
		camDoNotOpen = true
		$ScreenCameraNode/ReferenceRect/Monitor.play("default")
		$CameraNode/Camera2D/CameraSounds_DARK.set_stream(load("res://SFX/dark.mp3"))
		$CameraNode/Camera2D/CameraSounds_DARK.play()
		var camera_open_speed = $ScreenCameraNode/ReferenceRect/Monitor.get_sprite_frames().get_animation_speed("default")
		var camera_open_frames = $ScreenCameraNode/ReferenceRect/Monitor.get_sprite_frames().get_frame_count("default")
		await get_tree().create_timer(camera_open_frames / camera_open_speed).timeout
		$ScreenCameraNode/CameraScreenDisplay/ScreenCamera.make_current() #camera view
		power_display(1)
		$AnimatronicAIController.foxy_angy = max($AnimatronicAIController.foxy_angy - 2, -10)#Cut anger on flipping cam to account for the timer being slow
		#GoldFredbear westhall attack
		if randi_range(1,100) == 1: #Begin attack
			golden_freddy = true
			$ScreenCameraNode/CameraScreenDisplay.room_textures["2B"] = "res://Textures/79/WestHall_Golden.png"
		if $Fredbear.is_visible(): #Survive attack
			$Fredbear/HimTimer.stop()
			$Fredbear.set_visible(false)
	
	#Constant action
	camera_open = !camera_open
	$ScreenCameraNode/CameraScreenDisplay.set_visible(camera_open)
	$ScreenCameraNode/CameraScreenDisplay.update_cam()
	if not camera_open:
		$ScreenCameraNode/CameraScreenDisplay.cam_close()
	camDoNotOpen = false

func _on_foxy_kill_you_timer_timeout() -> void:
	if not leftDoorOpen: #Attack prevented
		#print("Attack Fail Door Closed")
		#Stop the anim overlay
		$ScreenCameraNode/CameraScreenDisplay/FoxyLayer/FoxyCharge.set_visible(false)
		$ScreenCameraNode/CameraScreenDisplay/FoxyLayer/FoxyCharge.pause()
		#Hit the door sfx
		$GameScreen_Base/LeftDoor/FoxyDoorHit.play()
		#Reset Foxy
		$AnimatronicAIController.FoxyAttack = false
		$AnimatronicAIController.FoxyStage = 0
		$ScreenCameraNode/CameraScreenDisplay.updateFoxy(0)
		if camera_open: camera_flip()
		power -= 3.0 #he drains power with Foxy magic
		$"FanAmbient/Foxy Audio/FoxyAmbientTimer".start()
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

func _on_reference_rect_mouse_exited() -> void:
	$CameraNode/Camera2D/HUD/ReferenceRect/CamAccess.set_visible(true)

#Foxy random mumbling.
func _on_foxy_ambient_timeout() -> void:
	$"FanAmbient/Foxy Audio/FoxyAmbient".play()

func _on_foxy_ambient_finished() -> void:
	$"FanAmbient/Foxy Audio/FoxyAmbientTimer".start(randi_range(25, 1000 / $AnimatronicAIController.FoxyAI))


var halu_sounds = ["res://SFX/79/Spook1.mp3", "res://SFX/79/Spook2.mp3",
"res://SFX/79/Spook3.mp3", "res://SFX/79/Spook4.mp3"]
var halu_frames = ["res://Textures/79/Hallucinations/Halluci1.png","res://Textures/79/Hallucinations/Halluci2.png",
"res://Textures/79/Hallucinations/Halluci3.png","res://Textures/79/Hallucinations/Halluci4.png",
"res://Textures/79/Hallucinations/Halluci5.png","res://Textures/79/Hallucinations/Halluci6.png",
"res://Textures/79/Hallucinations/Halluci7.png","res://Textures/79/Hallucinations/Halluci8.png",
"res://Textures/79/Hallucinations/Halluci9.png","res://Textures/79/Hallucinations/Halluci10.png",
"res://Textures/79/Hallucinations/HalluciB1.png","res://Textures/79/Hallucinations/HalluciB2.png",
"res://Textures/79/Hallucinations/HalluciB3.png","res://Textures/79/Hallucinations/HalluciB4.png",
"res://Textures/79/Hallucinations/HalluciF1.png","res://Textures/79/Hallucinations/HalluciF2.png",
"res://Textures/79/Hallucinations/HalluciF3.png"
]
var dining_altered = false
#Spooky, rare activities per 1 second game tick
func golden_action():
	if randi_range(1, 200) == 1 and not camera_open: #Hallucinate only works in Office
		var anim_flash = $CameraNode/Camera2D/HallucinationLayer.get_sprite_frames()
		anim_flash.clear("Flash")
		for frame in range(randi_range(3,6)):
			anim_flash.add_frame("Flash", load(""))
			anim_flash.add_frame("Flash", load(halu_frames.pick_random()))
		anim_flash.add_frame("Flash", load(""))
		$CameraNode/Camera2D/HallucinationLayer.play("Flash")
		$CameraNode/Camera2D/HallucinationLayer/SpookAudio.set_stream(load(halu_sounds.pick_random()))
		$CameraNode/Camera2D/HallucinationLayer/SpookAudio.play()
	
	if not dining_altered and randi_range(1, 400) == 1: #Changing dining hall
		if randi_range(1,2) == 1:
			$ScreenCameraNode/CameraScreenDisplay.room_textures["1B"] = "res://Textures/79/DiningRoom_Base_milkspilled.png"
			#audio glass breaking
			$FanAmbient/GoldAudio.set_stream(load("res://SFX/79/Glass_dig2.ogg"))
			$FanAmbient/GoldAudio.play()
		else:
			$ScreenCameraNode/CameraScreenDisplay.room_textures["1B"] = "res://Textures/79/DiningRoom_Base_cakeeated.png"
			#cake eat audio
			$FanAmbient/GoldAudio.set_stream(load("res://SFX/79/Eat1.ogg"))
			$FanAmbient/GoldAudio.play()
		dining_altered = true

func _on_him_timer_timeout() -> void:
	camDoNotOpen = true
	$ScreenCameraNode/CameraScreenDisplay.set_visible(false)
	$CameraNode.camDoNotMove = true
	gotKilled = "GOLDY"
	$GameTick.stop()
	$CameraNode/Camera2D.set_position(Vector2(0,0))
	$CameraNode/Camera2D/HUD.set_visible(false)
	$CameraNode/Camera2D/JumpscareLayer.set_visible(false)
	$CameraNode/Camera2D/GameOverScreen.set_texture(load("res://Textures/Outcomes/golddeath.png"))
	$Fredbear/FredbearKill.play()
	await get_tree().create_timer(3).timeout
	get_tree().quit() #Game crashes
	

#Phone Call Handling:
func _on_phone_incoming_timer_timeout() -> void:
	$GameScreen_Base/Phone/PhoneRing.play()
	$GameScreen_Base/Phone.play()
	$GameScreen_Base/Phone/PhoneButton.set_disabled(false)

func _on_phone_button_pressed() -> void:
	if not phoneActive:
		phoneActive = true
		$GameScreen_Base/Phone/ActivePhone.set_visible(true)
		$CameraNode/Camera2D/PhoneOverlay.set_visible(true)
		$GameScreen_Base/Phone.stop()
		$GameScreen_Base/Phone/PhoneCall.play()
		$GameScreen_Base/Phone/PhoneRing.stop()
	else:
		phoneActive = false
		$GameScreen_Base/Phone/ActivePhone.set_visible(false)
		$CameraNode/Camera2D/PhoneOverlay.set_visible(false)
		$GameScreen_Base/Phone/PhoneOff.play()
		$GameScreen_Base/Phone/PhoneCall.stop()
		$GameScreen_Base/Phone/PhoneButton.set_disabled(true)

#Moans if the player is hiding in the camera
func _on_player_warn_timer_timeout() -> void:
	if camera_open and randi_range(1, 3) == 1:
		$GameScreen_Base/PlayerWarnDeath.play()
