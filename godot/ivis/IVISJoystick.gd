class_name IVISJoystick extends Control

@export var radius := 90.0
var active := false
var pointer := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			active = true
			pointer = _clamp_pointer(event.position)
		else:
			active = false
			pointer = Vector2.ZERO
		queue_redraw()
	elif event is InputEventScreenDrag and active:
		pointer = _clamp_pointer(event.position)
		queue_redraw()

func _clamp_pointer(pos: Vector2) -> Vector2:
	var center := size * 0.5
	var delta := pos - center
	if delta.length() > radius:
		delta = delta.normalized() * radius
	return delta

func get_vector() -> Vector2:
	return pointer / radius if active else Vector2.ZERO

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, Color(0.05, 0.07, 0.1, 0.38))
	draw_circle(center + pointer, radius * 0.42, Color(0.8, 0.9, 1.0, 0.60))
