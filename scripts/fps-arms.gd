extends Camera3D
@onready var glock = $"fps_rig/glock2"
@onready var fps_arms = $"fps_rig/fps-arms_UNMIRROED1"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	glock.position.x = lerp(glock.position.x, 0.0, delta*5)
	glock.position.y = lerp(glock.position.y, 0.0, delta*5)
	fps_arms.position.x = lerp(fps_arms.position.x, 0.0, delta*5)
	fps_arms.position.y = lerp(fps_arms.position.y, 0.0, delta*5)

func sway(sway_amount):
	glock.position.x =+ sway_amount.x
	glock.position.y =+ sway_amount.y
	fps_arms.position.x =+ sway_amount.x
	fps_arms.position.y =+ sway_amount.y
