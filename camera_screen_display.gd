extends TextureRect

var layer_List = [$BonnieLayer,$ChicaLayer,$FreddyLayer,$FoxyLayer,$GoldenLayer]
var current_camera = "1A"
#var camera_open = false #bad duplicate donotuse
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

# Images of characters, currently in bonnie,chica,freddy. See build_room()
var room_Characters = {"1A" : ["res://Textures/CharacterLayers/Showstage_Bonnie.png", 
"res://Textures/CharacterLayers/Showstage_Chica.png", "res://Textures/CharacterLayers/Showstage_Freddy.png"],
"1B" : ["res://Textures/CharacterLayers/Dining_Bonnie.png", "res://Textures/CharacterLayers/Dining_Chica.png", "res://Textures/CharacterLayers/Dining_Freddy.png"],
"1C" : ["res://Textures/CharacterLayers/PirateCove_Foxy0.png"],#pirates cove
"2A" : ["res://Textures/CharacterLayers/WestHall_Bonnie.png", null, null],
"2B" : ["res://Textures/CharacterLayers/WestHallCorner_Bonnie.png", null, null],
"3" : ["res://Textures/CharacterLayers/Supply_Closet_Bonnie.png", null, null],
"4A" : [null, "res://Textures/CharacterLayers/EastHall_Chica.png", "res://Textures/CharacterLayers/EastHall_Freddy.png", null], #East Hall
"4B" : [null, "res://Textures/CharacterLayers/EastHallCorner_Chica.png", "res://Textures/CharacterLayers/EastHallCorner_Freddy.png", null], #East Hall Corner
"5" : ["res://Textures/CharacterLayers/Backstage_Bonnie.png", null, null],
"6" : [null, "", "", null],#Kitchen, there are none - If you load null the program crashes.
"7" : [null, "res://Textures/CharacterLayers/Bathrooms_Chica1.png", "res://Textures/CharacterLayers/Bathrooms_Freddy.png", null] #Bathrooms
}

#FoxyStages
var foxy_Textures = ["res://Textures/CharacterLayers/PirateCove_Foxy0.png",
"res://Textures/CharacterLayers/PirateCove_Foxy1.png",
"res://Textures/CharacterLayers/PirateCove_Foxy2.png",
"res://Textures/CharacterLayers/PirateCove_Foxy3.png",
"res://Textures/CharacterLayers/PirateCove_Foxy4.png"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Load on ready to ensure NOT NULL
	#await get_tree().create_timer(0.5).timeout #No effect
	if self.is_visible(): #Set invisible so program doesn't crash if left visible
		self.set_visible(false)
	layer_List = [$BonnieLayer,$ChicaLayer,$FreddyLayer,$FoxyLayer,$GoldenLayer]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#camera moving tech
func update_cam(camName = current_camera):
	current_camera = camName
	#Kitchen handling
	$ScreenCamera/KitchenLayer.set_visible(true if current_camera == "6" else false)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Kitchen"), 0 if camName == "6" else -10)
	$ScreenCamera/MapUI/CameraDetail.set_text(room_names[current_camera])
	$RoomView.set_texture(load(room_textures[current_camera]))
	#Foxy Camera volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Foxy"), 0 if camName == "3" else -10)
	#FoxyRun handling
	if camName == "2A" and $"../../AnimatronicAIController".FoxyAttack:
		$"../../AnimatronicAIController".FoxyAttack = false #Maybe problematic
		#print("Foxy chase go")
		$"../../AnimatronicAIController/FoxyKillYouTimer".stop()
		$"../../AnimatronicAIController/FoxyKillYouTimer".start(2) #Changed from 1 second
		$"../../FanAmbient/Foxy Audio/FoxyAmbientTimer".stop() #Pause his ambient noises
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Foxy"), 0)
		$"../../FanAmbient/Foxy Audio".set_stream(load("res://SFX/Foxy/FoxyRunAudio.mp3"))
		$"../../FanAmbient/Foxy Audio".play()
		$FoxyLayer/FoxyCharge.set_frame(0)
		$FoxyLayer/FoxyCharge.set_visible(true)
		$FoxyLayer/FoxyCharge.play() #Foxy charges down the hall now. Should not be drawn over room but only camera.
	build_room()
	if current_camera == "2B" and $"../..".golden_freddy and not $"../../Fredbear".is_visible():
		$"../../Fredbear/FredbearAttackBegin".play()
		$"../../Fredbear".set_visible(true)

##layer_list currently locked to locations list
#Constructs Character layer to overlay room texture
func build_room():
	var locations = $"../../AnimatronicAIController".give_Locations() #list of [Bonnie,Chica,Freddy,Foxy] update every time
	for index in range(0, 3): #assume noninclusive for 0-2
		if locations[index] == current_camera: #If animatronic is in room, add the layer texture
			layer_List[index].set_texture(load(room_Characters[current_camera][index]))
		else: #If no animatronic, empty layer
			layer_List[index].set_texture(null)
	# Pirate's Cove Handling
	if current_camera == "1C":
		for index in range(0, 3): #unload other characters
			layer_List[index].set_texture(null)
		layer_List[3].set_texture(load(room_Characters[current_camera][0])) #load Foxy
	else:
		layer_List[3].set_texture(null) #unload Foxy

#Show stage has Bonnie, Freddy, and Chica. Bonnie leaves first, then Chica, then Freddy (if not observed). They do not return in the night.
func _on_cam_1a_pressed() -> void:
	update_cam("1A") 
	$"../../CameraNode/Camera2D/CameraSounds_DARK/Camera_DEEP".play()

func _on_cam_1b_pressed() -> void:
	update_cam("1B")
	$"../../CameraNode/Camera2D/CameraSounds_DARK/Camera_DEEP".play()

func _on_cam_1c_pressed() -> void:
	update_cam("1C")
	$"../../CameraNode/Camera2D/CameraSounds_DARK/Camera_DEEP".play()

func _on_cam_2a_pressed() -> void:
	update_cam("2A")
	$"../../CameraNode/Camera2D/CameraSounds_DARK/Camera_DEEP".play()

func _on_cam_2b_pressed() -> void:
	update_cam("2B")
	$"../../CameraNode/Camera2D/CameraSounds_DARK/Camera_DEEP".play()
	#if $"../..".golden_freddy and not $"../../Fredbear".is_visible():
		#$"../../Fredbear/FredbearAttackBegin".play()
		#$"../../Fredbear".set_visible(true)

func _on_cam_3_pressed() -> void:
	update_cam("3")
	$"../../CameraNode/Camera2D/CameraSounds_DARK/Camera_DEEP".play()

func _on_cam_4a_pressed() -> void:
	update_cam("4A") 
	$"../../CameraNode/Camera2D/CameraSounds_DARK/Camera_DEEP".play()

func _on_cam_4b_pressed() -> void:
	update_cam("4B")
	$"../../CameraNode/Camera2D/CameraSounds_DARK/Camera_DEEP".play()

func _on_cam_5_pressed() -> void:
	update_cam("5")
	$"../../CameraNode/Camera2D/CameraSounds_DARK/Camera_DEEP".play()

func _on_cam_6_pressed() -> void:
	update_cam("6")
	$"../../CameraNode/Camera2D/CameraSounds_DARK/Camera_DEEP".play()

func _on_cam_7_pressed() -> void:
	update_cam("7")
	$"../../CameraNode/Camera2D/CameraSounds_DARK/Camera_DEEP".play()


func _on_animatronic_ai_controller_did_move(room: Variant) -> void:
	#If animatronic left the room you staring at, remove their layer
	if str(room) == current_camera:
		if $"../..".camera_open:
			$ScreenCamera/MonitorStatic.play("StaticAnim")
			$ScreenCamera/MonitorStatic/MonitorStatic.play()
			$ScreenCamera/MonitorStatic/CamOutTimer.start(randf_range(1.0,1.8))
		await get_tree().create_timer(0.05).timeout #Code runs too fast to take layer out
		update_cam(current_camera)

func isFreddyOnCam():
	return $"../..".camera_open and current_camera == $"../../AnimatronicAIController".give_Locations()[2]
	
# Called by animatronic_ai_controller when FoxyStage changes.
func updateFoxy(stage):
	room_Characters["1C"][0] = foxy_Textures[stage]

func cam_close():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Kitchen"), -10)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Foxy"), -10)


func _on_cam_out_timer_timeout() -> void:
	$ScreenCamera/MonitorStatic.play("default")
