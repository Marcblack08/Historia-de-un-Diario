extends Node3D

var camera: Camera3D
var fade: ColorRect
var caption: Label
var prompt: Label
var cinematic_active := true
var skip_requested := false
var rain: GPUParticles3D

func _ready() -> void:
	_build_world()
	_build_ui()
	_start_cinematic()

func _process(_delta: float) -> void:
	if cinematic_active and is_instance_valid(camera):
		var target := Vector3(0.0, 2.2, -8.0)
		camera.look_at(target, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if not cinematic_active:
		return
	if event is InputEventKey and event.pressed:
		skip_requested = true
	elif event is InputEventScreenTouch and event.pressed:
		skip_requested = true
	elif event is InputEventMouseButton and event.pressed:
		skip_requested = true

func _mat(color: Color, roughness := 0.8, emission := Color(0, 0, 0, 1)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	if emission.a > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 1.6
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = material
	n.position = pos
	parent.add_child(n)
	return n

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.008, 0.012, 0.018)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.16, 0.19, 0.23)
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48, -28, 0)
	moon.light_color = Color(0.48, 0.56, 0.68)
	moon.light_energy = 0.55
	moon.shadow_enabled = true
	add_child(moon)

	var ground_mat := _mat(Color(0.035, 0.04, 0.038), 0.95)
	_box(self, Vector3(34, 0.25, 40), Vector3(0, -0.15, -4), ground_mat)

	var road_mat := _mat(Color(0.055, 0.06, 0.062), 0.7)
	_box(self, Vector3(9, 0.08, 40), Vector3(0, 0, 8), road_mat)

	var house := Node3D.new()
	house.position = Vector3(0, 0, -9)
	add_child(house)

	var wall := _mat(Color(0.24, 0.23, 0.21), 0.92)
	var roof := _mat(Color(0.055, 0.05, 0.045), 0.9)
	_box(house, Vector3(12, 5.2, 7), Vector3(0, 2.6, 0), wall)
	_box(house, Vector3(13.2, 0.8, 8), Vector3(0, 5.45, 0), roof)
	_box(house, Vector3(14, 0.35, 8.5), Vector3(0, 6.0, 0), roof)

	var door_mat := _mat(Color(0.075, 0.045, 0.028), 0.72)
	_box(house, Vector3(1.6, 2.9, 0.18), Vector3(0, 1.45, 3.56), door_mat)

	var glow := _mat(Color(0.72, 0.38, 0.13), 0.4, Color(1.0, 0.36, 0.08, 1))
	for x in [-3.9, 3.9]:
		_box(house, Vector3(2.2, 1.8, 0.12), Vector3(x, 2.9, 3.55), glow)
	for x in [-3.9, 3.9]:
		_box(house, Vector3(2.2, 1.8, 0.12), Vector3(x, 2.9, -3.55), glow)

	var porch_light := OmniLight3D.new()
	porch_light.position = Vector3(0, 3.2, 4.2)
	porch_light.light_color = Color(1.0, 0.42, 0.14)
	porch_light.light_energy = 2.0
	porch_light.omni_range = 7.0
	add_child(porch_light)

	# Car in the foreground.
	var car := Node3D.new()
	car.position = Vector3(5.2, 0.65, 3.8)
	car.rotation_degrees.y = -10
	add_child(car)
	var car_body := _mat(Color(0.018, 0.022, 0.025), 0.35)
	_box(car, Vector3(4.2, 0.75, 2.0), Vector3(0, 0.3, 0), car_body)
	_box(car, Vector3(2.2, 0.65, 1.65), Vector3(-0.2, 0.92, 0), car_body)
	var glass := _mat(Color(0.035, 0.06, 0.08), 0.18)
	_box(car, Vector3(1.7, 0.45, 1.48), Vector3(-0.2, 1.02, 0), glass)

	# Rain particles.
	rain = GPUParticles3D.new()
	rain.amount = 260
	rain.lifetime = 1.25
	rain.position = Vector3(0, 8, 0)
	var rain_mesh := BoxMesh.new()
	rain_mesh.size = Vector3(0.015, 0.45, 0.015)
	rain.draw_pass_1 = rain_mesh
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.08, -1.0, 0.02)
	process.spread = 8.0
	process.initial_velocity_min = 12.0
	process.initial_velocity_max = 18.0
	process.gravity = Vector3(0, -4, 0)
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(16, 4, 18)
	rain.process_material = process
	add_child(rain)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 62.0
	camera.position = Vector3(0, 1.55, 13.5)
	add_child(camera)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)

	caption = Label.new()
	caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	caption.position = Vector2(-520, -125)
	caption.size = Vector2(1040, 70)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_color_override("font_color", Color(0.86, 0.84, 0.78))
	caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(caption)

	prompt = Label.new()
	prompt.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	prompt.position = Vector2(-310, -55)
	prompt.size = Vector2(280, 35)
	prompt.text = "TOCA PARA OMITIR"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prompt.add_theme_font_size_override("font_size", 13)
	prompt.add_theme_color_override("font_color", Color(0.6, 0.58, 0.54, 0.75))
	layer.add_child(prompt)

func _fade_to(alpha: float, duration: float) -> void:
	var t := create_tween()
	t.tween_property(fade, "color:a", alpha, duration)
	await t.finished

func _caption(text: String, duration: float) -> void:
	caption.text = text
	caption.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(caption, "modulate:a", 1.0, 0.55)
	await get_tree().create_timer(duration).timeout
	var out := create_tween()
	out.tween_property(caption, "modulate:a", 0.0, 0.5)
	await out.finished

func _move_camera(pos: Vector3, duration: float) -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(camera, "position", pos, duration)
	await t.finished

func _start_cinematic() -> void:
	await get_tree().process_frame
	await _fade_to(0.0, 1.5)
	if skip_requested:
		_finish()
		return

	await _caption("Hay lugares a los que uno nunca debería volver.", 3.5)
	if skip_requested:
		_finish()
		return

	await _move_camera(Vector3(0, 1.8, 8.0), 3.0)
	await _caption("Después de muchos años...", 2.5)
	if skip_requested:
		_finish()
		return

	await _move_camera(Vector3(0, 2.15, 1.0), 3.2)
	await _caption("La casa seguía allí.", 2.4)
	if skip_requested:
		_finish()
		return

	await _move_camera(Vector3(0, 1.75, -5.4), 3.5)
	await _caption("Pero no estaba vacía.", 2.8)
	if skip_requested:
		_finish()
		return

	await _move_camera(Vector3(0, 1.45, -5.8), 2.2)
	await _caption("...", 1.0)
	await _fade_to(1.0, 0.8)
	await _get_diary_beat()
	_finish()

func _get_diary_beat() -> void:
	caption.text = "SI ESTÁS LEYENDO ESTO, YA REGRESASTE."
	caption.modulate.a = 1.0
	await get_tree().create_timer(2.6).timeout
	await _fade_to(1.0, 0.6)

func _finish() -> void:
	if not cinematic_active:
		return
	cinematic_active = false
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.35)
	await t.finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")
