extends Control

@onready var main_panel: VBoxContainer = $Center/MainPanel
@onready var settings_panel: PanelContainer = $Center/SettingsPanel
@onready var new_game: Button = $Center/MainPanel/NewGame
@onready var continue_game: Button = $Center/MainPanel/Continue
@onready var settings_button: Button = $Center/MainPanel/Settings
@onready var exit_button: Button = $Center/MainPanel/Exit
@onready var back_button: Button = $Center/SettingsPanel/SettingsBox/Back
@onready var background: TextureRect = $Background

func _ready() -> void:
	main_panel.visible = true
	settings_panel.visible = false
	continue_game.disabled = true
	_apply_cinematic_background()

	new_game.pressed.connect(_new_game)
	settings_button.pressed.connect(_open_settings)
	exit_button.pressed.connect(_exit_game)
	back_button.pressed.connect(_close_settings)

	await get_tree().process_frame
	new_game.grab_focus()

func _apply_cinematic_background() -> void:
	# The cinematic JPEG is preferred when present; SVG remains a safe fallback
	# so the project never opens with a missing-resource error.
	var cinematic_path := "res://ui/main_menu_cinematic.jpg"
	if ResourceLoader.exists(cinematic_path):
		var cinematic_texture := load(cinematic_path) as Texture2D
		if cinematic_texture:
			background.texture = cinematic_texture

func _new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/intro.tscn")

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
