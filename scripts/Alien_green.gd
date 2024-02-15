extends CharacterBody3D

@onready var animation_player = $"alien-green/AnimationPlayer"

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var speed = 5
var target_node: Node

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	animation_player.play("Run")
	target_node = get_parent().get_node("./QodotMap/entity_1_player_spwan") # Passe den Pfad entsprechend an
	
	
func _physics_process(delta):
	# Überprüfe, ob das Ziel gültig ist
	print("target_node")
	print(target_node)
	if target_node != null:
		# Berechne die Richtung zum Ziel
		var direction = (target_node.global_transform.origin - global_transform.origin).normalized()
		# Bewege diesen Knoten in Richtung des Ziels mit der festgelegten Geschwindigkeit
		global_transform.origin += direction * speed * delta
		move_and_slide()
		#look_at(target_node.global_transform.origin)
		
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Run":
		animation_player.play("Run")
