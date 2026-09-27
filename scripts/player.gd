extends CharacterBody3D

@export var speed := 3.2
@export var mouse_sensitivity := 0.0025
@export var gravity := 12.0
@onready var camera: Camera3D = $Camera3D
@onready var prompt: Label = $InteractionPrompt
var looking_at: Area3D = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_E and looking_at:
			get_tree().call_group("game", "show_interaction", looking_at.interact())

func _physics_process(delta: float) -> void:
	var input_vec := Vector2.ZERO
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
	if Input.is_key_pressed(KEY_F) and not get_meta("flashlight_pressed", false):
		$Camera3D/Flashlight.visible = not $Camera3D/Flashlight.visible
		set_meta("flashlight_pressed", true)
	elif not Input.is_key_pressed(KEY_F):
		set_meta("flashlight_pressed", false)
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
