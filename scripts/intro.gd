extends Node3D

# Apertura visual del juego: la primera impresión debe parecer una película de terror.
var camera: Camera3D
var fade: ColorRect
var caption: Label
var prompt: Label
var cinematic_active := true
var skip_requested := false
var rain: GPUParticles3D
var look_target := Vector3(0.0, 2.2, -8.0)
var house: Node3D
var porch_light: OmniLight3D
var window_lights: Array[OmniLight3D] = []

func _ready() -> void:
	_build_world()
	_build_ui()
	_start_cinematic()

func _process(_delta: float) -> void:
	if cinematic_active and is_instance_valid(camera):
		camera.look_at(look_target, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if not cinematic_active:
		return
	if event is InputEventKey and event.pressed:
		skip_requested = true
	elif event is InputEventScreenTouch and event.pressed:
		skip_requested = true
	elif event is InputEventMouseButton and event.pressed:
		skip_requested = true

func _mat(color: Color, roughness := 0.8, emission := Color(0, 0, 0, 1), metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if emission.a > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 1.25
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = material
	n.position = pos
	n.rotation_degrees = rot
	parent.add_child(n)
	return n

func _cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.12
	mesh.height = height
	n.mesh = mesh
	n.material_override = material
	n.position = pos
	parent.add_child(n)
	return n

func _tree(pos: Vector3, scale := 1.0) -> void:
	var tree := Node3D.new()
	tree.position = pos
	tree.scale = Vector3.ONE * scale
	add_child(tree)
	var trunk := _mat(Color(0.055, 0.038, 0.025), 0.95)
	_cylinder(tree, 0.22, 3.8, Vector3(0, 1.9, 0), trunk)
	var foliage := _mat(Color(0.018, 0.035, 0.025), 0.98)
	for p in [Vector3(-0.9, 3.6, 0), Vector3(0.7, 4.1, 0.2), Vector3(0, 5.0, -0.1), Vector3(-0.2, 4.35, -0.6)]:
		var leaf := _cylinder(tree, 1.0, 1.9, p, foliage)
		leaf.scale = Vector3(1.2, 1.0, 1.2)

func _window(parent: Node3D, pos: Vector3, size := Vector2(1.9, 1.55)) -> OmniLight3D:
	var frame := _mat(Color(0.075, 0.055, 0.04), 0.82)
	var glass := _mat(Color(0.72, 0.34, 0.12), 0.28, Color(1.0, 0.22, 0.045, 1))
	_box(parent, Vector3(size.x, size.y, 0.10), pos, glass)
	_box(parent, Vector3(0.10, size.y + 0.16, 0.14), pos + Vector3(0, 0, 0.08), frame)
	_box(parent, Vector3(size.x + 0.16, 0.10, 0.14), pos + Vector3(0, 0, 0.08), frame)
	_box(parent, Vector3(0.08, size.y, 0.16), pos + Vector3(0, 0, 0.10), frame)
	_box(parent, Vector3(size.x, 0.08, 0.16), pos + Vector3(0, 0, 0.10), frame)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 0, 0.8)
	light.light_color = Color(1.0, 0.46, 0.16)
	light.light_energy = 1.15
	light.omni_range = 4.0
	parent.add_child(light)
	window_lights.append(light)
	return light

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.004, 0.007, 0.012)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.075, 0.095, 0.12)
	environment.ambient_light_energy = 0.62
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.7
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.08, 0.10, 0.12)
	environment.fog_light_energy = 0.45
	environment.fog_density = 0.012
	environment.fog_sky_affect = 0.25
	env.environment = environment
	add_child(env)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48, -28, 0)
	moon.light_color = Color(0.42, 0.50, 0.62)
	moon.light_energy = 0.78
	moon.shadow_enabled = true
	add_child(moon)

	# Moon disk.
	var moon_node := MeshInstance3D.new()
	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 1.15
	moon_mesh.height = 2.3
	moon_node.mesh = moon_mesh
	moon_node.material_override = _mat(Color(0.72, 0.76, 0.78), 0.55, Color(0.48, 0.55, 0.62, 1))
	moon_node.position = Vector3(8.5, 9.5, -17)
	add_child(moon_node)

	var ground_mat := _mat(Color(0.022, 0.027, 0.026), 0.96)
	_box(self, Vector3(38, 0.25, 44), Vector3(0, -0.15, -4), ground_mat)

	# Wet driveway / road.
	var road_mat := _mat(Color(0.035, 0.040, 0.041), 0.18, Color(0.01, 0.012, 0.013, 1), 0.32)
	_box(self, Vector3(10.5, 0.09, 38), Vector3(0, 0, 8), road_mat)

	# Irregular puddle strips catch the warm house light.
	var puddle_mat := _mat(Color(0.035, 0.050, 0.055), 0.08, Color(0.005, 0.008, 0.01, 1), 0.65)
	for p in [Vector3(-2.6, 0.055, 7.0), Vector3(2.1, 0.058, 4.4), Vector3(-1.1, 0.06, 1.2), Vector3(3.2, 0.058, -1.8)]:
		_box(self, Vector3(2.8, 0.025, 0.55), p, puddle_mat, Vector3(0, -8, 0))

	# House silhouette.
	house = Node3D.new()
	house.position = Vector3(0, 0, -9)
	add_child(house)

	var wall := _mat(Color(0.19, 0.18, 0.165), 0.93)
	var wall_dark := _mat(Color(0.12, 0.115, 0.105), 0.96)
	var roof := _mat(Color(0.032, 0.029, 0.027), 0.96)
	var wood := _mat(Color(0.07, 0.042, 0.026), 0.82)

	_box(house, Vector3(12.5, 4.8, 7.2), Vector3(0, 2.4, 0), wall)
	_box(house, Vector3(10.5, 2.8, 6.8), Vector3(0, 6.0, 0), wall_dark)
	_box(house, Vector3(14.5, 0.65, 8.2), Vector3(0, 5.0, 0), roof, Vector3(0, 0, 0))
	_box(house, Vector3(13.4, 0.55, 7.7), Vector3(0, 7.35, 0), roof, Vector3(0, 0, 0))
	# Sloped roof pieces.
	_box(house, Vector3(8.0, 0.55, 8.2), Vector3(-3.3, 8.05, 0), roof, Vector3(0, 0, -27))
	_box(house, Vector3(8.0, 0.55, 8.2), Vector3(3.3, 8.05, 0), roof, Vector3(0, 0, 27))

	# Porch.
	_box(house, Vector3(5.0, 0.30, 2.4), Vector3(0, 0.55, 4.25), wood)
	for x in [-2.1, 2.1]:
		_cylinder(house, 0.16, 3.2, Vector3(x, 2.0, 4.45), wood)
	_box(house, Vector3(6.0, 0.28, 0.25), Vector3(0, 3.55, 4.4), wood)

	# Front door and upper balcony door.
	var door_mat := _mat(Color(0.055, 0.032, 0.020), 0.72)
	_box(house, Vector3(1.65, 2.95, 0.18), Vector3(0, 1.95, 3.63), door_mat)
	_box(house, Vector3(1.35, 2.25, 0.18), Vector3(0, 6.15, 3.46), door_mat)
	# Door panels / handle.
	for y in [1.25, 2.15]:
		_box(house, Vector3(1.25, 0.05, 0.04), Vector3(0, y, 3.74), wood)
	var handle := _cylinder(house, 0.055, 0.04, Vector3(0.52, 1.85, 3.76), _mat(Color(0.55, 0.32, 0.12), 0.35, Color(0.2, 0.08, 0.02, 1), 0.7))
	handle.rotation_degrees.x = 90

	# Windows, warm but not cheerful.
	for x in [-4.35, 4.35]:
		_window(house, Vector3(x, 2.65, 3.64))
		_window(house, Vector3(x, 6.0, 3.44), Vector2(1.7, 1.25))

	# Porch lamp.
	porch_light = OmniLight3D.new()
	porch_light.position = Vector3(0, 3.15, 4.1)
	porch_light.light_color = Color(1.0, 0.32, 0.10)
	porch_light.light_energy = 2.4
	porch_light.omni_range = 7.5
	add_child(porch_light)

	# Fence and gate silhouette.
	var fence_mat := _mat(Color(0.045, 0.038, 0.031), 0.9)
	for side in [-1, 1]:
		for i in range(7):
			var x: float = float(side) * (8.0 + float(i) * 1.15)
			_box(self, Vector3(0.14, 2.0, 0.18), Vector3(x, 1.0, 0.5), fence_mat)
		_box(self, Vector3(8.2, 0.16, 0.18), Vector3(side * 11.3, 2.0, 0.5), fence_mat)

	# Trees frame the shot.
	_tree(Vector3(-9.0, 0, -1.0), 1.8)
	_tree(Vector3(9.0, 0, -3.0), 1.65)
	_tree(Vector3(-11.0, 0, -11.0), 2.2)
	_tree(Vector3(10.5, 0, -12.0), 2.0)

	# Car in the foreground.
	var car := Node3D.new()
	car.position = Vector3(5.8, 0.55, 3.2)
	car.rotation_degrees.y = -12
	add_child(car)
	var car_body := _mat(Color(0.012, 0.016, 0.020), 0.24, Color(0.005, 0.006, 0.008, 1), 0.45)
	_box(car, Vector3(4.5, 0.78, 2.05), Vector3(0, 0.42, 0), car_body)
	_box(car, Vector3(2.55, 0.72, 1.65), Vector3(-0.25, 1.02, 0), car_body)
	var glass := _mat(Color(0.018, 0.035, 0.045), 0.10, Color(0.005, 0.012, 0.018, 1), 0.35)
	_box(car, Vector3(2.05, 0.48, 1.48), Vector3(-0.25, 1.12, 0), glass)
	var wheel_mat := _mat(Color(0.008, 0.009, 0.010), 0.5)
	for x in [-1.45, 1.45]:
		_cylinder(car, 0.45, 0.24, Vector3(x, 0.18, -0.92), wheel_mat)
		_cylinder(car, 0.45, 0.24, Vector3(x, 0.18, 0.92), wheel_mat)

	# Rain.
	rain = GPUParticles3D.new()
	rain.amount = 360
	rain.lifetime = 1.1
	rain.position = Vector3(0, 9, -1)
	var rain_mesh := BoxMesh.new()
	rain_mesh.size = Vector3(0.012, 0.50, 0.012)
	rain.draw_pass_1 = rain_mesh
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.12, -1.0, 0.03)
	process.spread = 10.0
	process.initial_velocity_min = 14.0
	process.initial_velocity_max = 20.0
	process.gravity = Vector3(0, -3.0, 0)
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(17, 5, 19)
	rain.process_material = process
	add_child(rain)

	# Camera.
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 58.0
	camera.position = Vector3(0, 1.60, 14.5)
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
	caption.position = Vector2(-520, -128)
	caption.size = Vector2(1040, 72)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_color_override("font_color", Color(0.88, 0.86, 0.81))
	caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
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
	prompt.add_theme_color_override("font_color", Color(0.65, 0.62, 0.57, 0.72))
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

func _move_camera(pos: Vector3, target: Vector3, duration: float) -> void:
	look_target = target
	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(camera, "position", pos, duration)
	await t.finished

func _flicker_lights() -> void:
	for light in window_lights:
		if is_instance_valid(light):
			light.light_energy = randf_range(0.85, 1.25)
	if is_instance_valid(porch_light):
		porch_light.light_energy = randf_range(1.7, 2.5)

func _start_cinematic() -> void:
	await get_tree().process_frame
	await _fade_to(0.0, 1.7)
	if skip_requested:
		_finish()
		return

	await _caption("Hay lugares a los que uno nunca debería volver.", 3.4)
	if skip_requested:
		_finish()
		return

	await _move_camera(Vector3(0, 1.78, 8.0), Vector3(0, 2.3, -8.0), 3.2)
	await _caption("Después de muchos años...", 2.4)
	_flicker_lights()
	if skip_requested:
		_finish()
		return

	await _move_camera(Vector3(0, 2.05, 0.8), Vector3(0, 3.0, -9.0), 3.3)
	await _caption("La casa seguía allí.", 2.5)
	if skip_requested:
		_finish()
		return

	await _move_camera(Vector3(-1.0, 1.72, -4.7), Vector3(0, 3.4, -9.0), 3.7)
	await _caption("Pero no estaba vacía.", 2.8)
	_flicker_lights()
	if skip_requested:
		_finish()
		return

	await _move_camera(Vector3(0.65, 1.08, -3.65), Vector3(0.65, 0.45, -5.05), 2.6)
	await _caption("...", 1.1)
	await _fade_to(1.0, 0.9)
	await _get_diary_beat()
	_finish()

func _get_diary_beat() -> void:
	caption.text = "SI ESTÁS LEYENDO ESTO, YA REGRESASTE."
	caption.modulate.a = 1.0
	await get_tree().create_timer(2.6).timeout

func _finish() -> void:
	if not cinematic_active:
		return
	cinematic_active = false
	var t := create_tween()
	t.tween_property(fade, "color:a", 1.0, 0.35)
	await t.finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")
