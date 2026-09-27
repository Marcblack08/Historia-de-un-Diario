extends CharacterBody3D

@export var speed := 3.2
@export var mouse_sensitivity := 0.0025
@export var touch_look_sensitivity := 0.004
@export var gravity := 12.0

@onready var camera: Camera3D = $Camera3D
@onready var prompt: Label = $InteractionPrompt
var looking_at: Area3D = null
var touch_move := Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		apply_look(event.relative)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_E:
			interact()

func apply_look(delta: Vector2) -> void:
	rotate_y(-delta.x * mouse_sensitivity)
	camera.rotate_x(-delta.y * mouse_sensitivity)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

func set_touch_move(value: Vector2) -> void:
	touch_move = value

func touch_look(delta: Vector2) -> void:
	rotate_y(-delta.x * touch_look_sensitivity)
	camera.rotate_x(-delta.y * touch_look_sensitivity)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

func flashlight() -> void:
	$Camera3D/Flashlight.visible = not $Camera3D/Flashlight.visible

func interact() -> void:
	if looking_at:
		get_tree().call_group("game", "show_interaction", looking_at.interact())

func _physics_process(delta: float) -> void:
	var input_vec := touch_move
	if input_vec.length() < 0.05:
		input_vec = Vector2.ZERO
		if Input.is_key_pressed(KEY_A): input_vec.x -= 1.0
		if Input.is_key_pressed(KEY_D): input_vec.x += 1.0
		if Input.is_key_pressed(KEY_W): input_vec.y -= 1.0
		if Input.is_key_pressed(KEY_S): input_vec.y += 1.0
	var direction := (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	_update_interaction()

func _update_interaction() -> void:
	var space := get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from + -camera.global_transform.basis.z * 3.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var hit := space.intersect_ray(query)
	looking_at = null
	prompt.visible = false
	if hit and hit.collider is Area3D:
		looking_at = hit.collider
		prompt.text = "[ E ]  " + str(looking_at.item_name)
		prompt.visible = true
