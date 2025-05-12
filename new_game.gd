extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_mouse_entered() -> void:
	$"../Continue/Indic".set_visible(false)
	$Indic.set_visible(true)


func _on_pressed() -> void:
	$"../../NewspaperTransition".play('GOOD EMPLOYMENT')
	


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://Night1.tscn")
	#get_tree().root.add_child(load("res://Night1.tscn").instantiate())
	#var level = get_tree().root.get_node('TitleScreen')
	#get_tree().get_node("TitleScreen").free()
