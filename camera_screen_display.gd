extends TextureRect

var current_camera = "Show Stage"
var room_textures = {"Show Stage" : "res://Textures/RoomFiles/Showstage_Base.png",
"Dining Area" : "res://Textures/RoomFiles/DiningRoom_Base.png",
"Pirate's Cove": "res://Textures/RoomFiles/Pirate'sCove_base.png",
"West Hall" : "res://Textures/RoomFiles/WestHall_Base.png",
"West Hall Corner" : "res://Textures/RoomFiles/WestHallCorner_Base.png",
"Closet" : "res://Textures/RoomFiles/Supply_Closet_Base.png",
"East Hall" : "res://Textures/RoomFiles/EastHall_Base.png",
"East Hall Corner" : "res://Textures/RoomFiles/EastHallCorner_base.png",
"Backstage" : "res://Textures/RoomFiles/Backstage_Base.png",
"Kitchen" : "res://Textures/RoomFiles/Kitchen.png",
"Bathrooms" : "res://Textures/RoomFiles/Bathrooms_Base.png"
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#pass # Replace with function body.
	$CharacterLayer1.set_texture(load("res://Textures/CharacterLayers/Showstage_Chica.png"))
	$CharacterLayer2.set_texture(load("res://Textures/CharacterLayers/Showstage_Freddy.png"))
	$CharacterLayer3.set_texture(load("res://Textures/CharacterLayers/Showstage_Bonnie.png"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#Animation maybe?
#camera moving tech
func update_cam():
	$MapUI/CameraDetail.set_text(current_camera)
	$RoomView.set_texture(load(room_textures[current_camera]))

func _on_cam_1a_pressed() -> void:
	current_camera = "Show Stage"
	update_cam()

func _on_cam_1b_pressed() -> void:
	current_camera = "Dining Area"
	update_cam()

func _on_cam_1c_pressed() -> void:
	current_camera = "Pirate's Cove"
	update_cam()

func _on_cam_2a_pressed() -> void:
	current_camera = "West Hall"
	update_cam()

func _on_cam_2b_pressed() -> void:
	current_camera = "West Hall Corner"
	update_cam()

func _on_cam_3_pressed() -> void:
	current_camera = "Closet"
	update_cam()

func _on_cam_4a_pressed() -> void:
	current_camera = "East Hall"
	update_cam()

func _on_cam_4b_pressed() -> void:
	current_camera = "East Hall Corner"
	update_cam()

func _on_cam_5_pressed() -> void:
	current_camera = "Backstage"
	update_cam()

func _on_cam_6_pressed() -> void:
	current_camera = "Kitchen"
	update_cam()

func _on_cam_7_pressed() -> void:
	current_camera = "Bathrooms"
	update_cam()
