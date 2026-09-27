extends Area3D

@export_multiline var inspect_text := "No hay nada especial aquí."
@export var item_name := "Objeto"

func interact() -> String:
	return inspect_text
