extends SpotLight3D

@export var flicker_enabled := true
@export var base_energy := 2.2
var timer := 0.0

func _ready() -> void:
	light_energy = base_energy

func _process(delta: float) -> void:
	if not flicker_enabled:
		return
	timer += delta
	if timer > 0.12:
		timer = 0.0
		if randf() < 0.06:
			light_energy = randf_range(0.25, 1.0)
		else:
			light_energy = base_energy
