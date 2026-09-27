extends Node3D

@onready var message: Label = $UI/Message
@onready var diary_panel: ColorRect = $UI/DiaryPanel
@onready var touch: Control = $UI/TouchController
var diary_read := false
var lights_on := false
var upstairs_locked := true
var scare_timer := 0.0

func _ready() -> void:
	add_to_group("game")
	message.text = ""
	diary_panel.visible = false
	touch.move_changed.connect($Player.set_touch_move)
	touch.look_changed.connect($Player.touch_look)
	touch.flashlight_pressed.connect($Player.flashlight)
	touch.interact_pressed.connect($Player.interact)
	_build_visual_environment()
	_build_first_floor_story_space()

func _mat(color: Color, roughness := 0.8, metallic := 0.0, emission := Color(0, 0, 0, 1)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if emission.a > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 0.8
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	n.rotation_degrees = rot
	parent.add_child(n)
	return n

func _cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	parent.add_child(n)
	return n

func _build_visual_environment() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.006, 0.007, 0.008)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.12, 0.105, 0.09)
	environment.ambient_light_energy = 0.38
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.55
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.055, 0.06, 0.065)
	environment.fog_light_energy = 0.28
	environment.fog_density = 0.018
	env.environment = environment
	add_child(env)

	# Warm ceiling light and a colder window light establish cinematic contrast.
	$CeilingLight.light_energy = 0.16
	$CeilingLight.light_color = Color(0.55, 0.46, 0.35)
	var window_light := OmniLight3D.new()
	window_light.position = Vector3(-4.2, 2.0, -4.6)
	window_light.light_color = Color(0.22, 0.30, 0.38)
	window_light.light_energy = 0.7
	window_light.omni_range = 5.0
	window_light.shadow_enabled = true
	add_child(window_light)

	# Old wooden beams.
	var beam := _mat(Color(0.055, 0.034, 0.022), 0.88)
	for x in [-5.2, -1.8, 1.8, 5.2]:
		_box(self, Vector3(0.22, 0.24, 9.4), Vector3(x, 3.05, 0), beam)

	# Wall wainscoting and trim.
	var trim := _mat(Color(0.075, 0.052, 0.036), 0.84)
	_box(self, Vector3(13.4, 0.34, 0.18), Vector3(0, 0.42, -4.82), trim)
	_box(self, Vector3(0.18, 0.34, 9.4), Vector3(-6.82, 0.42, 0), trim)
	_box(self, Vector3(0.18, 0.34, 9.4), Vector3(6.82, 0.42, 0), trim)

	# Rug with worn dark red tone.
	var rug := _mat(Color(0.105, 0.028, 0.024), 0.94)
	_box(self, Vector3(4.8, 0.035, 2.7), Vector3(0, 0.035, 1.1), rug)
	var rug_edge := _mat(Color(0.18, 0.055, 0.035), 0.9)
	_box(self, Vector3(4.95, 0.04, 0.10), Vector3(0, 0.06, -0.25), rug_edge)
	_box(self, Vector3(4.95, 0.04, 0.10), Vector3(0, 0.06, 2.45), rug_edge)

	# Wooden table becomes a believable piece of furniture.
	var table_wood := _mat(Color(0.075, 0.038, 0.021), 0.76)
	_box(self, Vector3(2.9, 0.16, 1.35), Vector3(0, 1.15, -1.2), table_wood)
	for x in [-1.15, 1.15]:
		for z in [-0.42, 0.42]:
			_box(self, Vector3(0.15, 1.1, 0.15), Vector3(x, 0.58, -1.2 + z), table_wood)

	# A chair left abandoned beside the table.
	var chair := Node3D.new()
	chair.position = Vector3(-2.15, 0, -0.9)
	add_child(chair)
	_box(chair, Vector3(1.05, 0.14, 1.0), Vector3(0, 0.72, 0), table_wood)
	_box(chair, Vector3(1.0, 1.1, 0.13), Vector3(0, 1.25, 0.42), table_wood)
	for x in [-0.4, 0.4]:
		_box(chair, Vector3(0.12, 0.72, 0.12), Vector3(x, 0.36, -0.34), table_wood)

	# Sideboard against the wall.
	var cabinet := _mat(Color(0.065, 0.035, 0.022), 0.8)
	_box(self, Vector3(3.7, 1.55, 0.65), Vector3(-3.2, 0.78, -4.35), cabinet)
	_box(self, Vector3(3.9, 0.12, 0.78), Vector3(-3.2, 1.58, -4.35), table_wood)
	for x in [-4.2, -3.2, -2.2]:
		_box(self, Vector3(0.035, 0.95, 0.55), Vector3(x, 0.8, -4.02), trim)

	# Old framed pictures. No faces: only unsettling empty frames.
	var frame := _mat(Color(0.18, 0.10, 0.055), 0.65)
	var picture := _mat(Color(0.10, 0.105, 0.10), 0.96)
	for x in [-5.1, 3.0, 4.8]:
		_box(self, Vector3(1.25, 1.55, 0.08), Vector3(x, 1.9, -4.78), frame)
		_box(self, Vector3(1.02, 1.30, 0.035), Vector3(x, 1.9, -4.72), picture)

	# A narrow window at the rear: cold moonlight.
	var window_frame := _mat(Color(0.045, 0.035, 0.028), 0.9)
	var window_glass := _mat(Color(0.055, 0.09, 0.12), 0.25, 0.1)
	_box(self, Vector3(2.4, 2.0, 0.08), Vector3(0, 1.85, -4.72), window_glass)
	_box(self, Vector3(0.12, 2.2, 0.12), Vector3(0, 1.85, -4.62), window_frame)
	_box(self, Vector3(2.5, 0.12, 0.12), Vector3(0, 1.85, -4.62), window_frame)
	_box(self, Vector3(2.5, 0.12, 0.12), Vector3(0, 0.88, -4.62), window_frame)
	_box(self, Vector3(0.12, 2.0, 0.12), Vector3(-1.16, 1.85, -4.62), window_frame)
	_box(self, Vector3(0.12, 2.0, 0.12), Vector3(1.16, 1.85, -4.62), window_frame)

	# Small props that sell the scale of the room.
	var metal := _mat(Color(0.12, 0.11, 0.095), 0.35, 0.55)
	_cylinder(self, 0.10, 0.35, Vector3(1.05, 1.43, -1.2), metal)
	_cylinder(self, 0.16, 0.18, Vector3(1.45, 1.35, -1.2), _mat(Color(0.16, 0.06, 0.035), 0.7))
	
	# Subtle dust motes, kept cheap for mobile.
	var dust := GPUParticles3D.new()
	dust.amount = 40
	dust.lifetime = 5.0
	dust.position = Vector3(0, 1.8, 0)
	var dust_mesh := SphereMesh.new()
	dust_mesh.radius = 0.012
	dust_mesh.height = 0.024
	dust.draw_pass_1 = dust_mesh
	var dust_process := ParticleProcessMaterial.new()
	dust_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	dust_process.emission_box_extents = Vector3(6, 1.6, 4.0)
	dust_process.direction = Vector3(0.1, 0.05, 0.1)
	dust_process.initial_velocity_min = 0.02
	dust_process.initial_velocity_max = 0.08
	dust_process.gravity = Vector3.ZERO
	dust.process_material = dust_process
	add_child(dust)

	$Player/Camera3D.fov = 68.0

func show_interaction(text: String) -> void:
	message.text = text
	if text.begins_with("DIARIO"):
		diary_panel.visible = true
		diary_read = true
		message.text = "El diario está abierto.\n\nEncuentra el interruptor de la entrada."
		_build_story_after_diary()

func _build_first_floor_story_space() -> void:
	# A staircase is the visual promise of the second floor.
	var stair_mat := _mat(Color(0.075, 0.040, 0.024), 0.84)
	var riser_mat := _mat(Color(0.045, 0.028, 0.019), 0.92)
	for i in range(8):
		var z := -1.8 - float(i) * 0.38
		var y := 0.10 + float(i) * 0.20
		var step := _box(self, Vector3(2.6, 0.20, 0.72), Vector3(4.15, y, z), stair_mat)
		step.name = "Stair_%02d" % i
		_box(self, Vector3(2.62, 0.10, 0.10), Vector3(4.15, y + 0.13, z - 0.30), riser_mat)
	# Upstairs landing hint.
	_box(self, Vector3(3.0, 0.16, 2.0), Vector3(4.15, 1.72, -4.0), stair_mat)
	# A locked door at the top.
	var locked_mat := _mat(Color(0.035, 0.022, 0.015), 0.75)
	_box(self, Vector3(1.55, 2.75, 0.16), Vector3(4.15, 3.10, -4.82), locked_mat)
	var lock_light := OmniLight3D.new()
	lock_light.position = Vector3(4.15, 2.5, -4.45)
	lock_light.light_color = Color(0.35, 0.12, 0.07)
	lock_light.light_energy = 0.35
	lock_light.omni_range = 2.5
	add_child(lock_light)

func _build_story_after_diary() -> void:
	if not diary_read:
		return
	if not lights_on:
		lights_on = true
		$CeilingLight.light_energy = 0.75
		$CeilingLight.light_color = Color(1.0, 0.52, 0.22)
		message.text = "El diario está abierto.\n\nEl interruptor de la entrada acaba de encenderse."
		var pulse := create_tween()
		pulse.tween_property($CeilingLight, "light_energy", 0.08, 0.12)
		pulse.tween_property($CeilingLight, "light_energy", 0.75, 0.18)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		diary_panel.visible = false
