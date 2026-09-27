extends Control

@onready var main_panel: VBoxContainer = $Center/MainPanel
@onready var settings_panel: PanelContainer = $Center/SettingsPanel
@onready var subtitle: Label = $Center/MainPanel/Subtitle
@onready var new_game: Button = $Center/MainPanel/NewGame
@onready var continue_game: Button = $Center/MainPanel/Continue
@onready var settings_button: Button = $Center/MainPanel/Settings
@onready var exit_button: Button = $Center/MainPanel/Exit
@onready var back_button: Button = $Center/SettingsPanel/SettingsBox/Back
@onready var ambience: ColorRect = $Ambience

func _ready() -> void:
	main_panel.visible = true
	settings_panel.visible = false
	continue_game.disabled = true
	new_game.grab_focus()

	new_game.pressed.connect(_new_game)
	settings_button.pressed.connect(_open_settings)
	exit_button.pressed.connect(_exit_game)
	back_button.pressed.connect(_close_settings)

	var tween := create_tween().set_loops()
	tween.tween_property(ambience, "modulate:a", 0.72, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ambience, "modulate:a", 0.48, 3.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _open_settings() -> void:
	main_panel.visible = false
	settings_panel.visible = true
	back_button.grab_focus()

func _close_settings() -> void:
	settings_panel.visible = false
	main_panel.visible = true
	settings_button.grab_focus()

func _exit_game() -> void:
	get_tree().quit()
