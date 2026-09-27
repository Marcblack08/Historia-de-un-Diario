extends Node3D

@onready var message: Label = $UI/Message

func _ready() -> void:
	message.text = "Historia de un Diario\n\nExplora la casa. Encuentra algo que no debería estar aquí.\n\n[WASD] Mover   [Mouse] Mirar   [F] Linterna"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		message.text = "Algo cruje en algún lugar de la casa..."
