extends Node3D

var animPlayer = null

# Called when the node enters the scene tree for the first time.
func _ready():
	animPlayer = $AnimationPlayer
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event):
	# Mouse Looking logic
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()):
		animPlayer.play("shoot-anim")

