extends Control

@onready var main_panel: VBoxContainer = $Center/MainPanel
@onready var settings_panel: PanelContainer = $Center/SettingsPanel
@onready var new_game: Button = $Center/MainPanel/NewGame
@onready var continue_game: Button = $Center/MainPanel/Continue
@onready var settings_button: Button = $Center/MainPanel/Settings
@onready var exit_button: Button = $Center/MainPanel/Exit
@onready var back_button: Button = $Center/SettingsPanel/SettingsBox/Back
@onready var background: TextureRect = $Background
@onready var center: Control = $Center
@onready var eyebrow: Label = $Center/MainPanel/Eyebrow
@onready var title_top: Label = $Center/MainPanel/TitleTop
@onready var title: Label = $Center/MainPanel/Title
@onready var subtitle: Label = $Center/MainPanel/Subtitle
@onready var rule: ColorRect = $Center/MainPanel/Rule
@onready var buttons: Array[Button] = [$Center/MainPanel/NewGame, $Center/MainPanel/Continue, $Center/MainPanel/Settings, $Center/MainPanel/Exit]

func _ready() -> void:
	main_panel.visible = true
	settings_panel.visible = false
	continue_game.disabled = true
	_apply_cinematic_background()

	_play_intro_animation()
	new_game.pressed.connect(_new_game)
	settings_button.pressed.connect(_open_settings)
	exit_button.pressed.connect(_exit_game)
	back_button.pressed.connect(_close_settings)

	await get_tree().process_frame
	new_game.grab_focus()

func _play_intro_animation() -> void:
	# Cinematic entrance: background breathes in while the title and controls
	# arrive with a short stagger. Designed to remain light on Android.
	background.modulate.a = 0.0
	background.scale = Vector2(1.035, 1.035)
	center.modulate.a = 0.0
	eyebrow.modulate.a = 0.0
	title_top.position.y += 18.0
	title.position.y += 24.0
	subtitle.position.y += 28.0
	rule.modulate.a = 0.0
	for button in buttons:
		button.modulate.a = 0.0
		button.position.x -= 24.0

	var fade := create_tween().set_parallel(true)
	fade.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade.tween_property(background, "modulate:a", 1.0, 0.75)
	fade.tween_property(background, "scale", Vector2.ONE, 3.2)
	fade.tween_property(center, "modulate:a", 1.0, 0.55)
	fade.tween_property(eyebrow, "modulate:a", 1.0, 0.40)

	var title_tween := create_tween()
	title_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	title_tween.tween_property(title_top, "position:y", title_top.position.y - 18.0, 0.45)
	title_tween.tween_property(title, "position:y", title.position.y - 24.0, 0.48)
	title_tween.tween_property(subtitle, "position:y", subtitle.position.y - 28.0, 0.52)
	title_tween.tween_property(rule, "modulate:a", 1.0, 0.25)

	for i in range(buttons.size()):
		var button_tween := create_tween()
		button_tween.tween_interval(0.12 * float(i))
		button_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		button_tween.tween_property(buttons[i], "modulate:a", 1.0, 0.28)
		button_tween.tween_property(buttons[i], "position:x", buttons[i].position.x + 24.0, 0.30)
		buttons[i].mouse_entered.connect(_on_button_enter.bind(buttons[i]))
		buttons[i].mouse_exited.connect(_on_button_exit.bind(buttons[i]))

func _on_button_enter(button: Button) -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(button, "scale", Vector2(1.025, 1.025), 0.12)

func _on_button_exit(button: Button) -> void:
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(button, "scale", Vector2.ONE, 0.12)

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
