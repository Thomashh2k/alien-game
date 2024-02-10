extends CharacterBody3D

@onready var neck = $neck
@onready var head = $neck/Head
@onready var eyes = $neck/Head/eyes
@onready var camera_3d = $neck/Head/eyes/Camera3D
@onready var animPlayer = $neck/Head/eyes/AnimationPlayer
@onready var standing_collision_shape = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var ray_cast_3d = $RayCast3D
@onready var sub_viewport = $neck/Head/eyes/Camera3D/SubViewportContainer/SubViewport
@onready var view_model_camera = $neck/Head/eyes/Camera3D/SubViewportContainer/SubViewport/view_model_camera

@export var current_speed = 5.0
@export var walking_speed = 5.0
@export var sprinting_speed = 8.0
@export var crouching_speed = 3.0
@export var mouse_sensitivity = 0.03

# Movement-States
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

var last_velocity = Vector3.ZERO

# Slide vars
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.0

# Head bobbings vars

const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_sprinting_intensity = 0.08
const head_bobbing_walking_intensity = 0.10
const head_bobbing_crouching_intensity = 0.20

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intensity = 0.0


const jump_velocity = 4.5

var lerp_speed = 10.0
var air_lerp_speed = 1.0

var free_look_tilt_amount = 10

var direction = Vector3.ZERO
var crounching_depth = -0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	sub_viewport.size = DisplayServer.window_get_size()
	

func _input(event):
	# Mouse Looking logic
	if event is InputEventMouseMotion:
		if Gamemode.free_looking_enabled || sliding:
			performFreeLook(event)
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		# lock vertically mouse movement 89" degrees down and up
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		#view_model_camera.sway(Vector2(event.relative.x, event.relative.y))

func _process(delta):
	pass
func _physics_process(delta):
	view_model_camera.global_transform = camera_3d.global_transform
	#print("FPS: %d" % Engine.get_frames_per_second())
	# Handle movement state
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	if Input.is_action_pressed("crouch") || sliding:
		# Crouching
		if is_on_floor():
			current_speed = lerp(current_speed, crouching_speed, lerp_speed * delta)
			# lerp head down for crounching
			head.position.y = lerp(head.position.y, crounching_depth, lerp_speed * delta)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		# Slide begin logic
		if sprinting && is_on_floor() && input_dir != Vector2.ZERO:
			sliding = true
			free_looking = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			print("Slide begin...")
		
		walking = false
		sprinting = false
		crouching = true
		
	elif !ray_cast_3d.is_colliding():
		# Collides not with ceiling
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		# lerp the head back up
		head.position.y = lerp(head.position.y, 0.0, lerp_speed * delta)
		if Input.is_action_pressed("sprinting"):
			current_speed = lerp(current_speed, sprinting_speed, lerp_speed * delta)
			walking = false
			sprinting = true
			crouching = false
		else:
			current_speed = lerp(current_speed, walking_speed, lerp_speed * delta)
			walking = true
			sprinting = false
			crouching = false
	
	# if Input.is_action_pressed("lean_left"):
	
	if Gamemode.free_looking_enabled || Gamemode.sliding_enabled:
		# Handle free looking
		listenOnFreeLooking(delta)
	if Gamemode.sliding_enabled:
		listenOnSliding(delta)
		
	# Handle headbob
	handleHeadBob(delta)
	
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index / 2) + 0.5
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y * (head_bobbing_current_intensity / 2.0), lerp_speed * delta)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x * head_bobbing_current_intensity, lerp_speed * delta)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, lerp_speed * delta)
		eyes.position.x = lerp(eyes.position.x, 0.0, lerp_speed * delta)
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() && !sliding:
		velocity.y = jump_velocity
		sliding = false
		animPlayer.play("jump")
		
	# Handle landing
	if is_on_floor():
		if last_velocity.y < -10.0:
			if Gamemode.roll_landing_enabled:
				print(last_velocity.y)
				animPlayer.play("roll_landing")
			elif last_velocity.y < -0.0:
				animPlayer.play("landing")
			
	
	if Gamemode.air_control_enabled:
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
	else:
		if is_on_floor():
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerp_speed)
		else:
			if input_dir != Vector2.ZERO:
				direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * air_lerp_speed)
			
	
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		current_speed = (slide_timer + 0.1) * slide_speed

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	last_velocity = velocity
	
	move_and_slide()
	

func listenOnSliding(delta):
	if sliding and is_on_floor():
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			print("Slide end...")
			free_looking = false

func listenOnFreeLooking(delta):
	if Input.is_action_pressed("free_looking") || sliding:
		free_looking = true
		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z, -deg_to_rad(7.0), lerp_speed * delta)
		else:
			eyes.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt_amount)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, lerp_speed * delta)
		var cameraRotateFactor = 0 if sprinting else 10
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0, (lerp_speed + cameraRotateFactor) * delta)
		# eyes.ro@onready var animation_player = $neck/Head/eyes/AnimationPlayer
func performFreeLook(event):
	if free_looking:
		neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
	else:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

func handleHeadBob(delta):
	if sprinting:
		head_bobbing_current_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif walking:
		head_bobbing_current_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif crouching:
		head_bobbing_current_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
