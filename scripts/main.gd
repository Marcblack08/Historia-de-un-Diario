extends Node3D

@onready var message: Label = $UI/Message
@onready var diary_panel: ColorRect = $UI/DiaryPanel

func _ready() -> void:
	add_to_group("game")
	message.text = "HISTORIA DE UN DIARIO\n\nLa casa está exactamente como la recuerdas... casi."
	diary_panel.visible = false

func show_interaction(text: String) -> void:
	message.text = text
	if text.begins_with("DIARIO"):
		diary_panel.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		diary_panel.visible = false
