extends CanvasLayer

@onready var world: IVISWorld = get_parent()

func _process(_delta: float) -> void:
	if not is_instance_valid(world):
		return
	$TopBar/Performance.text = "FPS %d   FRAME %.1f ms   RENDER %.0f%%" % [
		Engine.get_frames_per_second(),
		1000.0 / max(1.0, Engine.get_frames_per_second()),
		world.auto_quality * 100.0
	]
