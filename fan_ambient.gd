extends AudioStreamPlayer

var golden_factor = 0 #More golden freddy = more noises
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func begin(golden_freddy):
	golden_factor = golden_freddy #Ranges from 0.0-1.0
	$".".play()
	$RandomAmbient/RandomTimer.start(randf_range(3.0,7.0))

#Playing random sounds for ambience.
func _on_random_timer_timeout() -> void:
	$RandomAmbient.play()
	if randi_range(1,30) == 1: #Start the fun music
		$FunSongAmbient.play()
		$FunSongAmbient/FunTimer.start(randf_range(6.0,15.0))

#Start a pause between sounds based on GoldeFreddy power
func _on_random_ambient_finished() -> void:
	$RandomAmbient.stop()
	$RandomAmbient/RandomTimer.start(randf_range(3.0,7.0)) #delay between sounds

#Stop the fun music at random time
func _on_fun_timer_timeout() -> void:
	$FunSongAmbient.stop()
