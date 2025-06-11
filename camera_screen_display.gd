extends TextureRect

var layer_List = [$CharacterLayer1, $CharacterLayer2, $CharacterLayer3, $CharacterLayer4, $CharacterLayer5] #layer 1 = bonnie, layer 2 = chica
var current_camera = "1A"
var camera_open = false
var room_names = {"1A" : "Show Stage",
"1B" : "Dining Area",
"1C" : "Pirate's Cove",
"2A" : "West Hall",
"2B" : "West Hall Corner",
"3" : "Supply Closet",
"4A" : "East Hall",
"4B" : "East Hall Corner",
"5" : "Backstage",
"6" : "Kitchen",
"7" : "Bathrooms"
}
var room_textures = {"1A" : "res://Textures/RoomFiles/Showstage_Base.png",
"1B" : "res://Textures/RoomFiles/DiningRoom_Base.png",
"1C": "res://Textures/RoomFiles/Pirate'sCove_base.png",
"2A" : "res://Textures/RoomFiles/WestHall_Base.png",
"2B" : "res://Textures/RoomFiles/WestHallCorner_Base.png",
"3" : "res://Textures/RoomFiles/Supply_Closet_Base.png",
"4A" : "res://Textures/RoomFiles/EastHall_Base.png",
"4B" : "res://Textures/RoomFiles/EastHallCorner_base.png",
"5" : "res://Textures/RoomFiles/Backstage_Base.png",
"6" : "res://Textures/RoomFiles/Kitchen.png",
"7" : "res://Textures/RoomFiles/Bathrooms_Base.png"
}

var room_Characters = {"1A" : ["res://Textures/CharacterLayers/Showstage_Bonnie.png", 
"res://Textures/CharacterLayers/Showstage_Chica.png", "res://Textures/CharacterLayers/Showstage_Freddy.png"],
"1B" : ["res://Textures/CharacterLayers/Dining_Bonnie.png", "res://Textures/CharacterLayers/Dining_Chica.png", null],
"1C" : ["res://Textures/CharacterLayers/PirateCove_Foxy1.png"],#pirates cove
"2A" : ["res://Textures/CharacterLayers/WestHall_Bonnie.png", null, null],
"2B" : ["res://Textures/CharacterLayers/WestHallCorner_Bonnie.png", null, null],
"3" : ["res://Textures/CharacterLayers/Supply_Closet_Bonnie.png", null, null],
"4A" : [null, "res://Textures/CharacterLayers/EastHall_Chica.png", null, null], #East Hall
"4B" : [null, "res://Textures/CharacterLayers/EastHallCorner_Chica.png", null, null], #East Hall Corner
"5" : ["res://Textures/CharacterLayers/Backstage_Bonnie.png", null, null],
"6" : [null, "", null, null],#Kitchen, there are none
"7" : [null, "res://Textures/CharacterLayers/Bathrooms_Chica1.png", null, null] #Bathrooms
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Load on ready to ensure NOT NULL
	#await get_tree().create_timer(0.5).timeout #No effect
	if self.is_visible(): #Set invisible so program doesn't crash if left visible
		self.set_visible(false)
	layer_List = [$CharacterLayer1, $CharacterLayer2, $CharacterLayer3, $CharacterLayer4, $CharacterLayer5] #layer 1 = bonnie, layer 2 = chica


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#Animation maybe?
#camera moving tech
func update_cam(camName = current_camera):
	current_camera = camName
	if camName == "6":
		kitchenSounds()
	else:
		kitchenSoundsOff()
	$ScreenCamera/MapUI/CameraDetail.set_text(room_names[current_camera]) 
	$RoomView.set_texture(load(room_textures[current_camera]))
	build_room()

##layer_list currently locked to locations list
#Constructs Character layer to overlay room texture
func build_room():
	var locations = $"../../AnimatronicAIController".give_Locations() #list of [Bonnie,Chica,Freddy,Foxy] update every time
	for index in range(0, 3): #assume noninclusive for 0-2
		if locations[index] == current_camera: #If animatronic is in room, add the layer texture
			layer_List[index].set_texture(load(room_Characters[current_camera][index]))
		else: #If no animatronic, empty layer
			layer_List[index].set_texture(null)

#Show stage has Bonnie, Freddy, and Chica. Bonnie leaves first, then Chica, then Freddy (if not observed). They do not return in the night.
func _on_cam_1a_pressed() -> void:
	update_cam("1A") 

func _on_cam_1b_pressed() -> void:
	update_cam("1B")

func _on_cam_1c_pressed() -> void:
	update_cam("1C")

func _on_cam_2a_pressed() -> void:
	update_cam("2A")

func _on_cam_2b_pressed() -> void:
	update_cam("2B")

func _on_cam_3_pressed() -> void:
	update_cam("3")

func _on_cam_4a_pressed() -> void:
	update_cam("4A") 

func _on_cam_4b_pressed() -> void:
	update_cam("4B")

func _on_cam_5_pressed() -> void:
	update_cam("5")

func _on_cam_6_pressed() -> void:
	update_cam("6")
	#kitchenSounds()

func _on_cam_7_pressed() -> void:
	update_cam("7")


func _on_animatronic_ai_controller_did_move(room: Variant) -> void:
	#If animatronic left the room you staring at, remove their layer
	if str(room) == current_camera:
		#todo: kill the camera temporarily
		await get_tree().create_timer(0.05).timeout #Code runs too fast to take layer out
		update_cam(current_camera)

#Set the kitchen sound layers
#0: BaseLow, 1: BaseHigh, 2: Chica, 3: Freddy
func kitchenSounds():
	var locations = $"../../AnimatronicAIController".give_Locations()
	var chicaPresent = locations[1] == "6"
	var freddyPresent = locations[2] == "6"
	$"../../CameraNode/Camera2D/KitchenChicaStream"._set_playing(chicaPresent)
	$"../../CameraNode/Camera2D/KitchenLowBaseStream".set_volume_db(0)
	$"../../CameraNode/Camera2D/KitchenFreddyStream"._set_playing(freddyPresent)
	$"../../CameraNode/Camera2D/KitchenLowBaseStream"._set_playing((!chicaPresent) != (!freddyPresent)) # XOR
	$"../../CameraNode/Camera2D/KitchenHighBaseStream"._set_playing(chicaPresent and freddyPresent)

func kitchenSoundsOff():
	$"../../CameraNode/Camera2D/KitchenFreddyStream"._set_playing(false)
	$"../../CameraNode/Camera2D/KitchenChicaStream"._set_playing(false)
	if $"../../AnimatronicAIController".give_Locations()[1] == "6": #If chica still present
		$"../../CameraNode/Camera2D/KitchenLowBaseStream".set_volume_db(-20)
	else:
		$"../../CameraNode/Camera2D/KitchenLowBaseStream"._set_playing(false)
	$"../../CameraNode/Camera2D/KitchenHighBaseStream"._set_playing(false)
