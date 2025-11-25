extends Node
#Numerical Aggression index for custom night
var BonnieAI = 0
var ChicaAI = 0
var FreddyAI = 0
var FoxyAI = 0

#Locations
var FreddyPos = "1A"
var BonniePos = "1A"
var ChicaPos = "1A"
var FoxyStage = 0

#Variable to drive AI to the Office over time so it doesn't wander forever
var bonnie_angy = 0 
var chica_angy = 0
var freddy_angy = 0
var foxy_angy = 0
var FoxyAttack = false

signal did_move(room)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#Pass initial parameters in NightX script
func initialize(AIValues):
	BonnieAI = AIValues[0]
	ChicaAI = AIValues[1]
	FreddyAI = AIValues[2]
	FoxyAI = AIValues[3]
	$BonnieTimer.start(30 / BonnieAI + 5)
	$ChicaTimer.start(30 / ChicaAI + 5)

#Core loop
#Pauses / Timers are cooldowns to prevent rapid lucky movement.
func tick():
	if $BonnieTimer.is_stopped(): #First pause is 30s currently, set via node
		if randi_range(0, 20) <= BonnieAI:
			move_bonnie()
			$BonnieTimer.start(randf_range(150, 400) / BonnieAI) #Cooldown shortens with AI level
	if $ChicaTimer.is_stopped():
		if randi_range(0, 20) <= ChicaAI:
			move_chica()
			$ChicaTimer.start(randf_range(150, 600) / ChicaAI) #Chica slower than bon bon
	bonnie_angy += 1
	chica_angy += 1
	# Freddy gains angy when not looked at, lowers when viewed. If angy too high, he move.
	if $"../ScreenCameraNode/CameraScreenDisplay".isFreddyOnCam():
		freddy_angy -= 1
	else:
		freddy_angy += 1
	if freddy_angy >= 2000 / FreddyAI:
		move_freddy()
		print("Freddy: " + FreddyPos)
		freddy_angy = 0
	# Foxy gains angy when the cameras are OFF. He attacks if the monitor is down.
	if not FoxyAttack:
		if $"../ScreenCameraNode/CameraScreenDisplay".camera_open:
			foxy_angy += 1
		else:
			foxy_angy -= 1
		if foxy_angy >= 5000 / FoxyAI:
			move_foxy()
			foxy_angy = 0
			print("Foxy Stage: " + str(FoxyStage))
	

func give_Locations():
	return [BonniePos, ChicaPos, FreddyPos, FoxyStage]

var bonnie_movement_WANDER = {"1A" : ["1B"],
"1B" : ["5", "2A"],
"5" : ["1B"],
"2A" : ["1B", "Office", "2B"],
"2B" : ["Office"]
}
var bonnie_movement_AGGRESS = {"1A" : "1B",
"1B" : "2A",
"5" : "1B",
"2A" : "2B",
"2B" : "Office"
}

#Moves Bonnie animatromo to new room.
func move_bonnie():
	if BonniePos == "Office":
		if $"..".leftDoorOpen:
			$"..".bonnieKill()
			print("Killed byBonnie")
			#Kill mode 1. wait for camera drop 2. force jumpscare if cam down?
		else:
			#if door closed, leave
			BonniePos = '1B'
			$"../LeftHallTexture/BonnieOffice".set_visible(false)
	elif randi_range(0, 1000) <= bonnie_angy: #Roll for aggression
		did_move.emit(BonniePos)
		BonniePos = bonnie_movement_AGGRESS[BonniePos]
	else: #Wander move
		did_move.emit(BonniePos)
		BonniePos = bonnie_movement_WANDER[BonniePos].pick_random()
	if BonniePos == "Office": #Satisfied by reaching Office
		bonnie_angy = 0
		$"../LeftHallTexture/BonnieOffice".set_visible(true)
	$"../FanAmbient/LEFT Footstep Audio".play() #Play audio sound
	print("Bonnie: " + BonniePos)

var chica_movement_WANDER = {"1A" : ["1B"],
"1B" : ["7", "4A", "6"],
"7" : ["1B"],
"6" : ["1B"], #Kitchen
"4A" : ["1B", "4B", "Office"],
"4B" : ["Office"]
}
var chica_movement_AGGRESS = {"1A" : "1B",
"1B" : "4A",
"7" : "1B",
"6" : "1B", #Kitchen
"4A" : "Office",
"4B" : "Office"
}

#Moves Chica, the fat bird, to new room.
#Emits did_move -> camera_screen.gd
func move_chica(room = ""):
	if ChicaPos == "Office":
		if $"..".rightDoorOpen:
			$"..".chicaKill()
			print("Killed byChica")
			#Kill mode 1. wait for camera drop 2. force jumpscare if cam down?
		else:
			ChicaPos = '1B' #if door closed, leave
			$"../RightHallTexture/ChicaOffice".set_visible(false)
	
	if room != "": #Cheat purposes
		ChicaPos = room
	elif BonniePos == "1A":
		return #Cannot leave before Bonnie
	elif randi_range(0, 1000) <= chica_angy: #Roll for aggression
		did_move.emit(ChicaPos)
		ChicaPos = chica_movement_AGGRESS[ChicaPos]
	else: #Wander move
		did_move.emit(ChicaPos)
		ChicaPos = chica_movement_WANDER[ChicaPos].pick_random()
	
	if ChicaPos == "Office": #Satisfied by reaching Office
		chica_angy = 0
		$"../RightHallTexture/ChicaOffice".set_visible(true)
	#if ChicaPos == "6":
		#$"../CameraNode/Camera2D/KitchenLowBaseStream"._set_playing(true)
		#$"../CameraNode/Camera2D/KitchenLowBaseStream".set_volume_db(-20)
	$"../FanAmbient/RIGHT Footstep Audio".play()#Play audio sound
	print("Chica: " + ChicaPos)
	
	
	
var freddy_movement = {"1A":"1B",
	"1B":"7",
	"7":"6",
	"6":"4A",
	"4A":"4B",
	}
var FreddyLaughs =["res://SFX/Freddy/FreddyLaugh-01.wav","res://SFX/Freddy/FreddyLaugh-02.wav",
"res://SFX/Freddy/FreddyLaugh-03.wav", "res://SFX/Freddy/FreddyLaugh-04-2.wav"]
# Move Freddy to next room.
# Kitchen sounds -> camera_screen
func move_freddy(room = ""):
	if room != "": #Cheat purposes
		FreddyPos = room
	elif FreddyPos == "4B" and $"..".rightDoorOpen:
		if $"..".rightDoorOpen:
			$"..".freddyKill()
			print("Killed by Freddy")
		else:
			print("Freddy Blocked by Door")
	else:
		did_move.emit(FreddyPos)
		FreddyPos = freddy_movement[FreddyPos]
		$FreddyTimer/AudioStreamPlayer.set_stream(load(FreddyLaughs[randi_range(0, FreddyLaughs.size() - 1)])) #range is INCLUSIVE
		$FreddyTimer/AudioStreamPlayer.play() #Play FredLaugh
	
#Foxy moves through 4 stages, with the 4th stage being him running down west hall to kill your ass.
#At stage 4 he has a timer to attack the office given player inactivity or will run if the West Hall is looked at.?
func move_foxy():
	FoxyStage = min(4, FoxyStage + 1) #Capped
	if FoxyStage == 4:
		FoxyAttack = true
		print("Foxy attak")
		$FoxyKillYouTimer.start()
	$"../ScreenCameraNode/CameraScreenDisplay".updateFoxy(FoxyStage)
	did_move.emit("1C") #1C = Pirate's Cove
	
	
	
