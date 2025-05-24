extends Node
#Numerical Aggression index for custom night
var FreddyAI = 0
var BonnieAI = 0
var ChicaAI = 0
var FoxyAI = 0

#Locations
var FreddyPos = "ShowStage"
var BonniePos = "Showstage"
var ChicaPos = "Showstage"
var FoxyStage = 0

#Variable to drive AI to the Office over time so it doesn't wander forever
var bonnie_angy = 0 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#Pass initial parameters
func initialize(AIValues):
	FreddyAI = AIValues[0]
	BonnieAI = AIValues[1]
	ChicaAI = AIValues[2]
	FoxyAI = AIValues[3]

#Core loop
func tick():
	if randi_range(0, 20) <= BonnieAI:
		move_bonnie()
	if randi_range(0, 20) <= ChicaAI:
		move_chica()
	if randi_range(0, 20) <= FreddyAI:
		move_freddy()
	if randi_range(0, 20) <= FoxyAI:
		move_foxy()
	bonnie_angy += 1


var bonnie_movement_WANDER = {"Showstage" : ["Dining"],
"Dining" : ["Backstage", "WestHall"],
"Backstage" : ["Dining"],
"WestHall" : ["Dining", "Office", "WestHallCorner"],
"WestHallCorner" : ["Office"]
}
var bonnie_movement_AGGRESS = {"Showstage" : "Dining",
"Dining" : "WestHall",
"Backstage" : "Dining",
"WestHall" : "WestHallCorner",
"WestHallCorner" : "Office"
}


func move_bonnie():
	if BonniePos == "Office":
		pass #kill player
	elif randi_range(0, 1000) <= bonnie_angy: #Roll for aggression
		BonniePos = bonnie_movement_AGGRESS[BonniePos]
	else: #Wander move
		BonniePos = bonnie_movement_WANDER[BonniePos].pick_random()
	if BonniePos == "Office": #Satisfied by reaching Office
		bonnie_angy = 0
	#Play audio sound

func move_chica():
	pass
	
func move_freddy():
	pass

func move_foxy():
	pass
