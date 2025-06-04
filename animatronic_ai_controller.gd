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

signal did_move(room)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#Pass initial parameters
func initialize(AIValues):
	BonnieAI = AIValues[0]
	ChicaAI = AIValues[1]
	FreddyAI = AIValues[2]
	FoxyAI = AIValues[3]

#Core loop
func tick():
	if $BonnieTimer.is_stopped(): #First pause is 30s currently, set via node
		if randi_range(0, 20) <= BonnieAI:
			move_bonnie()
			$BonnieTimer.start(randf_range(150, 400) / BonnieAI) #Cooldown shortens with AI level
	if randi_range(0, 20) <= ChicaAI:
		move_chica()
	if randi_range(0, 20) <= FreddyAI:
		move_freddy()
	if randi_range(0, 20) <= FoxyAI:
		move_foxy()
	bonnie_angy += 1

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


func move_bonnie():
	if BonniePos == "Office":
		#if door closed, leave
		if $"..".leftDoorOpen:
			$"..".bonnieKill()
			print("Killed byBonnie")
			#Kill mode 1. wait for camera drop 2. force jumpscare if cam down?
		else:
			BonniePos = '1B'
	elif randi_range(0, 1000) <= bonnie_angy: #Roll for aggression
		did_move.emit(BonniePos)
		BonniePos = bonnie_movement_AGGRESS[BonniePos]
	else: #Wander move
		did_move.emit(BonniePos)
		BonniePos = bonnie_movement_WANDER[BonniePos].pick_random()
	if BonniePos == "Office": #Satisfied by reaching Office
		bonnie_angy = 0
		$"../LeftHallTexture/BonnieOffice".set_visible(true)
	#Play audio sound
	print("Bonnie: " + BonniePos)

func move_chica():
	pass
	
func move_freddy():
	pass

func move_foxy():
	pass
