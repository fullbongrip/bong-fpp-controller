extends CharacterBody3D

@onready var head = $head
@onready var standing_collision = $standing_collision
@onready var crouching_collision = $crouching_collision
@onready var ray_cast_3d = $RayCast3D
@onready var view_model_cam = $head/Camera3D/SubViewportContainer/SubViewport/view_model_cam

var current_speed = 5.0
var current_head_height = 1.8  # Default standing height
var target_head_height = 1.8   # Start with standing height

const walking_speed = 5.0
const sprint_speed = 8.0
const crouch_speed = 2.5

const jump_impulse = 8.0  # Impulse applied when jumping
const gravity = -24.0     # Gravity strength for more realistic falling

const mouse_sens = 0.1

var lerp_speed = 10.0
var crouching_depth = 1.3
var height_lerp_speed = 8.0  # Speed of head height interpolation

var head_bob_frequency = 10.0  # Frequency bobbing
var head_bob_amplitude = 0.05  
var head_bob_timer = 0.0  # Timer for bobbing

var is_jumping = false  # check if the player is in air

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$head/Camera3D/SubViewportContainer/SubViewport.size = DisplayServer.window_get_size()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		view_model_cam.sway(Vector2(event.relative.x, event.relative.y))

func _physics_process(delta):
	$head/Camera3D/SubViewportContainer/SubViewport/view_model_cam.global_transform = $head/Camera3D.global_transform
	
	if Input.is_action_pressed("crouch"):
		current_speed = crouch_speed
		target_head_height = crouching_depth
		standing_collision.disabled = true
		crouching_collision.disabled = false
	elif ray_cast_3d.is_colliding():
		current_speed = crouch_speed
	elif Input.is_action_pressed("sprint"):
		current_speed = sprint_speed
	elif !ray_cast_3d.is_colliding():
		current_speed = walking_speed
		target_head_height = 1.8
		standing_collision.disabled = false
		crouching_collision.disabled = true
	elif ray_cast_3d.is_colliding():
		current_speed = crouch_speed

	# Smoothly interpolate the head height
	current_head_height = lerp(current_head_height, target_head_height, height_lerp_speed * delta)

	# Get the input direction
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Calculate head bobbing effect only if on the floor and moving
	var bobbing = 0.0
	if is_on_floor() and direction.length() > 0.1:  # Only bob while moving on the floor
		head_bob_timer += delta * head_bob_frequency * (current_speed / walking_speed)
		bobbing = sin(head_bob_timer) * head_bob_amplitude

	head.position.y = current_head_height + bobbing

	# Jumping logic
	if is_on_floor():
		if Input.is_action_pressed("space") and not is_jumping:
			is_jumping = true
			velocity.y = jump_impulse
	else:
		# Apply gravity if not on the floor
		velocity.y += gravity * delta

	# Stop jumping when the player is on the ground
	if is_on_floor() and is_jumping:
		is_jumping = false

	# Smoothly interpolate the velocity
	var target_velocity = direction * current_speed
	velocity.x = lerp(velocity.x, target_velocity.x, lerp_speed * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, lerp_speed * delta)

	# Move the character
	move_and_slide()

