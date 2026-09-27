extends Control

signal move_changed(value: Vector2)
signal look_changed(delta: Vector2)
signal flashlight_pressed
signal interact_pressed

var move_touch := -1
var look_touch := -1
var move_origin := Vector2.ZERO
var move_value := Vector2.ZERO
var last_look := Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x > size.x - 190 and event.position.y > size.y - 190:
				flashlight_pressed.emit()
				return
			if event.position.x > size.x - 190 and event.position.y > size.y - 340:
				interact_pressed.emit()
				return
			if event.position.x < size.x * 0.45 and move_touch == -1:
				move_touch = event.index
				move_origin = event.position
				move_value = Vector2.ZERO
				queue_redraw()
			elif event.position.x >= size.x * 0.45 and look_touch == -1:
				look_touch = event.index
				last_look = event.position
		else:
			if event.index == move_touch:
				move_touch = -1
				move_value = Vector2.ZERO
				move_changed.emit(Vector2.ZERO)
				queue_redraw()
			elif event.index == look_touch:
				look_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == move_touch:
			var delta := event.position - move_origin
			move_value = delta.limit_length(70.0) / 70.0
			move_changed.emit(move_value)
			queue_redraw()
		elif event.index == look_touch:
			var delta := event.position - last_look
			last_look = event.position
			look_changed.emit(delta)

func _draw() -> void:
	if move_touch != -1:
		draw_circle(move_origin, 72.0, Color(1, 1, 1, 0.10))
		draw_circle(move_origin + move_value * 58.0, 28.0, Color(1, 1, 1, 0.28))
	draw_circle(Vector2(size.x - 95, size.y - 95), 54.0, Color(1, 1, 1, 0.16))
	draw_circle(Vector2(size.x - 95, size.y - 245), 46.0, Color(1, 1, 1, 0.12))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 125, size.y - 88), "LINTERNA", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1,1,1,0.8))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 125, size.y - 238), "MIRAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1,1,1,0.8))
