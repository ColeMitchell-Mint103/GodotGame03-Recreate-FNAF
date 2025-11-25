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
	$RandomAmbient/RandomTimer.start(randi_range(0, 50 * golden_factor) + 10)



func _on_random_timer_timeout() -> void:
	$RandomAmbient.play()


func _on_random_ambient_finished() -> void:
	$RandomAmbient.stop()
	$RandomAmbient/RandomTimer.start(randi_range(0, 50 * golden_factor) + 6) #delay between sounds
