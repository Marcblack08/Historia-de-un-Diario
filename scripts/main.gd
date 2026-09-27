extends Node3D

@onready var message: Label = $UI/Message

func _ready() -> void:
	message.text = "HISTORIA DE UN DIARIO\n\nLa casa está exactamente como la recuerdas... casi.\n\nWASD  Mover   Mouse  Mirar   F  Linterna   E  Investigar"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		message.text = "El aire está frío. Hay una fotografía sobre la mesa."

func _process(_delta: float) -> void:
	var player := $Player
	var target := player.global_position
	if target.x > 5.5 and target.z < -3.0:
		message.text = "La puerta está cerrada. Necesitas encontrar una llave."
