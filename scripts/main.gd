extends Node3D

@onready var message: Label = $UI/Message

func _ready() -> void:
	message.text = "HISTORIA DE UN DIARIO\n\nExplora la casa. Encuentra algo que no debería estar aquí.\n\nWASD  Mover     Mouse  Mirar     F  Linterna     E  Investigar"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		message.text = "Algo cruje en algún lugar de la casa..."
